import os
import time
from io import BytesIO

import httpx
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response

load_dotenv()

ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")

if not ELEVENLABS_API_KEY:
    raise RuntimeError(
        "ELEVENLABS_API_KEY is missing from backend/.env"
    )

elevenlabs = ElevenLabs(
    api_key=ELEVENLABS_API_KEY,
)

ELEVENLABS_BASE_URL = "https://api.elevenlabs.io"

MAX_AUDIO_SIZE = 25 * 1024 * 1024

app = FastAPI(
    title="WakeVoice Backend",
    version="1.2.0",
    description="WakeVoice voice cloning and speech generation backend.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "app": "WakeVoice Backend",
        "status": "running",
        "version": "1.2.0",
    }


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "wakevoice-backend",
    }


@app.post("/api/voice/clone")
async def clone_voice(
    name: str = Form(...),
    consent: str = Form(...),
    file: UploadFile = File(...),
):
    started = time.perf_counter()

    print(
        f"[CLONE] Request received | "
        f"name={name!r} | "
        f"filename={file.filename!r} | "
        f"type={file.content_type!r}"
    )

    if consent.strip().lower() != "true":
        raise HTTPException(
            status_code=400,
            detail=(
                "Voice cloning requires confirmation "
                "that you have permission to use this voice."
            ),
        )

    clean_name = name.strip()

    if not clean_name:
        raise HTTPException(
            status_code=400,
            detail="Voice name cannot be empty.",
        )

    if not file.filename:
        raise HTTPException(
            status_code=400,
            detail="No audio file was provided.",
        )

    audio_bytes = await file.read()

    if not audio_bytes:
        raise HTTPException(
            status_code=400,
            detail="The uploaded audio file is empty.",
        )

    if len(audio_bytes) > MAX_AUDIO_SIZE:
        raise HTTPException(
            status_code=413,
            detail=(
                "Audio file is too large. "
                "Maximum size is 25 MB."
            ),
        )

    print(
        f"[CLONE] Audio received | "
        f"size={len(audio_bytes) / (1024 * 1024):.2f} MB"
    )

    try:
        print(
            "[CLONE] Creating Instant Voice Clone "
            "through ElevenLabs SDK..."
        )

        voice = elevenlabs.voices.ivc.create(
            name=clean_name,
            files=[
                BytesIO(audio_bytes),
            ],
        )

        elapsed = time.perf_counter() - started

        voice_id = voice.voice_id

        if not voice_id:
            raise HTTPException(
                status_code=502,
                detail=(
                    "ElevenLabs returned no voice_id."
                ),
            )

        print(
            f"[CLONE] SUCCESS | "
            f"voice_id={voice_id} | "
            f"time={elapsed:.1f}s"
        )

        return {
            "success": True,
            "voice_id": voice_id,
            "name": clean_name,
            "requires_verification": getattr(
                voice,
                "requires_verification",
                False,
            ),
            "processing_seconds": round(
                elapsed,
                2,
            ),
        }

    except HTTPException:
        raise

    except Exception as exc:
        elapsed = time.perf_counter() - started

        print(
            f"[CLONE] FAILED | "
            f"time={elapsed:.1f}s | "
            f"error={exc}"
        )

        raise HTTPException(
            status_code=502,
            detail={
                "provider": "ElevenLabs",
                "error": str(exc),
            },
        )


@app.post("/api/tts")
async def generate_speech(
    voice_id: str = Form(...),
    text: str = Form(...),
    language_code: str | None = Form(None),
):
    clean_voice_id = voice_id.strip()
    clean_text = text.strip()

    if not clean_voice_id:
        raise HTTPException(
            status_code=400,
            detail="voice_id is required.",
        )

    if not clean_text:
        raise HTTPException(
            status_code=400,
            detail="Text cannot be empty.",
        )

    if len(clean_text) > 5000:
        raise HTTPException(
            status_code=400,
            detail=(
                "Text is too long. "
                "Maximum is 5000 characters."
            ),
        )

    payload = {
        "text": clean_text,
        "model_id": "eleven_v3",
    }

    if language_code and language_code.strip():
        payload["language_code"] = (
            language_code.strip()
        )

    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json",
        "Accept": "audio/mpeg",
    }

    params = {
        "output_format": "mp3_44100_128",
    }

    started = time.perf_counter()

    print(
        f"[TTS] Generating speech | "
        f"voice_id={clean_voice_id}"
    )

    try:
        timeout = httpx.Timeout(
            connect=30.0,
            read=300.0,
            write=60.0,
            pool=30.0,
        )

        async with httpx.AsyncClient(
            timeout=timeout
        ) as client:
            response = await client.post(
                f"{ELEVENLABS_BASE_URL}/v1/text-to-speech/"
                f"{clean_voice_id}",
                headers=headers,
                params=params,
                json=payload,
            )

        elapsed = time.perf_counter() - started

        print(
            f"[TTS] Response | "
            f"status={response.status_code} | "
            f"time={elapsed:.1f}s"
        )

        if response.status_code >= 400:
            try:
                provider_error = response.json()
            except Exception:
                provider_error = response.text

            print(
                f"[TTS] Provider error: "
                f"{provider_error}"
            )

            raise HTTPException(
                status_code=response.status_code,
                detail={
                    "provider": "ElevenLabs",
                    "status_code": response.status_code,
                    "error": provider_error,
                },
            )

        return Response(
            content=response.content,
            media_type="audio/mpeg",
            headers={
                "Content-Disposition":
                    'inline; filename="wakevoice.mp3"'
            },
        )

    except HTTPException:
        raise

    except Exception as exc:
        print(
            f"[TTS] FAILED | error={exc}"
        )

        raise HTTPException(
            status_code=502,
            detail={
                "provider": "ElevenLabs",
                "error": str(exc),
            },
        )
