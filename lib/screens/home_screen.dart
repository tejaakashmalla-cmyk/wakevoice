import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_alarm_screen.dart';
import 'voice_record_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _voiceName = 'My Voice';
  bool _profileCreated = false;

  bool _alarmCreated = false;
  String _alarmTime = 'No alarm created';
  String _alarmLanguage = 'English';
  String _alarmPersonality = 'Caring';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final profileCreated =
        prefs.getBool('voice_profile_created') ?? false;

    final voiceName =
        prefs.getString('voice_profile_name') ?? 'My Voice';

    final alarmCreated =
        prefs.getBool('alarm_created') ?? false;

    final alarmHour =
    prefs.getInt('alarm_hour');

    final alarmMinute =
    prefs.getInt('alarm_minute');

    final language =
        prefs.getString('alarm_language') ?? 'English';

    final personality =
        prefs.getString('alarm_personality') ?? 'Caring';

    setState(() {
      _profileCreated = profileCreated;
      _voiceName = voiceName;

      _alarmCreated = alarmCreated;
      _alarmLanguage = language;
      _alarmPersonality = personality;

      if (alarmCreated &&
          alarmHour != null &&
          alarmMinute != null) {
        _alarmTime = _formatTime(
          alarmHour,
          alarmMinute,
        );
      } else {
        _alarmTime = 'No alarm created';
      }
    });
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour =
    hour % 12 == 0 ? 12 : hour % 12;

    final displayMinute =
    minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }

  Future<void> _openVoiceSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VoiceRecordScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _createAlarm() async {
    if (!_profileCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Create your voice profile first.',
          ),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateAlarmScreen(),
      ),
    );

    await _loadData();
  }

  Future<void> _showAlarmDetails() async {
    if (!_alarmCreated) {
      await _createAlarm();
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            30,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Next Alarm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 18),

              _DetailRow(
                icon: Icons.access_time_rounded,
                title: 'Time',
                value: _alarmTime,
              ),

              const SizedBox(height: 12),

              _DetailRow(
                icon: Icons.record_voice_over_rounded,
                title: 'Voice',
                value: _voiceName,
              ),

              const SizedBox(height: 12),

              _DetailRow(
                icon: Icons.language_rounded,
                title: 'Language',
                value: _alarmLanguage,
              ),

              const SizedBox(height: 12),

              _DetailRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Style',
                value: _alarmPersonality,
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createAlarm();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF6C4AB6),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Edit Alarm',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'WakeVoice',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildGreeting(),

                const SizedBox(height: 24),

                _buildVoiceCard(),

                const SizedBox(height: 22),

                _buildNextAlarmCard(),

                const SizedBox(height: 22),

                _buildActionCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning 👋',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Who is waking you up?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7A55C7),
            Color(0xFF6140A8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                  Colors.white.withValues(
                    alpha: 0.16,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const Spacer(),

              if (_profileCreated)
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                    Colors.white.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _profileCreated
                ? _voiceName
                : 'No voice profile yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _profileCreated
                ? 'Your saved wake-up voice is ready to use.'
                : 'Create a voice profile to start making personalized alarms.',
            style: TextStyle(
              color:
              Colors.white.withValues(alpha: 0.84),
              fontSize: 14,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openVoiceSetup,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                const Color(0xFF6846B1),
                minimumSize:
                const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _profileCreated
                    ? 'Manage Voice'
                    : 'Create Voice Profile',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAlarmCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _showAlarmDetails,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FA),
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  size: 30,
                  color: Color(0xFF6C4AB6),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alarmCreated
                          ? 'Next alarm'
                          : 'Next alarm',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _alarmTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (_alarmCreated) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$_alarmLanguage • $_alarmPersonality',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        _ActionCard(
          icon: Icons.add_alarm_rounded,
          title: 'Create an alarm',
          subtitle:
          'Choose time, language and personality',
          onTap: _createAlarm,
        ),

        const SizedBox(height: 12),

        _ActionCard(
          icon: Icons.tune_rounded,
          title: 'Voice settings',
          subtitle:
          'Manage your saved voice profile',
          onTap: _openVoiceSetup,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E9FA),
            borderRadius:
            BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6C4AB6),
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FA),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6C4AB6),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}