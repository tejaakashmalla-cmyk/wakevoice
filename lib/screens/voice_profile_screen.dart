import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class VoiceProfileScreen extends StatefulWidget {
  final String audioPath;

  const VoiceProfileScreen({
    super.key,
    required this.audioPath,
  });

  @override
  State<VoiceProfileScreen> createState() =>
      _VoiceProfileScreenState();
}

class _VoiceProfileScreenState
    extends State<VoiceProfileScreen> {
  final TextEditingController _nameController =
  TextEditingController();

  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _hasConsent = false;
  bool _english = true;
  bool _telugu = true;

  bool _creatingVoice = false;
  bool _voiceCreated = false;
  bool _testingVoice = false;

  String? _voiceId;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final prefs =
    await SharedPreferences.getInstance();

    final existingName =
    prefs.getString('voice_profile_name');

    final existingVoiceId =
    prefs.getString('voice_id');

    if (!mounted) return;

    setState(() {
      if (existingName != null &&
          existingName.trim().isNotEmpty) {
        _nameController.text = existingName;
      }

      if (existingVoiceId != null &&
          existingVoiceId.trim().isNotEmpty) {
        _voiceId = existingVoiceId;
        _voiceCreated = true;
      }

      _english =
          prefs.getBool(
            'voice_language_english',
          ) ??
              true;

      _telugu =
          prefs.getBool(
            'voice_language_telugu',
          ) ??
              true;

      _hasConsent =
          prefs.getBool(
            'voice_profile_consent',
          ) ??
              false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _createVoiceClone() async {
    final name =
    _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Please enter a name for this voice.',
      );
      return;
    }

    if (!_english && !_telugu) {
      _showMessage(
        'Select at least one language.',
      );
      return;
    }

    if (!_hasConsent) {
      _showMessage(
        'Please confirm that you have permission to use this voice.',
      );
      return;
    }

    final audioFile =
    File(widget.audioPath);

    if (!audioFile.existsSync()) {
      _showMessage(
        'The voice recording could not be found.',
      );
      return;
    }

    setState(() {
      _creatingVoice = true;
      _statusMessage =
      'Uploading your voice sample...';
      _voiceCreated = false;
      _voiceId = null;
    });

    try {
      final result =
      await _apiService.cloneVoice(
        name: name,
        audioPath: widget.audioPath,
        consent: true,
      );

      final returnedVoiceId =
      result['voice_id']?.toString();

      if (returnedVoiceId == null ||
          returnedVoiceId.trim().isEmpty) {
        throw Exception(
          'The server did not return a voice ID.',
        );
      }

      final prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'voice_profile_name',
        name,
      );

      await prefs.setString(
        'voice_sample_path',
        widget.audioPath,
      );

      await prefs.setString(
        'voice_id',
        returnedVoiceId,
      );

      await prefs.setBool(
        'voice_profile_consent',
        true,
      );

      await prefs.setBool(
        'voice_language_english',
        _english,
      );

      await prefs.setBool(
        'voice_language_telugu',
        _telugu,
      );

      await prefs.setBool(
        'voice_profile_created',
        true,
      );

      if (!mounted) return;

      setState(() {
        _creatingVoice = false;
        _voiceCreated = true;
        _voiceId = returnedVoiceId;
        _statusMessage =
        'Your reusable voice profile is ready.';
      });

      await _showVoiceCreatedDialog();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _creatingVoice = false;
        _statusMessage =
        'Voice creation failed.';
      });

      _showMessage(
        _cleanError(e),
      );
    }
  }

  Future<void> _testClonedVoice() async {
    if (_voiceId == null ||
        _voiceId!.trim().isEmpty) {
      _showMessage(
        'Create the voice profile first.',
      );
      return;
    }

    setState(() {
      _testingVoice = true;
      _statusMessage =
      'Generating a test message...';
    });

    try {
      const testMessage =
          'Good morning! This is your WakeVoice test. '
          'Wake up and start your day.';

      final audio =
      await _apiService.generateSpeech(
        voiceId: _voiceId!,
        text: testMessage,
        languageCode: 'en',
      );

      if (audio.isEmpty) {
        throw Exception(
          'The server returned empty audio.',
        );
      }

      await _audioPlayer.stop();

      await _audioPlayer.play(
        BytesSource(audio),
      );

      if (!mounted) return;

      setState(() {
        _testingVoice = false;
        _statusMessage =
        'Test audio is playing.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _testingVoice = false;
        _statusMessage =
        'Could not generate test audio.';
      });

      _showMessage(
        _cleanError(e),
      );
    }
  }

  Future<void> _showVoiceCreatedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 56,
          ),
          title: const Text(
            'Voice Clone Ready',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Your voice profile has been created successfully.\n\n'
                'The same saved voice can now be reused for multiple alarms.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment:
          MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Test My Voice',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    await _testClonedVoice();
  }

  String _cleanError(Object error) {
    final text =
    error.toString();

    if (text.contains('DioException')) {
      if (text.contains('connection')) {
        return 'Could not connect to the WakeVoice backend. '
            'Make sure the backend is running and your phone is on the same Wi-Fi.';
      }

      if (text.contains('400')) {
        return 'The voice sample or voice information was rejected by the server.';
      }

      if (text.contains('401') ||
          text.contains('403')) {
        return 'ElevenLabs rejected the request. Check your API key permissions.';
      }

      if (text.contains('422')) {
        return 'The voice sample format or request was not accepted by ElevenLabs.';
      }

      if (text.contains('429')) {
        return 'The ElevenLabs account has reached a usage limit. Check the account quota.';
      }

      if (text.contains('500') ||
          text.contains('502') ||
          text.contains('503')) {
        return 'The voice service returned a server error. Check the backend terminal.';
      }
    }

    return text
        .replaceFirst(
      'Exception: ',
      '',
    )
        .replaceFirst(
      'Error: ',
      '',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration:
        const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioExists =
    File(widget.audioPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voice Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 22),

              _buildNameSection(),

              const SizedBox(height: 22),

              _buildLanguageSection(),

              const SizedBox(height: 22),

              _buildPermissionSection(),

              const SizedBox(height: 22),

              _buildRecordingSection(
                audioExists,
              ),

              const SizedBox(height: 22),

              _buildStatusSection(),

              const SizedBox(height: 24),

              _buildCreateButton(),

              if (_voiceCreated) ...[
                const SizedBox(height: 14),
                _buildTestButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Create your reusable voice',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This voice profile will be used for '
              'your personalized wake-up alarms.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection() {
    return _Section(
      title: 'Voice name',
      subtitle:
      'Choose a name that you will recognize later.',
      child: TextField(
        controller: _nameController,
        enabled: !_creatingVoice,
        textInputAction:
        TextInputAction.done,
        decoration: InputDecoration(
          hintText:
          "Example: Mom's Voice",
          prefixIcon: const Icon(
            Icons.record_voice_over_rounded,
          ),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _Section(
      title: 'Languages',
      subtitle:
      'The voice can be used for English and Telugu alarms.',
      child: Column(
        children: [
          _LanguageTile(
            title: 'English',
            subtitle:
            'Natural English wake-up messages',
            value: _english,
            enabled: !_creatingVoice,
            onChanged: (value) {
              setState(() {
                _english = value;
              });
            },
          ),

          const SizedBox(height: 10),

          _LanguageTile(
            title: 'తెలుగు',
            subtitle:
            'సహజమైన తెలుగు మేల్కొలుపు సందేశాలు',
            value: _telugu,
            enabled: !_creatingVoice,
            onChanged: (value) {
              setState(() {
                _telugu = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEFC),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0D2F3),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _hasConsent,
            onChanged: _creatingVoice
                ? null
                : (value) {
              setState(() {
                _hasConsent =
                    value ?? false;
              });
            },
          ),

          const SizedBox(width: 6),

          const Expanded(
            child: Padding(
              padding:
              EdgeInsets.only(top: 10),
              child: Text(
                'I confirm that I own this voice or have '
                    'permission from the person to create and '
                    'use a voice profile from this recording.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection(
      bool audioExists,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              const Color(0xFFF0E9FA),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Icon(
              audioExists
                  ? Icons.audiotrack_rounded
                  : Icons.error_outline_rounded,
              color: audioExists
                  ? const Color(
                0xFF6C4AB6,
              )
                  : Colors.red,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  audioExists
                      ? 'Voice sample ready'
                      : 'Voice sample missing',
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  audioExists
                      ? 'Your recorded audio is ready to upload.'
                      : 'Go back and record your voice again.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            audioExists
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            color: audioExists
                ? Colors.green
                : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_statusMessage == null &&
        !_voiceCreated) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _voiceCreated
            ? Colors.green.withValues(
          alpha: 0.08,
        )
            : const Color(0xFFF7F3FD),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: _voiceCreated
              ? Colors.green.withValues(
            alpha: 0.22,
          )
              : const Color(
            0xFFE2D7F1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _voiceCreated
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: _voiceCreated
                ? Colors.green
                : const Color(
              0xFF6C4AB6,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _statusMessage ??
                  'Voice profile ready.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed:
        _creatingVoice
            ? null
            : _createVoiceClone,
        icon: _creatingVoice
            ? const SizedBox(
          width: 21,
          height: 21,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(
          _voiceCreated
              ? Icons.refresh_rounded
              : Icons.auto_awesome_rounded,
        ),
        label: Text(
          _creatingVoice
              ? 'Creating Voice...'
              : _voiceCreated
              ? 'Recreate Voice Clone'
              : 'Create Voice Clone',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor:
          const Color(0xFF6C4AB6),
          foregroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed:
        _testingVoice
            ? null
            : _testClonedVoice,
        icon: _testingVoice
            ? const SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Icon(
          Icons.play_arrow_rounded,
        ),
        label: Text(
          _testingVoice
              ? 'Generating Test Voice...'
              : 'Test My Cloned Voice',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style:
        OutlinedButton.styleFrom(
          foregroundColor:
          const Color(0xFF6C4AB6),
          side: const BorderSide(
            color: Color(0xFF6C4AB6),
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LanguageTile
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFF4EFFB)
            : Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: value
              ? const Color(0xFF6C4AB6)
              : Colors.grey.shade300,
          width:
          value ? 1.5 : 1,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged:
        enabled ? onChanged : null,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        secondary: const Icon(
          Icons.language_rounded,
        ),
      ),
    );
  }
}