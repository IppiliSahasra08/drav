import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdultDashboardScreen extends StatefulWidget {
  const AdultDashboardScreen({super.key});

  @override
  State<AdultDashboardScreen> createState() => _AdultDashboardScreenState();
}

class _AdultDashboardScreenState extends State<AdultDashboardScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final client = Supabase.instance.client;

      // Fetch all child profiles
      final profiles = await client
          .from('profiles')
          .select('id, display_name, email')
          .eq('role', 'child');

      // Fetch skill_mastery for each child
      final List<Map<String, dynamic>> enriched = [];
      for (final child in profiles as List) {
        final mastery = await client
            .from('skill_mastery')
            .select('skill_id, mastery_score')
            .eq('user_id', child['id']);

        final scores = mastery as List;
        final avg = scores.isEmpty
            ? 0.0
            : scores.fold(0.0, (sum, m) => sum + (m['mastery_score'] as num)) / scores.length;

        enriched.add({
          ...child,
          'mastery': scores,
          'avg_score': avg,
        });
      }

      if (mounted) setState(() { _children = enriched; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Parent Dashboard', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                Text(user?.email?.split('@').first ?? 'Parent',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              ]),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
                onPressed: () async {
                  await AuthService().signOut();
                  if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                }),
            ]),
            const SizedBox(height: 24),
            const Text("Children's Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_children.isEmpty)
              const Text('No child accounts found.', style: TextStyle(color: AppTheme.textSecondary))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _children.length,
                  itemBuilder: (_, i) {
                    final child = _children[i];
                    final avg = (child['avg_score'] as double) * 100;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(child['display_name'] ?? child['email'],
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Average mastery: ${avg.toStringAsFixed(0)}%',
                            style: const TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: child['avg_score'] as double,
                            backgroundColor: Colors.grey.shade200,
                            color: AppTheme.primary,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
          ]),
        ),
      ),
    );
  }
}