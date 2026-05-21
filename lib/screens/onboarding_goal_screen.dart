import 'package:flutter/material.dart';
import '../theme.dart';

import 'onboarding_accessibility_screen.dart';

class OnboardingGoalScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String displayName;
  final String username;
  final String role;
  const OnboardingGoalScreen({required this.userId, required this.email, required this.displayName, required this.username, required this.role, super.key});

  @override
  State<OnboardingGoalScreen> createState() => _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends State<OnboardingGoalScreen> {
  String? _selectedGoal;
  bool _loading = false;

  final List<Map<String,String>> _goals = [
    {'key': 'daily_conversation', 'label': 'Daily conversation'},
    {'key': 'travel', 'label': 'Travel communication'},
    {'key': 'school', 'label': 'School learning'},
    {'key': 'speaking_confidence', 'label': 'Speaking confidence'},
    {'key': 'accessibility', 'label': 'Accessibility learning'},
  ];

  void _continue() {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a goal')));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OnboardingAccessibilityScreen(
        userId: widget.userId,
        email: widget.email,
        displayName: widget.displayName,
        username: widget.username,
        role: widget.role,
        learningGoal: _selectedGoal!,
      )),
    );
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
            const Text('Welcome!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text('What is your goal?', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final g = _goals[i];
                  final selected = _selectedGoal == g['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGoal = g['key']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(colors: [AppTheme.primary.withOpacity(0.9), AppTheme.primary.withOpacity(0.6)])
                            : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,4))],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(g['label']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppTheme.textPrimary)),
                        if (selected)
                          const Icon(Icons.check_circle, color: Colors.white)
                        else
                          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _continue,
              style: AppTheme.primaryButton,
              child: _loading ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : const Text('Continue', style: TextStyle(fontSize:16)),
            ),
          ]),
        ),
      ),
    );
  }
}
