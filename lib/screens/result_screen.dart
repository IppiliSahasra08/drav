import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../services/auth_service.dart';

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
    _applyResult();
  }

  /// Apply result: persist XP and streak to Supabase when available.
  /// Uses a local `last_streak_date` in SharedPreferences to avoid
  /// incrementing the streak multiple times in a single day.
  Future<void> _applyResult() async {
    int xpTotal = 0;
    int streakDays = 0;

    try {
      if (AuthService().isSupabaseReady) {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          // Fetch current profile values
          final profile = await client
              .from('profiles')
              .select('xp,streak_days')
              .eq('id', user.id)
              .maybeSingle();

          xpTotal = (profile?['xp'] as int?) ?? 0;
          streakDays = (profile?['streak_days'] as int?) ?? 0;

          // Award XP
          final newXp = xpTotal + _xpEarned;

          // Streak logic: increment once per day using local marker
          final prefs = await SharedPreferences.getInstance();
          final last = prefs.getString('last_streak_date') ?? '';
          final today = DateTime.now().toUtc().toIso8601String().split('T').first;
          int newStreak = streakDays;
          if (last != today) {
            newStreak = streakDays + 1;
            await prefs.setString('last_streak_date', today);
          }

          // Persist to Supabase
          await client
              .from('profiles')
              .update({'xp': newXp, 'streak_days': newStreak}).eq('id', user.id);

          // Update local state
          if (mounted) setState(() {
            _xpTotal = newXp;
            _streak = newStreak;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback to local storage on any error
      debugPrint('Failed to persist to Supabase: $e');
    }

    // Offline/demo fallback: store in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final xp = prefs.getInt('xp_total') ?? 0;
      final streak = prefs.getInt('streak_days') ?? 0;
      final today = DateTime.now().toUtc().toIso8601String().split('T').first;
      final last = prefs.getString('last_streak_date') ?? '';
      int newStreak = streak;
      if (last != today) {
        newStreak = streak + 1;
        await prefs.setString('last_streak_date', today);
      }
      final newXp = xp + _xpEarned;
      await prefs.setInt('xp_total', newXp);
      await prefs.setInt('streak_days', newStreak);
      if (mounted) setState(() {
        _xpTotal = newXp;
        _streak = newStreak;
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
