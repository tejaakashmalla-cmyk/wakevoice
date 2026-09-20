import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/voice_alarm_service.dart';

class CreateAlarmScreen extends StatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  State<CreateAlarmScreen> createState() =>
      _CreateAlarmScreenState();
}

class _CreateAlarmScreenState
    extends State<CreateAlarmScreen> {
  final VoiceAlarmService _voiceAlarmService =
      VoiceAlarmService();

  final TextEditingController _messageController =
      TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(
    hour: 6,
    minute: 30,
  );

  final Set<int> _selectedDays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  String _language = 'English';
  String _personality = 'Caring';

  bool _generateFreshMessage = true;
  bool _saving = false;
  bool _testingAlarm = false;

  final List<_PersonalityOption> _personalities = [
    const _PersonalityOption(
      name: 'Caring',
      icon: Icons.favorite_rounded,
      description: 'Warm and gentle',
    ),
    const _PersonalityOption(
      name: 'Playful',
      icon: Icons.sentiment_very_satisfied_rounded,
      description: 'Fun and cheerful',
    ),
    const _PersonalityOption(
      name: 'Sarcastic',
      icon: Icons.sentiment_neutral_rounded,
      description: 'Teasing and funny',
    ),
    const _PersonalityOption(
      name: 'Strict',
      icon: Icons.front_hand_rounded,
      description: 'Firm and direct',
    ),
    const _PersonalityOption(
      name: 'Motivational',
      icon: Icons.local_fire_department_rounded,
      description: 'Energetic and encouraging',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Choose wake-up time',
    );

    if (result == null) return;

    setState(() {
      _selectedTime = result;
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();

    final date = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    return DateFormat('hh:mm a').format(date);
  }

  String _timeForSpeech() {
    final now = DateTime.now();

    final date = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return DateFormat('h:mm a').format(date);
  }

  String _generateMessage() {
    final time = _timeForSpeech();

    final isTelugu =
        _language == 'Telugu';

    final isBoth =
        _language == 'English + Telugu';

    if (_personality == 'Sarcastic') {
      if (isTelugu) {
        return 'ఆకాశ్... $time అయిపోయింది. '
            'ఇంకా పడుకున్నావా? '
            'లేవుతానన్నావు కదా... '
            'ఆ మాట గుర్తుందా? లేచి రా!';
      }

      if (isBoth) {
        return 'Akash... it is $time. '
            'Still sleeping? You said you would wake up early. '
            'Nice plan. Get up ra!\n\n'
            'ఆకాశ్... $time అయిపోయింది. '
            'ఇంకా పడుకున్నావా? లేచి రా!';
      }

      return 'Akash... it is $time. '
          'Still sleeping? You said you would wake up early. '
          'Nice plan. Get up!';
    }

    if (_personality == 'Strict') {
      if (isTelugu) {
        return 'ఆకాశ్, $time అయింది. '
            'ఇప్పుడు లేవాలి. ఆలస్యం చేయకుండా '
            'వెంటనే లేచి రెడీ అవ్వండి.';
      }

      if (isBoth) {
        return 'Akash, it is $time. '
            'Time to get up. No more sleeping. '
            'Get ready now.\n\n'
            'ఆకాశ్, $time అయింది. ఇప్పుడు లేవాలి.';
      }

      return 'Akash, it is $time. '
          'Time to get up. No more sleeping. '
          'Get ready now.';
    }

    if (_personality == 'Playful') {
      if (isTelugu) {
        return 'ఆకాశ్... గుడ్ మార్నింగ్! '
            '$time అయింది. ఇంకా నిద్రలోనే ఉన్నావా? '
            'లేచి రా బాస్!';
      }

      if (isBoth) {
        return 'Good morning Akash! '
            'It is $time. Come on sleepyhead, wake up!\n\n'
            'గుడ్ మార్నింగ్ ఆకాశ్! '
            '$time అయింది. లేచి రా!';
      }

      return 'Good morning Akash! '
          'It is $time. Come on sleepyhead, wake up!';
    }

    if (_personality == 'Motivational') {
      if (isTelugu) {
        return 'ఆకాశ్, $time అయింది. '
            'లేచి నీ రోజును మొదలు పెట్టు. '
            'ఈ రోజు మంచి రోజుగా మార్చుకో!';
      }

      if (isBoth) {
        return 'Good morning Akash! '
            'It is $time. Get up and make today count!\n\n'
            'ఆకాశ్, $time అయింది. '
            'లేచి నీ రోజును మొదలు పెట్టు!';
      }

      return 'Good morning Akash! '
          'It is $time. Get up and make today count!';
    }

    if (isTelugu) {
      return 'శుభోదయం ఆకాశ్. '
          '$time అయింది. లేచి నీ రోజును ప్రారంభించు.';
    }

    if (isBoth) {
      return 'Good morning Akash. '
          'It is $time. Wake up and start your day.\n\n'
          'శుభోదయం ఆకాశ్. '
          '$time అయింది. లేచి నీ రోజును ప్రారంభించు.';
    }

    return 'Good morning Akash. '
        'It is $time. Wake up and start your day.';
  }

  int _createAlarmId(DateTime dateTime) {
    return 200000 +
        (dateTime.year % 100) * 100000 +
        dateTime.month * 1000 +
        dateTime.day * 10 +
        dateTime.weekday;
  }

  List<DateTime> _getUpcomingAlarmDates() {
    final now = DateTime.now();

    final List<DateTime> dates = [];

    for (int i = 0; i < 8; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(
        Duration(days: i),
      );

      if (!_selectedDays.contains(
        day.weekday,
      )) {
        continue;
      }

      final dateTime = DateTime(
        day.year,
        day.month,
        day.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (dateTime.isAfter(now)) {
        dates.add(dateTime);
      }
    }

    return dates;
  }

  Future<void> _testVoiceAlarm() async {
    if (_testingAlarm) return;

    setState(() {
      _testingAlarm = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final voiceId =
          prefs.getString('voice_id');

      if (voiceId == null ||
          voiceId.trim().isEmpty) {
        throw Exception(
          'No cloned voice found. Go to Voice Settings and create your voice clone first.',
        );
      }

      final testMessage =
          _language == 'Telugu'
              ? 'ఆకాశ్... ఇది WakeVoice టెస్ట్ అలారం. '
                'నా స్వంత వాయిస్‌తో నిన్ను లేపడానికి ఇదే టెస్ట్. లేచి రా!'
              : _language == 'English + Telugu'
                  ? 'Akash... this is your WakeVoice test alarm. '
                    'Yes, your own saved voice is doing the talking!\n\n'
                    'ఆకాశ్... ఇది నీ WakeVoice టెస్ట్ అలారం. లేచి రా!'
                  : 'Akash... this is your WakeVoice test alarm. '
                    'Yes, your saved voice is doing the talking. Wake up!';

      final audioPath =
          await _voiceAlarmService.generateVoiceAudio(
        text: testMessage,
        language: _language,
      );

      await _voiceAlarmService
          .cancelWakeVoiceAlarms();

      final testTime = DateTime.now().add(
        const Duration(minutes: 1),
      );

      final success =
          await _voiceAlarmService
              .scheduleVoiceAlarm(
        id: 900001,
        dateTime: testTime,
        audioPath: audioPath,
        title: 'WakeVoice Test Alarm',
        body: 'Your cloned voice is waking you up.',
      );

      if (!success) {
        throw Exception(
          'Android could not schedule the voice test alarm.',
        );
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.record_voice_over_rounded,
              color: Color(0xFF6C4AB6),
              size: 50,
            ),
            title: const Text(
              'Voice Alarm Scheduled',
            ),
            content: Text(
              'The generated voice alarm will ring at:\n\n'
              '${DateFormat('hh:mm a').format(testTime)}\n\n'
              'Lock your phone and wait about one minute.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Got it'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
          duration:
              const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _testingAlarm = false;
        });
      }
    }
  }

  Future<void> _saveAlarm() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one repeat day.',
          ),
        ),
      );
      return;
    }

    final customMessage =
        _messageController.text.trim();

    if (!_generateFreshMessage &&
        customMessage.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a wake-up message.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final voiceId =
          prefs.getString('voice_id');

      if (voiceId == null ||
          voiceId.trim().isEmpty) {
        throw Exception(
          'No cloned voice found. Create your voice clone before creating a voice alarm.',
        );
      }

      final finalMessage =
          _generateFreshMessage
              ? _generateMessage()
              : customMessage;

      if (!mounted) return;

      setState(() {
        _saving = true;
      });

      final audioPath =
          await _voiceAlarmService.generateVoiceAudio(
        text: finalMessage,
        language: _language,
      );

      await _voiceAlarmService
          .cancelWakeVoiceAlarms();

      final dates =
          _getUpcomingAlarmDates();

      if (dates.isEmpty) {
        throw Exception(
          'No upcoming selected alarm time was found.',
        );
      }

      int scheduledCount = 0;

      for (final dateTime in dates) {
        final success =
            await _voiceAlarmService
                .scheduleVoiceAlarm(
          id: _createAlarmId(dateTime),
          dateTime: dateTime,
          audioPath: audioPath,
          title: 'WakeVoice',
          body: finalMessage,
        );

        if (success) {
          scheduledCount++;
        }
      }

      if (scheduledCount == 0) {
        throw Exception(
          'Android could not schedule the voice alarm.',
        );
      }

      await prefs.setInt(
        'alarm_hour',
        _selectedTime.hour,
      );

      await prefs.setInt(
        'alarm_minute',
        _selectedTime.minute,
      );

      await prefs.setString(
        'alarm_language',
        _language,
      );

      await prefs.setString(
        'alarm_personality',
        _personality,
      );

      await prefs.setString(
        'alarm_message',
        finalMessage,
      );

      await prefs.setStringList(
        'alarm_days',
        _selectedDays
            .map(
              (day) => day.toString(),
            )
            .toList(),
      );

      await prefs.setBool(
        'alarm_created',
        true,
      );

      await prefs.setString(
        'alarm_next_date',
        dates.first.toIso8601String(),
      );

      await prefs.setInt(
        'alarm_id',
        _createAlarmId(dates.first),
      );

      await prefs.setString(
        'alarm_audio_path',
        audioPath,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 55,
            ),
            title: const Text(
              'Voice Alarm Ready',
            ),
            content: Text(
              '${DateFormat('EEE, dd MMM • hh:mm a').format(dates.first)}\n\n'
              'Voice: Your cloned voice\n'
              'Language: $_language\n'
              'Style: $_personality\n\n'
              'Generated voice audio has been saved on the phone '
              'and connected to the Android alarm.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
          duration:
              const Duration(seconds: 6),
        ),
      );
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.contains(
      'No cloned voice found',
    )) {
      return message.replaceFirst(
        'Exception: ',
        '',
      );
    }

    if (message.contains(
      'SocketException',
    )) {
      return 'Cannot reach the WakeVoice backend. '
          'Make sure the backend is running and the phone is on the same Wi-Fi.';
    }

    if (message.contains('401') ||
        message.contains('403')) {
      return 'ElevenLabs rejected the request. '
          'Check your API key permissions.';
    }

    if (message.contains('422')) {
      return 'The voice sample was not accepted. '
          'Record a longer, clean voice sample and try again.';
    }

    if (message.contains('429')) {
      return 'ElevenLabs usage limit reached. '
          'Check your account quota.';
    }

    return message.replaceFirst(
      'Exception: ',
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Alarm',
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
            16,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildTimeSection(),

              const SizedBox(height: 24),

              _buildDaysSection(),

              const SizedBox(height: 24),

              _buildLanguageSection(),

              const SizedBox(height: 24),

              _buildPersonalitySection(),

              const SizedBox(height: 24),

              _buildMessageSection(),

              const SizedBox(height: 20),

              _buildVoiceAlarmTestSection(),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  onPressed:
                      _saving ? null : _saveAlarm,
                  icon: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .record_voice_over_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'Generating Voice & Scheduling...'
                        : 'Save Voice Alarm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF6C4AB6,
                    ),
                    foregroundColor:
                        Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF7A55C7),
            Color(0xFF6140A8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          26,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Wake me up at',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatTime(_selectedTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
            ),
            label: const Text(
              'Change Time',
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            style:
                OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSection() {
    const days = [
      _DayInfo(
        DateTime.monday,
        'M',
        'Mon',
      ),
      _DayInfo(
        DateTime.tuesday,
        'T',
        'Tue',
      ),
      _DayInfo(
        DateTime.wednesday,
        'W',
        'Wed',
      ),
      _DayInfo(
        DateTime.thursday,
        'T',
        'Thu',
      ),
      _DayInfo(
        DateTime.friday,
        'F',
        'Fri',
      ),
      _DayInfo(
        DateTime.saturday,
        'S',
        'Sat',
      ),
      _DayInfo(
        DateTime.sunday,
        'S',
        'Sun',
      ),
    ];

    return _Section(
      title: 'Repeat',
      subtitle:
          'Choose the days this alarm should run.',
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          final selected =
              _selectedDays.contains(
            day.value,
          );

          return GestureDetector(
            onTap: () =>
                _toggleDay(day.value),
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),
              width: 40,
              height: 64,
              decoration:
                  BoxDecoration(
                color: selected
                    ? const Color(
                        0xFF6C4AB6,
                      )
                    : Colors
                        .grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border:
                    Border.all(
                  color: selected
                      ? const Color(
                          0xFF6C4AB6,
                        )
                      : Colors
                          .grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    day.shortLetter,
                    style: TextStyle(
                      fontWeight:
                          FontWeight
                              .w800,
                      color: selected
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    day.name.substring(
                      0,
                      1,
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _Section(
      title: 'Language',
      subtitle:
          'Choose how your wake-up message should sound.',
      child: Column(
        children: [
          _ChoiceTile(
            icon: '🇬🇧',
            title: 'English',
            subtitle:
                'Natural English',
            selected:
                _language ==
                    'English',
            onTap: () {
              setState(() {
                _language =
                    'English';
              });
            },
          ),

          const SizedBox(height: 10),

          _ChoiceTile(
            icon: '🇮🇳',
            title: 'తెలుగు',
            subtitle:
                'సహజమైన తెలుగు',
            selected:
                _language ==
                    'Telugu',
            onTap: () {
              setState(() {
                _language =
                    'Telugu';
              });
            },
          ),

          const SizedBox(height: 10),

          _ChoiceTile(
            icon: '🔀',
            title:
                'English + Telugu',
            subtitle:
                'Both languages in one alarm',
            selected:
                _language ==
                    'English + Telugu',
            onTap: () {
              setState(() {
                _language =
                    'English + Telugu';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection() {
    return _Section(
      title:
          'Wake-up personality',
      subtitle:
          'Choose how your saved voice should talk to you.',
      child: Column(
        children:
            _personalities.map(
          (option) {
            final selected =
                _personality ==
                    option.name;

            return Padding(
              padding:
                  const EdgeInsets
                      .only(
                bottom: 10,
              ),
              child:
                  _PersonalityTile(
                option:
                    option,
                selected:
                    selected,
                onTap: () {
                  setState(() {
                    _personality =
                        option
                            .name;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildMessageSection() {
    return _Section(
      title: 'Wake-up message',
      subtitle:
          'Generate a personalized message or write your own.',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding:
                EdgeInsets.zero,
            title: const Text(
              'Generate a fresh message',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            subtitle:
                const Text(
              'AI-generated messages will come later.',
            ),
            value:
                _generateFreshMessage,
            onChanged: (value) {
              setState(() {
                _generateFreshMessage =
                    value;
              });
            },
          ),

          const SizedBox(height: 10),

          TextField(
            controller:
                _messageController,
            enabled:
                !_generateFreshMessage,
            minLines: 4,
            maxLines: 7,
            decoration:
                InputDecoration(
              hintText:
                  'Example:\n'
                  'Good morning Akash, wake up! '
                  'You have college today.',
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              filled: true,
              fillColor:
                  _generateFreshMessage
                      ? Colors
                          .grey.shade100
                      : Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
              16,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF2ECFB,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Icon(
                  Icons
                      .auto_awesome_rounded,
                  color:
                      Color(0xFF6C4AB6),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    _generateMessage(),
                    style:
                        const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceAlarmTestSection() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE3D9F0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .record_voice_over_rounded,
                color:
                    Color(0xFF6C4AB6),
              ),
              SizedBox(width: 10),
              Text(
                'Test your AI voice alarm',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'This generates an MP3 using your saved '
            'voice and schedules it for one minute from now.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 54,
            child:
                OutlinedButton.icon(
              onPressed:
                  _testingAlarm
                      ? null
                      : _testVoiceAlarm,
              icon: _testingAlarm
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                      ),
                    )
                  : const Icon(
                      Icons
                          .timer_rounded,
                    ),
              label: Text(
                _testingAlarm
                    ? 'Generating Voice...'
                    : 'Test Voice Alarm in 1 Minute',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              style:
                  OutlinedButton
                      .styleFrom(
                foregroundColor:
                    const Color(
                  0xFF6C4AB6,
                ),
                side:
                    const BorderSide(
                  color:
                      Color(0xFF6C4AB6),
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
    );
  }
}

class _Section
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color:
                  Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChoiceTile
    extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(15),
        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xFFF3EDFB,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border:
              Border.all(
            color: selected
                ? const Color(
                    0xFF6C4AB6,
                  )
                : Colors.grey.shade300,
            width:
                selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style:
                  const TextStyle(
                fontSize: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .radio_button_unchecked_rounded,
              color: selected
                  ? const Color(
                      0xFF6C4AB6,
                    )
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalityTile
    extends StatelessWidget {
  final _PersonalityOption option;
  final bool selected;
  final VoidCallback onTap;

  const _PersonalityTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(
        17,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color: selected
              ? const Color(
                  0xFFF3EDFB,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          border:
              Border.all(
            color: selected
                ? const Color(
                    0xFF6C4AB6,
                  )
                : Colors.grey.shade300,
            width:
                selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration:
                  BoxDecoration(
                color: selected
                    ? const Color(
                        0xFFE7D9FA,
                      )
                    : Colors.grey
                        .shade100,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                option.icon,
                color: selected
                    ? const Color(
                        0xFF6C4AB6,
                      )
                    : Colors.grey
                        .shade700,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    option.name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    option.description,
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .radio_button_unchecked_rounded,
              color: selected
                  ? const Color(
                      0xFF6C4AB6,
                    )
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalityOption {
  final String name;
  final IconData icon;
  final String description;

  const _PersonalityOption({
    required this.name,
    required this.icon,
    required this.description,
  });
}

class _DayInfo {
  final int value;
  final String shortLetter;
  final String name;

  const _DayInfo(
    this.value,
    this.shortLetter,
    this.name,
  );
}
