import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme.dart';
import '../services/tts_service.dart';
import '../quiz/quiz_controller.dart';

enum LessonPhase { learn, practice, quiz }

class LessonPhrase {
  final String character;
  final String transliteration;
  final String meaning;

  LessonPhrase({required this.character, required this.transliteration, required this.meaning});
}

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
  bool _didLoad = false;
  LessonPhase _phase = LessonPhase.learn;
  final List<LessonPhrase> _phrases = [];
  int _learnIndex = 0;
  int _practiceIndex = 0;
  bool _practiceAnswered = false;
  bool _ttsLoading = false;

  @override
  void initState() {
    super.initState();
    controller = QuizController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadLessonData();
    }
  }

  @override
  void dispose() {
    // Stop any active TTS playback when leaving the screen
    try {
      TtsService.instance.stop();
    } catch (_) {}
    super.dispose();
  }

  Widget _buildListenButton(LessonPhrase phrase) {
    if (_ttsLoading) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return IconButton(
      onPressed: () => _onListenPressed(phrase),
      icon: const Icon(Icons.volume_up),
    );
  }

  Future<void> _onListenPressed(LessonPhrase phrase) async {
    final textParts = [phrase.character, phrase.transliteration, phrase.meaning]
        .where((s) => s.isNotEmpty)
        .join('. ');
    setState(() => _ttsLoading = true);
    try {
      await TtsService.instance.speak(textParts);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _ttsLoading = false);
    }
  }

  /// Load lesson assets and prepare learn/practice phrases.
  Future<void> _loadLessonData() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _language = args?['language'] as String? ?? 'tamil';
      _category = args?['category'] as String?;

      final assetPath = _getAssetPath();
      final raw = await rootBundle.loadString(assetPath);
      final list = jsonDecode(raw) as List<dynamic>;

      // Build a map of character -> transliteration and meaning
      final Map<String, String> translits = {};
      final Map<String, String> meanings = {};

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final char = (map['character'] as String?) ?? '';
        final type = (map['type'] as String?) ?? '';
        final answer = (map['answer'] as String?) ?? '';
        if (char.isEmpty) continue;
        if (type == 'typing') {
          // treat typing answers as transliteration
          translits[char] = answer;
        } else if (type == 'mcq') {
          // treat mcq answer as English meaning
          meanings[char] = answer;
        }
      }

      _phrases.clear();
      final seen = <String>{};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final char = (map['character'] as String?) ?? '';
        if (char.isEmpty || seen.contains(char)) continue;
        seen.add(char);
        final translit = translits[char] ?? '';
        final meaning = meanings[char] ?? '';
        // Only include greetings category if filtering is active
        final category = (map['category'] as String?) ?? '';
        if (_category == null || _category == '' || category.toLowerCase() == _category!.toLowerCase()) {
          _phrases.add(LessonPhrase(character: char, transliteration: translit, meaning: meaning));
        }
      }

      if (_phrases.isEmpty) {
        // If no phrases, fall back to loading quiz questions directly
        await controller.loadFromAsset(assetPath, category: _category);
        setState(() {
          _isLoading = false;
          _phase = LessonPhase.quiz;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _phase = LessonPhase.learn;
      });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = 'Failed to load lesson: $e';
      });
    }
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
    // If we have lesson phrases, run Learn -> Practice -> Quiz flow.
    if (_phrases.isNotEmpty && _phase != LessonPhase.quiz) {
      final phrase = _phrases[_learnIndex.clamp(0, _phrases.length - 1)];

      if (_phase == LessonPhase.learn) {
        return Scaffold(
          appBar: AppBar(title: Text('Learn'), backgroundColor: Colors.white, centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFF4E6), Color(0xFFFCEFE6)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    Text(phrase.character, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(phrase.transliteration, style: const TextStyle(fontSize: 20, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Text(phrase.meaning, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _buildListenButton(phrase),
                      const SizedBox(width: 8),
                      const Text('Listen', style: TextStyle(color: AppTheme.textSecondary)),
                    ])
                  ]),
                ),
                const SizedBox(height: 24),
                const Text('Take a moment to say it out loud — you got this!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _phase = LessonPhase.practice;
                      _practiceIndex = _learnIndex;
                      _practiceAnswered = false;
                    });
                  },
                  style: AppTheme.primaryButton,
                  child: const Text('Practice'),
                )
              ],
            ),
          ),
        );
      }

      // Practice UI
      final practice = _phrases[_practiceIndex.clamp(0, _phrases.length - 1)];
      // build options: correct Telugu char + up to 2 others
      final options = <String>[];
      options.add(practice.character);
      for (final p in _phrases) {
        if (options.length >= 3) break;
        if (p.character != practice.character) options.add(p.character);
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Practice'), backgroundColor: Colors.white, centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 8),
            Text('Tap the Telugu word for "${practice.meaning}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 5,
                mainAxisSpacing: 12,
                children: options.map((opt) {
                  final correct = opt == practice.character;
                  Color bg = Colors.white;
                  if (_practiceAnswered) {
                    if (correct) bg = const Color(0xFFF0FFF4);
                    else if (opt == _userAnswer) bg = const Color(0xFFFFF0F0);
                  }
                  return GestureDetector(
                    onTap: () {
                      if (_practiceAnswered) return;
                      setState(() {
                        _userAnswer = opt;
                        _practiceAnswered = true;
                      });
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (correct) {
                          // advance to next phrase or to quiz
                          if (_practiceIndex + 1 < _phrases.length) {
                            setState(() {
                              _learnIndex = _practiceIndex + 1;
                              _phase = LessonPhase.learn;
                              _userAnswer = '';
                            });
                          } else {
                            // move to quiz phase and load quiz questions
                            setState(() {
                              _phase = LessonPhase.quiz;
                              _isLoading = true;
                            });
                            // load quiz questions
                            Future(() async {
                              try {
                                final assetPath = _getAssetPath();
                                await controller.loadFromAsset(assetPath, category: _category);
                                if (mounted) setState(() {
                                  _isLoading = false;
                                });
                              } catch (e) {
                                if (mounted) setState(() {
                                  _isLoading = false;
                                  _error = 'Failed to load quiz: $e';
                                });
                              }
                            });
                          }
                        } else {
                          // gentle retry: clear answer after a short delay
                          Future.delayed(const Duration(milliseconds: 600), () {
                            if (mounted) setState(() {
                              _practiceAnswered = false;
                              _userAnswer = '';
                            });
                          });
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(child: Text(opt, style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (_practiceAnswered) const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                // Skip practice and go to quiz
                setState(() {
                  _phase = LessonPhase.quiz;
                  _isLoading = true;
                });
                Future(() async {
                  try {
                    final assetPath = _getAssetPath();
                    await controller.loadFromAsset(assetPath, category: _category);
                    if (mounted) setState(() {
                      _isLoading = false;
                    });
                  } catch (e) {
                    if (mounted) setState(() {
                      _isLoading = false;
                      _error = 'Failed to load quiz: $e';
                    });
                  }
                });
              },
              style: AppTheme.primaryButton,
              child: const Text('Skip to Quiz'),
            )
          ]),
        ),
      );
    }

    // --- Quiz phase: existing quiz UI ---
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
