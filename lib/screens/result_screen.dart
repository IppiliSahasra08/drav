import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _total = 0;
  int _correct = 0;
  int _xpEarned = 0;
  int _xpTotal = 0;
  int _streak = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _total = args?['total'] as int? ?? 0;
    _correct = args?['correct'] as int? ?? 0;
    _xpEarned = args?['xpEarned'] as int? ?? 0;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final xp = prefs.getInt('xp_total') ?? 0;
      final streak = prefs.getInt('streak_days') ?? 0;
      if (mounted)
        setState(() {
          _xpTotal = xp;
          _streak = streak;
        });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pct = _total == 0 ? 0 : ((_correct / _total) * 100).round();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Lesson Complete'),
          backgroundColor: Colors.white,
          centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          Text('Well done!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('You earned $_xpEarned XP',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Total XP: $_xpTotal',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Text('Score: $_correct / $_total  •  Accuracy: $pct%',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03), blurRadius: 8)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Streak',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('🔥 $_streak days',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'Keep going — a little practice every day builds fluency!',
                  style: TextStyle(color: AppTheme.textSecondary))
            ]),
          ),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              style: AppTheme.primaryButton,
              child: const Text('Continue Learning')),
        ]),
      ),
    );
  }
}
