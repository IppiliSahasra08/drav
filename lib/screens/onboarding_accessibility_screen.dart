import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingAccessibilityScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String displayName;
  final String username;
  final String role;
  final String learningGoal;
  const OnboardingAccessibilityScreen({required this.userId, required this.email, required this.displayName, required this.username, required this.role, required this.learningGoal, super.key});

  @override
  State<OnboardingAccessibilityScreen> createState() => _OnboardingAccessibilityScreenState();
}

class _OnboardingAccessibilityScreenState extends State<OnboardingAccessibilityScreen> {
  bool largerText = false;
  bool audioFirst = false;
  bool reducedAnimations = false;
  bool highContrast = false;
  String preferredLanguage = 'auto';
  bool _loading = false;
  String? _error;

  Future<void> _finish() async {
    setState(() { _loading = true; _error = null; });
    try {
      final accessMap = {
        'audio_first': audioFirst,
        'larger_text': largerText,
        'reduced_motion': reducedAnimations,
        'high_contrast': highContrast,
      };

      // Prepare exact DB column names as requested
      final updatePayload = {
        'learning_language': preferredLanguage == 'auto' ? null : preferredLanguage,
        'learning_goal': widget.learningGoal,
        'learning_style': 'standard',
        'accessibility_preferences': accessMap,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('profiles')
            .update(updatePayload)
            .eq('id', widget.userId)
            .select();

        final rows = res as List<dynamic>;
        if (rows.isEmpty) {
          throw Exception('Profile update returned empty result');
        }
        // Success
      } catch (ex, st) {
        debugPrint('onboarding: profile update error: $ex');
        debugPrint(st.toString());
        if (mounted) setState(() => _error = ex.toString());
        return;
      }

      if (!mounted) return;

      if (widget.role == 'adult') {
        Navigator.pushNamedAndRemoveUntil(context, '/adult-dashboard', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
      Switch(value: value, onChanged: onChanged)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: AppTheme.textPrimary)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Accessibility', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const SizedBox(height: 8),
            const Text('Optional preferences to make learning easier', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  _toggleRow('Larger text', largerText, (v) => setState(() => largerText = v)),
                  _toggleRow('Audio-first learning', audioFirst, (v) => setState(() => audioFirst = v)),
                  _toggleRow('Reduced animations', reducedAnimations, (v) => setState(() => reducedAnimations = v)),
                  _toggleRow('High contrast mode', highContrast, (v) => setState(() => highContrast = v)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Preferred language', style: TextStyle(fontSize: 15, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton(
                  style: preferredLanguage == 'te' ? AppTheme.primaryButton : null,
                  onPressed: () => setState(() => preferredLanguage = 'te'),
                  child: Text('Telugu', style: TextStyle(color: preferredLanguage == 'te' ? Colors.white : AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: preferredLanguage == 'ta' ? AppTheme.primaryButton : null,
                  onPressed: () => setState(() => preferredLanguage = 'ta'),
                  child: Text('Tamil', style: TextStyle(color: preferredLanguage == 'ta' ? Colors.white : AppTheme.textPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: preferredLanguage == 'auto' ? AppTheme.primaryButton : null,
                  onPressed: () => setState(() => preferredLanguage = 'auto'),
                  child: Text('Auto', style: TextStyle(color: preferredLanguage == 'auto' ? Colors.white : AppTheme.textPrimary)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _finish,
              style: AppTheme.primaryButton,
              child: _loading ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : const Text('Finish and Start Learning'),
            ),
          ]),
        ),
      ),
    );
  }
}
