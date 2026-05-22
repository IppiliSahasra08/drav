// ---------------------------------------------------------------------------
// HomeScreen — mirrors (tabs)/index.tsx
// What's the same: two language cards (Tamil, Telugu), tap to go to lesson.
// What's different: Flutter uses ListView instead of FlatList.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/exercise.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SkillMastery> _progress = [];
  int _streakDays = 0;
  int _xpTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    // Try loading canonical progress (xp & streak) from Supabase first.
    try {
      if (AuthService().isSupabaseReady) {
        final client = Supabase.instance.client;
        final profile = await client
            .from('profiles')
            .select('xp,streak_days')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          final xp = (profile['xp'] as int?) ?? 0;
          final days = (profile['streak_days'] as int?) ?? 0;
          if (mounted)
            setState(() {
              _xpTotal = xp;
              _streakDays = days;
            });
          return;
        }
      }
    } catch (_) {}

    // Fallback to local prefs for offline/demo mode
    try {
      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getInt('streak_days') ?? 0;
      final xp = prefs.getInt('xp_total') ?? 0;
      if (mounted)
        setState(() {
          _streakDays = days;
          _xpTotal = xp;
        });
    } catch (_) {}
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // progress calculation removed for Day 1 MVP — keep backend logic unchanged elsewhere.

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Welcome back 👋',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                Text(user?.email?.split('@').first ?? 'Learner',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ]),
              IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.textSecondary),
                  onPressed: _signOut),
            ]),

            const SizedBox(height: 20),

            // Streak + Continue card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFF4E6), Color(0xFFFCEFE6)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 12)
                ],
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Daily Streak',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('$_streakDays days',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 180,
                    child: Text(
                        'Practice a little every day — keep your streak going!',
                        style: const TextStyle(color: AppTheme.textSecondary),
                        softWrap: true),
                  ),
                ]),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/quiz',
                      arguments: {
                        'language': 'telugu',
                        'category': 'greetings'
                      }),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Row(children: const [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Continue Learning')
                  ]),
                )
              ]),
            ),

            const SizedBox(height: 18),

            // Progress summary
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8)
                      ]),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progress',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Beginner • 0/7 lessons',
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Text('XP: $_xpTotal',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8)
                      ]),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Practice',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 8),
                        Text('Daily • 5 min',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ]),
                ),
              )
            ]),

            const SizedBox(height: 18),

            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text('Lessons',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),

            // Learning roadmap
            Expanded(
              child: ListView(padding: EdgeInsets.zero, children: [
                _LessonTile(
                    title: 'Day 1 — Greetings',
                    subtitle: '7 phrases • Beginner',
                    onTap: () => Navigator.pushNamed(context, '/quiz',
                            arguments: {
                              'language': 'telugu',
                              'category': 'greetings'
                            })),
                _LessonTile(
                    title: 'Day 2 — Introductions',
                    subtitle: 'Coming soon',
                    onTap: () {}),
                _LessonTile(
                    title: 'Day 3 — Family',
                    subtitle: 'Coming soon',
                    onTap: () {}),
                _LessonTile(
                    title: 'Day 4 — Food',
                    subtitle: 'Coming soon',
                    onTap: () {}),
                _LessonTile(
                    title: 'Day 5 — Travel',
                    subtitle: 'Coming soon',
                    onTap: () {}),
              ]),
            )
          ]),
        ),
      ),
    );
  }
}

// Legacy language card removed for Day 1 MVP; kept in repo for reference.

class _LessonTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LessonTile(
      {required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)
            ]),
        child: Row(children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.language, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary))
              ])),
          const Icon(Icons.chevron_right)
        ]),
      ),
    );
  }
}
