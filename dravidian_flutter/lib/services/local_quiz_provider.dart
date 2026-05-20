// LocalQuizProvider — loads local JSON assets for offline quiz MVP.
// Designed to be a drop-in replacement for MockExerciseProvider in lesson flow.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';

class LocalQuizProvider {
  final String language; // 'tamil' | 'telugu'
  final List<ExerciseBundle> _bundles = [];
  int _index = 0;
  int correctCount = 0;

  LocalQuizProvider({required this.language});

  Future<void> load() async {
    final path = 'assets/data/${language.toLowerCase()}.json';
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _bundles.clear();
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i] as Map<String, dynamic>;
      final skill = Skill(
        id: 'skill-${language.toLowerCase()}',
        language: language.toLowerCase(),
        name: language[0].toUpperCase() + language.substring(1),
      );

      final typeRaw = (item['type'] as String?) ?? 'typing';
      final type = typeRaw == 'mcq' ? 'multiple_choice' : 'fill_in_blank';

      final optionsRaw = item['options'];
      List<String>? opts;
      if (optionsRaw is List) {
        opts = optionsRaw.map((e) => e.toString()).toList();
      }

      final exercise = Exercise(
        id: item['id']?.toString() ?? '${language}_$i',
        skillId: skill.id,
        type: type,
        promptText: (item['question'] as String?) ?? '',
        promptScript: (item['character'] as String?) ?? '',
        correctAnswer: (item['answer'] as String?) ?? '',
        options: opts,
        difficulty: (item['difficulty'] as int?) ?? 1,
      );

      final bundle = ExerciseBundle(skill: skill, exercise: exercise, hint: item['hint'] as String?);
      _bundles.add(bundle);
    }
    reset();
  }

  void reset() {
    _index = 0;
    correctCount = 0;
  }

  int get length => _bundles.length;

  int get currentIndex => _index; // 1-based in UI, provider is 0-based index

  ExerciseBundle? nextBundle() {
    if (_bundles.isEmpty) return null;
    if (_index >= _bundles.length) return null;
    final b = _bundles[_index];
    _index += 1;
    return b;
  }

  void rollback() {
    if (_index > 0) _index -= 1;
  }
}
