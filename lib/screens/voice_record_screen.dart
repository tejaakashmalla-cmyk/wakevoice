import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'voice_profile_screen.dart';

class VoiceRecordScreen extends StatefulWidget {
  const VoiceRecordScreen({super.key});

  @override
  State<VoiceRecordScreen> createState() =>
      _VoiceRecordScreenState();
}

class _VoiceRecordScreenState extends State<VoiceRecordScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;

  String? _recordedPath;
  int _seconds = 0;

  static const int minimumSeconds = 60;
  static const int maximumSeconds = 120;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission =
          await _recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required.',
            ),
          ),
        );

        return;
      }

      await _player.stop();

      final directory =
          await getApplicationDocumentsDirectory();

      final filePath =
          '${directory.path}/wakevoice_voice_sample.wav';

      final existingFile = File(filePath);

      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 1411200,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
        path: filePath,
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordedPath = null;
        _seconds = 0;
      });

      _runTimer();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not start recording: $e',
          ),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });

      if (path != null &&
          File(path).existsSync()) {
        if (_seconds < minimumSeconds) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please record at least $minimumSeconds seconds. '
                'Current recording: $_seconds seconds.',
              ),
              duration:
                  const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Voice sample ready: $_seconds seconds.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not stop recording: $e',
          ),
        ),
      );
    }
  }

  Future<void> _togglePlayback() async {
    final path = _recordedPath;

    if (path == null ||
        !File(path).existsSync()) {
      return;
    }

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(
          DeviceFileSource(path),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not play recording: $e',
          ),
        ),
      );
    }
  }

  Future<void> _retakeRecording() async {
    await _player.stop();

    final oldPath = _recordedPath;

    if (oldPath != null) {
      final oldFile = File(oldPath);

      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {}
      }
    }

    if (!mounted) return;

    setState(() {
      _recordedPath = null;
      _seconds = 0;
      _isPlaying = false;
    });
  }

  void _continue() {
    final path = _recordedPath;

    if (path == null ||
        !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please record your voice first.',
          ),
        ),
      );
      return;
    }

    if (_seconds < minimumSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your recording is too short. '
            'Please record at least $minimumSeconds seconds.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceProfileScreen(
          audioPath: path,
        ),
      ),
    );
  }

  void _runTimer() {
    Future.delayed(
      const Duration(seconds: 1),
      () async {
        if (!mounted || !_isRecording) return;

        final nextSecond = _seconds + 1;

        if (nextSecond >= maximumSeconds) {
          await _stopRecording();
          return;
        }

        setState(() {
          _seconds = nextSecond;
        });

        _runTimer();
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording =
        _recordedPath != null &&
        File(_recordedPath!).existsSync();

    final canContinue =
        hasRecording &&
        _seconds >= minimumSeconds;

    final progress =
        (_seconds / maximumSeconds)
            .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Voice Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            30,
          ),
          child: Column(
            children: [
              const Text(
                'Record your voice',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Record at least 60 seconds of clear, natural speech.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0E9FA),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Quiet room\n'
                      '• One speaker only\n'
                      '• Speak naturally\n'
                      '• Keep the phone about 15–20 cm away\n'
                      '• Avoid music and background noise\n'
                      '• Record 60–120 seconds',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Read this naturally',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Good morning! Wake up, it is time to start your day. '
                      'You have things to do, so get up now. '
                      'Today is going to be a great day.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'శుభోదయం! లేవాల్సిన సమయం వచ్చింది. '
                      'ఇప్పుడు లేచి నీ రోజును ప్రారంభించు. '
                      'ఈ రోజు మంచి రోజుగా మార్చుకో.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? const Color(0xFFFFE2E2)
                      : const Color(0xFFE9DDFB),
                ),
                child: Center(
                  child: Container(
                    width:
                        _isRecording
                            ? 120
                            : 105,
                    height:
                        _isRecording
                            ? 120
                            : 105,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : const Color(
                              0xFF6C4AB6,
                            ),
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons
                              .stop_rounded
                          : hasRecording
                              ? Icons
                                  .check_rounded
                              : Icons
                                  .mic_rounded,
                      color:
                          Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _formatTime(_seconds),
                style:
                    const TextStyle(
                  fontSize: 36,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius:
                    BorderRadius.circular(10),
                color:
                    const Color(0xFF6C4AB6),
                backgroundColor:
                    const Color(0xFFE6DFF0),
              ),

              const SizedBox(height: 8),

              Text(
                _seconds < minimumSeconds
                    ? '$_seconds / $minimumSeconds seconds minimum'
                    : 'Great! Your sample is long enough.',
                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: _isRecording
                      ? _stopRecording
                      : _startRecording,
                  icon: Icon(
                    _isRecording
                        ? Icons
                            .stop_rounded
                        : Icons
                            .mic_rounded,
                  ),
                  label: Text(
                    _isRecording
                        ? 'Stop Recording'
                        : hasRecording
                            ? 'Record Again'
                            : 'Start Recording',
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        _isRecording
                            ? Colors.red
                            : const Color(
                                0xFF6C4AB6,
                              ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                ),
              ),

              if (hasRecording) ...[
                const SizedBox(height: 14),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    15,
                  ),
                  decoration:
                      BoxDecoration(
                    color: canContinue
                        ? Colors.green
                            .withValues(
                            alpha: 0.08,
                          )
                        : Colors.orange
                            .withValues(
                            alpha: 0.08,
                          ),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canContinue
                            ? Icons
                                .check_circle_rounded
                            : Icons
                                .info_rounded,
                        color: canContinue
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          canContinue
                              ? 'Voice sample ready for cloning.'
                              : 'Record at least 60 seconds before continuing.',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _togglePlayback,
                    icon: Icon(
                      _isPlaying
                          ? Icons
                              .pause_rounded
                          : Icons
                              .play_arrow_rounded,
                    ),
                    label: Text(
                      _isPlaying
                          ? 'Pause Recording'
                          : 'Play Recording',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            _retakeRecording,
                        icon: const Icon(
                          Icons
                              .refresh_rounded,
                        ),
                        label: const Text(
                          'Retake',
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          minimumSize:
                              const Size.fromHeight(
                            52,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child:
                          FilledButton.icon(
                        onPressed:
                            canContinue
                                ? _continue
                                : null,
                        icon: const Icon(
                          Icons
                              .arrow_forward_rounded,
                        ),
                        label: const Text(
                          'Continue',
                        ),
                        style:
                            FilledButton
                                .styleFrom(
                          minimumSize:
                              const Size.fromHeight(
                            52,
                          ),
                          backgroundColor:
                              const Color(
                            0xFF6C4AB6,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
