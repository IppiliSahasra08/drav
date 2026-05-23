// ---------------------------------------------------------------------------
// MockExerciseProvider — local, in-memory exercises for demo and testing.
// Replaces backend calls for the lesson flow so the app can run offline
// and without Supabase. Easy to replace with real API later.
// ---------------------------------------------------------------------------

import '../models/exercise.dart';

class MockExerciseProvider {
  final List<ExerciseBundle> _bundles = [
    ExerciseBundle(
      skill: Skill(id: 's1', language: 'tamil', name: 'Letters'),
      exercise: Exercise(
        id: 'e1',
        skillId: 's1',
        type: 'multiple_choice',
        promptText: 'Which of these is the Tamil letter "அ"?',
        promptScript: 'அ',
        transliteration: '',
        correctAnswer: 'அ',
        options: ['அ', 'ஆ', 'இ', 'உ'],
        difficulty: 1,
      ),
      hint: 'Look for the rounded shape with a small tail.',
    ),
    ExerciseBundle(
      skill: Skill(id: 's1', language: 'tamil', name: 'Letters'),
      exercise: Exercise(
        id: 'e2',
        skillId: 's1',
        type: 'fill_in_blank',
        promptText: 'Type the transliteration for the letter shown',
        promptScript: 'க',
        transliteration: 'ka',
        correctAnswer: 'ka',
        options: null,
        difficulty: 1,
      ),
      hint: 'The consonant is pronounced like "ka".',
    ),
    ExerciseBundle(
      skill: Skill(id: 's2', language: 'telugu', name: 'Basic'),
      exercise: Exercise(
        id: 'e3',
        skillId: 's2',
        type: 'multiple_choice',
        promptText: 'Select the character matching the script',
        promptScript: 'అ',
        transliteration: 'a',
        correctAnswer: 'అ',
        options: ['అ', 'ఆ', 'ఈ', 'ఊ'],
        difficulty: 1,
      ),
      hint: 'First vowel in Telugu.',
    ),
  ];

  int _index = 0;
  int correctCount = 0;

  void reset() {
    _index = 0;
    correctCount = 0;
  }

  int get length => _bundles.length;

  int get currentIndex => _index;

  /// Returns next ExerciseBundle or null if none left.
  ExerciseBundle? nextBundle() {
    if (_bundles.isEmpty) return null;
    if (_index >= _bundles.length) return null;
    final b = _bundles[_index];
    _index += 1;
    return b;
  }

  /// Move index back one so the current question can be retried.
  void rollback() {
    if (_index > 0) _index -= 1;
  }
}
