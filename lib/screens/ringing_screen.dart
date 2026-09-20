import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class RingingScreen extends StatefulWidget {
  final int alarmId;
  final String? title;
  final String? message;

  const RingingScreen({
    super.key,
    required this.alarmId,
    this.title,
    this.message,
  });

  @override
  State<RingingScreen> createState() =>
      _RingingScreenState();
}

class _RingingScreenState
    extends State<RingingScreen> {
  bool _stopping = false;

  Future<void> _stopAlarm() async {
    if (_stopping) return;

    setState(() {
      _stopping = true;
    });

    try {
      await Alarm.stop(widget.alarmId);
    } catch (e) {
      debugPrint(
        'Could not stop alarm: $e',
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
        const Color(0xFF17131D),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF6C4AB6,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    size: 58,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'WakeVoice',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Time to wake up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  widget.title ??
                      'Your WakeVoice alarm is ringing',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                if (widget.message != null &&
                    widget.message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.08),
                      borderRadius:
                      BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white12,
                      ),
                    ),
                    child: Text(
                      widget.message!,
                      textAlign:
                      TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 66,
                  child: FilledButton.icon(
                    onPressed:
                    _stopping
                        ? null
                        : _stopAlarm,
                    icon: _stopping
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .stop_circle_rounded,
                      size: 28,
                    ),
                    label: Text(
                      _stopping
                          ? 'Stopping...'
                          : 'STOP ALARM',
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFFC62828,
                      ),
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Press STOP ALARM to silence the alarm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                    Colors.white.withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}