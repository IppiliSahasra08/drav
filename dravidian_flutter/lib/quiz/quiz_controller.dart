import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quiz_question.dart';

class QuizController {
  final List<QuizQuestion> _questions = [];
  int _index = 0;
  int correct = 0;

  List<QuizQuestion> get questions => List.unmodifiable(_questions);
  int get currentIndex => _index;
  int get total => _questions.length;

  QuizQuestion? get current => _index < _questions.length ? _questions[_index] : null;

  void resetProgress() {
    _index = 0;
    correct = 0;
  }

  void markCorrect() => correct += 1;

  void next() {
    if (_index < _questions.length) _index += 1;
  }

  /// Load questions from an asset file and optionally filter by category.
  Future<void> loadFromAsset(String assetPath, {String? category}) async {
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    _questions.clear();
    for (final item in list) {
      final q = QuizQuestion.fromJson(item as Map<String, dynamic>);
      if (category == null || q.category == category) {
        _questions.add(q);
      }
    }
    resetProgress();
  }
}
