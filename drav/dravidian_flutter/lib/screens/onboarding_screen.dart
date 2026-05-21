import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  String? _selectedLanguage;
  String? _selectedGoal;
  String? _selectedStyle;
  bool _largerText = false;
  bool _audioFirst = false;
  bool _reducedAnimations = false;
  bool _highContrast = false;
  bool _saving = false;
  String? _error;

  static const int _totalSteps = 4;

  bool get _canProceed {
    if (_currentStep == 0) return _selectedLanguage != null;
    if (_currentStep == 1) return _selectedGoal != null;
    if (_currentStep == 2) return _selectedStyle != null;
    return true;
  }

  String get _buttonLabel {
    return _currentStep == _totalSteps - 1 ? 'Get started' : 'Next';
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleNext() async {
    if (!_canProceed || _saving) return;
    if (_currentStep == _totalSteps - 1) {
      await _savePreferences();
      return;
    }
    _goToStep(_currentStep + 1);
  }

  Future<void> _savePreferences() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Authentication required to complete onboarding.');
      }

      final preferences = {
        'id': user.id,
        'learning_language': _selectedLanguage,
        'learning_goal': _selectedGoal,
        'learning_style': _selectedStyle,
        'accessibility_preferences': {
          'larger_text': _largerText,
          'audio_first': _audioFirst,
          'reduced_animations': _reducedAnimations,
          'high_contrast': _highContrast,
        },
        'onboarding_completed': true,
      };

      final response = await client.from('profiles').upsert(preferences).select().maybeSingle();
      if (response == null) {
        throw Exception('Unable to save your preferences.');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildOptionCard({
    required String label,
    required String value,
    required String? selectedValue,
    required VoidCallback onTap,
  }) {
    final selected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFE5E5E5),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  )),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppTheme.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
    );
  }

  Widget _buildStep({
    required String title,
    String? subtitle,
    required Widget content,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                onPressed: () => _goToStep(_currentStep - 1),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Step ${_currentStep + 1}/$_totalSteps',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep(
                      title: 'Tell us about you',
                      subtitle: 'We\'ll personalize your lessons for faster progress',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('What do you want to learn?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          const SizedBox(height: 16),
                          _buildOptionCard(
                            label: 'Telugu',
                            value: 'telugu',
                            selectedValue: _selectedLanguage,
                            onTap: () => setState(() => _selectedLanguage = 'telugu'),
                          ),
                          _buildOptionCard(
                            label: 'Tamil',
                            value: 'tamil',
                            selectedValue: _selectedLanguage,
                            onTap: () => setState(() => _selectedLanguage = 'tamil'),
                          ),
                        ],
                      ),
                    ),
                    _buildStep(
                      title: 'Tell us about you',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('What is your goal?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          const SizedBox(height: 16),
                          _buildOptionCard(
                            label: 'Daily conversation',
                            value: 'daily_conversation',
                            selectedValue: _selectedGoal,
                            onTap: () => setState(() => _selectedGoal = 'daily_conversation'),
                          ),
                          _buildOptionCard(
                            label: 'Travel communication',
                            value: 'travel_communication',
                            selectedValue: _selectedGoal,
                            onTap: () => setState(() => _selectedGoal = 'travel_communication'),
                          ),
                          _buildOptionCard(
                            label: 'School learning',
                            value: 'school_learning',
                            selectedValue: _selectedGoal,
                            onTap: () => setState(() => _selectedGoal = 'school_learning'),
                          ),
                          _buildOptionCard(
                            label: 'Speaking confidence',
                            value: 'speaking_confidence',
                            selectedValue: _selectedGoal,
                            onTap: () => setState(() => _selectedGoal = 'speaking_confidence'),
                          ),
                          _buildOptionCard(
                            label: 'Learn basics',
                            value: 'learn_basics',
                            selectedValue: _selectedGoal,
                            onTap: () => setState(() => _selectedGoal = 'learn_basics'),
                          ),
                        ],
                      ),
                    ),
                    _buildStep(
                      title: 'Choose your learning style',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOptionCard(
                            label: 'Beginner learner',
                            value: 'beginner_learner',
                            selectedValue: _selectedStyle,
                            onTap: () => setState(() => _selectedStyle = 'beginner_learner'),
                          ),
                          _buildOptionCard(
                            label: 'Child learner',
                            value: 'child_learner',
                            selectedValue: _selectedStyle,
                            onTap: () => setState(() => _selectedStyle = 'child_learner'),
                          ),
                          _buildOptionCard(
                            label: 'Traveler',
                            value: 'traveler',
                            selectedValue: _selectedStyle,
                            onTap: () => setState(() => _selectedStyle = 'traveler'),
                          ),
                          _buildOptionCard(
                            label: 'Accessibility learner',
                            value: 'accessibility_learner',
                            selectedValue: _selectedStyle,
                            onTap: () => setState(() => _selectedStyle = 'accessibility_learner'),
                          ),
                        ],
                      ),
                    ),
                    _buildStep(
                      title: 'Accessibility preferences (optional)',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSwitchTile(
                            title: 'Larger text',
                            value: _largerText,
                            onChanged: (value) => setState(() => _largerText = value),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchTile(
                            title: 'Audio-first learning',
                            value: _audioFirst,
                            onChanged: (value) => setState(() => _audioFirst = value),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchTile(
                            title: 'Reduced animations',
                            value: _reducedAnimations,
                            onChanged: (value) => setState(() => _reducedAnimations = value),
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchTile(
                            title: 'High contrast mode',
                            value: _highContrast,
                            onChanged: (value) => setState(() => _highContrast = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppTheme.error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _saving ? null : () => _goToStep(_currentStep - 1),
                      child: const Text('Back', style: TextStyle(fontSize: 16)),
                    ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canProceed && !_saving ? _handleNext : null,
                      style: AppTheme.primaryButton,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_buttonLabel, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
