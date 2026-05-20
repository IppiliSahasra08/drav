import 'package:flutter/material.dart';
import '../theme.dart';
import '../quiz/quiz_controller.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late QuizController controller;
  bool _isLoading = true;
  String? _error;
  String _language = 'tamil';
  String? _category;
  String _userAnswer = '';
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    controller = QuizController();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _language = args?['language'] as String? ?? 'tamil';
      _category = args?['category'] as String?;

      final assetPath = _getAssetPath();
      await controller.loadFromAsset(assetPath, category: _category);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load quiz: $e';
        });
      }
    }
  }

  String _getAssetPath() {
    if (_language == 'telugu') {
      return 'assets/data/telugu.json';
    }
    return 'assets/data/tamil.json';
  }

  void _handleAnswer(String answer) {
    if (_answered) return;

    setState(() {
      _userAnswer = answer;
      _answered = true;
    });

    final question = controller.current;
    if (question != null && question.answer.toLowerCase() == answer.toLowerCase()) {
      controller.markCorrect();
    }

    Future.delayed(const Duration(milliseconds: 1500), _nextQuestion);
  }

  void _nextQuestion() {
    if (controller.currentIndex < controller.total - 1) {
      controller.next();
      if (mounted) {
        setState(() {
          _userAnswer = '';
          _answered = false;
        });
      }
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final total = controller.total;
    final correct = controller.correct;
    final xpEarned = correct * 10;

    Navigator.pushReplacementNamed(
      context,
      '/result',
      arguments: {
        'total': total,
        'correct': correct,
        'xpEarned': xpEarned,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...'), backgroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller.total == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Questions'), backgroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No questions available for this category.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = controller.current;
    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz'), backgroundColor: Colors.white),
        body: const Center(child: Text('No more questions')),
      );
    }

    final progress = ((controller.currentIndex + 1) / controller.total * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${controller.currentIndex + 1}/${controller.total}'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (controller.currentIndex + 1) / controller.total,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              progress + '%',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            // Question text
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            // Character display (if available)
            if (question.character.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  question.character,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 24),
            // MCQ or Typing
            if (question.type == 'mcq' && question.options != null)
              Expanded(
                child: ListView.separated(
                  itemCount: question.options!.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final option = question.options![i];
                    final isSelected = _userAnswer == option;
                    final isCorrect = option == question.answer;
                    
                    Color bgColor = Colors.white;
                    Color borderColor = Colors.grey[300]!;
                    
                    if (_answered && isSelected && isCorrect) {
                      bgColor = Colors.green[50]!;
                      borderColor = Colors.green;
                    } else if (_answered && isSelected && !isCorrect) {
                      bgColor = Colors.red[50]!;
                      borderColor = Colors.red;
                    } else if (_answered && isCorrect) {
                      bgColor = Colors.green[50]!;
                      borderColor = Colors.green;
                    }
                    
                    return GestureDetector(
                      onTap: () => _handleAnswer(option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected && _answered
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      readOnly: _answered,
                      onChanged: (val) => setState(() => _userAnswer = val),
                      onSubmitted: _answered ? null : _handleAnswer,
                      decoration: InputDecoration(
                        hintText: 'Type your answer',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_answered)
                      ElevatedButton(
                        onPressed: _userAnswer.isEmpty ? null : () => _handleAnswer(_userAnswer),
                        child: const Text('Submit'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
