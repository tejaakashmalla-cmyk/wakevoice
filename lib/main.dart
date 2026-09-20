import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/ringing_screen.dart';
import 'screens/voice_record_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Alarm.init();

  runApp(const WakeVoiceApp());
}

class WakeVoiceApp extends StatefulWidget {
  const WakeVoiceApp({super.key});

  @override
  State<WakeVoiceApp> createState() =>
      _WakeVoiceAppState();
}

class _WakeVoiceAppState
    extends State<WakeVoiceApp> {
  final GlobalKey<NavigatorState>
  _navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    Alarm.ringing.listen(
          (alarmSet) {
        for (final alarm in alarmSet.alarms) {
          _showRingingScreen(alarm.id);
        }
      },
    );
  }

  void _showRingingScreen(int alarmId) {
    final navigator =
        _navigatorKey.currentState;

    if (navigator == null) return;

    final currentRoute =
    ModalRoute.of(
      navigator.context,
    );

    if (currentRoute?.settings.name ==
        '/ringing') {
      return;
    }

    navigator.push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: '/ringing',
        ),
        builder: (_) =>
            RingingScreen(
              alarmId: alarmId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'WakeVoice',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
        ColorScheme.fromSeed(
          seedColor:
          const Color(0xFF6C4AB6),
        ),
        scaffoldBackgroundColor:
        const Color(0xFFF8F6FB),
      ),
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() =>
      _StartupScreenState();
}

class _StartupScreenState
    extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();

    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    final alarms =
    await Alarm.getAlarms();

    // Important:
    // If Android opened WakeVoice because an
    // alarm is currently ringing, show our
    // custom alarm screen instead of Home.
    for (final alarm in alarms) {
      final ringing =
      await Alarm.isRinging(alarm.id);

      if (ringing) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings:
            const RouteSettings(
              name: '/ringing',
            ),
            builder: (_) =>
                RingingScreen(
                  alarmId: alarm.id,
                  title:
                  alarm.notificationSettings
                      .title,
                  message:
                  alarm.notificationSettings
                      .body,
                ),
          ),
        );

        return;
      }
    }

    final prefs =
    await SharedPreferences
        .getInstance();

    final profileCreated =
        prefs.getBool(
          'voice_profile_created',
        ) ??
            false;

    if (!mounted) return;

    if (profileCreated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C4AB6),
        ),
      ),
    );
  }
}

class WelcomeScreen
    extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE9DDFB,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    36,
                  ),
                ),
                child: const Icon(
                  Icons
                      .record_voice_over_rounded,
                  size: 58,
                  color:
                  Color(0xFF6C4AB6),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'WakeVoice',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight:
                  FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Wake up to the voice\nyou love.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Create a personalized voice profile '
                    'and use it to wake you up every morning.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color:
                  Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width:
                double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const VoiceRecordScreen(),
                      ),
                    );
                  },
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
                  child: const Text(
                    'Create Wake-Up Voice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'English • తెలుగు',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w500,
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}