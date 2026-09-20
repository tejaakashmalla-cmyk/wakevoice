import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class VoiceAlarmService {
  final ApiService _apiService = ApiService();

  Future<String> generateVoiceAudio({
    required String text,
    required String language,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final voiceId = prefs.getString('voice_id');

    if (voiceId == null || voiceId.trim().isEmpty) {
      throw Exception(
        'No cloned voice found. Create your voice profile first.',
      );
    }

    String? languageCode;

    if (language == 'English') {
      languageCode = 'en';
    } else if (language == 'Telugu') {
      languageCode = 'te';
    }

    final audioBytes = await _apiService.generateSpeech(
      voiceId: voiceId,
      text: text,
      languageCode: languageCode,
    );

    if (audioBytes.isEmpty) {
      throw Exception(
        'The voice service returned empty audio.',
      );
    }

    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final audioDirectory = Directory(
      '${documentsDirectory.path}/wakevoice_audio',
    );

    if (!await audioDirectory.exists()) {
      await audioDirectory.create(
        recursive: true,
      );
    }

    final fileName =
        'wakevoice_${DateTime.now().millisecondsSinceEpoch}.mp3';

    final audioFile = File(
      '${audioDirectory.path}/$fileName',
    );

    await audioFile.writeAsBytes(
      audioBytes,
      flush: true,
    );

    return audioFile.path;
  }

  Future<bool> scheduleVoiceAlarm({
    required int id,
    required DateTime dateTime,
    required String audioPath,
    required String title,
    required String body,
  }) async {
    final audioFile = File(audioPath);

    if (!await audioFile.exists()) {
      throw Exception(
        'Generated voice audio file does not exist.',
      );
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioPath,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: false,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      volumeSettings:
          const VolumeSettings.fixed(
        volume: 1.0,
        volumeEnforced: false,
      ),
      notificationSettings:
          NotificationSettings(
        title: title,
        body: body,
        stopButton: 'STOP ALARM',
      ),
    );

    return Alarm.set(
      alarmSettings: alarmSettings,
    );
  }

  Future<void> cancelWakeVoiceAlarms() async {
    final alarms = await Alarm.getAlarms();

    for (final alarm in alarms) {
      if ((alarm.id >= 200000 &&
              alarm.id <= 399999) ||
          (alarm.id >= 900000 &&
              alarm.id <= 999999)) {
        try {
          await Alarm.stop(alarm.id);
        } catch (_) {}
      }
    }
  }
}
