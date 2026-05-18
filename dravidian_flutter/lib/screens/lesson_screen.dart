// ---------------------------------------------------------------------------
// LessonScreen — mirrors lesson/[skillId].tsx
// All 3 fixes from the audit are already applied here:
//   ✓ supabase.from() (via AuthService.createSession)
//   ✓ fill_in_blank fully supported with TextField
//   ✓ hint display after wrong answers
// What's different from RN: uses StatefulWidget lifecycle instead of
// useEffect/useState. Navigation args passed via Navigator, not URL params.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String? _language; // 'tamil' or 'telugu' — passed as route arg
  String? _sessionId;
  ExerciseBundle? _bundle;
  bool _loading = true;

  // Feedback state
  bool? _isCorrect;
  String? _hint;
  bool _submitting = false;
  DateTime _startTime = DateTime.now();

  // Fill-in-blank controller
  final _textController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route argument is the language string ('tamil' or 'telugu')
    _language ??= ModalRoute.of(context)?.settings.arguments as String?;
    if (_sessionId == null) _startSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final sessionId = await AuthService().createSession();
    if (!mounted) return;
    setState(() => _sessionId = sessionId);
    _loadNextExercise();
  }

  Future<void> _loadNextExercise() async {
    final user = AuthService().currentUser;
    if (user == null || _language == null) return;
    setState(() {
      _loading = true;
      _isCorrect = null;
      _hint = null;
      _textController.clear();
      _startTime = DateTime.now();
    });
    try {
      final bundle = await ApiService().fetchNextExercise(
        userId: user.id,
        language: _language!,
      );
      if (mounted) setState(() => _bundle = bundle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAnswer(String selected) async {
    if (_bundle == null || _sessionId == null || _submitting) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    final correct = selected.trim().toLowerCase() ==
        _bundle!.exercise.correctAnswer.trim().toLowerCase();
    final elapsed = DateTime.now().difference(_startTime).inMilliseconds;

    try {
      final result = await ApiService().submitAnswer(
        userId: user.id,
        sessionId: _sessionId!,
        exerciseId: _bundle!.exercise.id,
        answer: selected,
        isCorrect: correct,
        responseTimeMs: elapsed,
      );

      if (mounted) {
        setState(() {
          _isCorrect = correct;
          _hint = result['hint'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Exit', style: TextStyle(color: AppTheme.primary)),
        ),
        title: Text(
          _bundle?.skill.name ?? _language ?? '',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _bundle == null
              ? _buildError()
              : _buildExercise(),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load exercise', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadNextExercise,
              style: AppTheme.primaryButton,
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildExercise() {
    final exercise = _bundle!.exercise;
    final answered = _isCorrect != null;
    final isMultiple = exercise.type == 'multiple_choice';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Prompt text
          Text(
            exercise.promptText,
            style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Script — big character display
          Text(
            exercise.promptScript,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // ── Multiple choice ──
          if (isMultiple)
            ...(exercise.options ?? []).map((opt) {
              Color borderColor = const Color(0xFFE5E5E5);
              Color bgColor = Colors.white;
              if (answered) {
                if (opt == exercise.correctAnswer) {
                  borderColor = AppTheme.success;
                  bgColor = const Color(0xFFF0FFF4);
                } else if (_isCorrect == false) {
                  borderColor = const Color(0xFFE5E5E5);
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: answered ? null : () => _handleAnswer(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),

          // ── Fill in blank ──
          if (!isMultiple) ...[
            TextField(
              controller: _textController,
              enabled: !answered,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                filled: true,
                fillColor: answered
                    ? (_isCorrect! ? const Color(0xFFF0FFF4) : const Color(0xFFFFF0F0))
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: answered
                        ? (_isCorrect! ? AppTheme.success : AppTheme.error)
                        : const Color(0xFFE5E5E5),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
              onSubmitted: answered ? null : (v) { if (v.trim().isNotEmpty) _handleAnswer(v); },
            ),
            if (!answered) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting || _textController.text.trim().isEmpty
                    ? null
                    : () => _handleAnswer(_textController.text),
                style: AppTheme.primaryButton,
                child: _submitting
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],

          // ── Feedback + hint ──
          if (answered) ...[
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect! ? const Color(0xFFF0FFF4) : const Color(0xFFFFF0F0),
                border: Border.all(
                  color: _isCorrect! ? AppTheme.success : AppTheme.error,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _isCorrect!
                        ? '✓ Correct!'
                        : '✗ The answer is: ${_bundle!.exercise.correctAnswer}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isCorrect! ? AppTheme.success : AppTheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_hint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 $_hint',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadNextExercise,
              style: AppTheme.primaryButton,
              child: const Text('Next →', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
