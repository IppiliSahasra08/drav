// ---------------------------------------------------------------------------
// HomeScreen — mirrors (tabs)/index.tsx
// What's the same: two language cards (Tamil, Telugu), tap to go to lesson.
// What's different: uses Flutter's ListView instead of FlatList.
// Progress fetching is wired up here (was unused in the RN version).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
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

  static const _languages = [
    {'id': 'tamil',  'name': 'Tamil',  'script': 'தமிழ்', 'color': 0xFFFF6B35},
    {'id': 'telugu', 'name': 'Telugu', 'script': 'తెలుగు', 'color': 0xFF4361EE},
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final data = await ApiService().fetchProgress(user.id);
      if (mounted) setState(() => _progress = data);
    } catch (_) {}
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  double _avgMastery(String language) {
    // For now, just show overall average — will be per-language later
    if (_progress.isEmpty) return 0;
    final total = _progress.fold(0.0, (s, m) => s + m.masteryScore);
    return total / _progress.length;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back 👋',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      Text(
                        user?.email?.split('@').first ?? 'Learner',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Text('Choose a language',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ),

            // Language cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: _languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final lang = _languages[i];
                  final mastery = _avgMastery(lang['id'] as String);
                  return _LanguageCard(
                    language: lang,
                    mastery: mastery,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/lesson',
                      arguments: lang['id'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Map<String, Object> language;
  final double mastery;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.mastery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(language['color'] as int);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language['script'] as String,
                  style: TextStyle(fontSize: 36, color: color, fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(mastery * 100).toInt()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              language['name'] as String,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text('Tap to start learning',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mastery,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
