import 'package:flutter/foundation.dart';
import '../quiz/quiz_controller.dart';
import '../models/quiz_question.dart';

enum DuoPhase { learn, practice, test, feedback }

class DuoLessonEngine {
  final QuizController controller;
  DuoPhase phase = DuoPhase.learn;
  int sessionXp = 0;

  DuoLessonEngine({required this.controller});

  QuizQuestion? get current => controller.current;
  int get total => controller.total;
  int get currentIndex => controller.currentIndex;

  void start() => phase = DuoPhase.learn;

  void toPractice() => phase = DuoPhase.practice;
  void toLearn() => phase = DuoPhase.learn;
  void toTest() => phase = DuoPhase.test;
  void toFeedback() => phase = DuoPhase.feedback;

  bool evaluateAnswer(String answer) {
    final q = current;
    if (q == null) return false;
    final ok = answer.trim().toLowerCase() == q.answer.trim().toLowerCase();
    if (ok) controller.markCorrect();
    return ok;
  }

  void awardXp(int amount) {
    sessionXp += amount;
  }

  void nextQuestion() {
    controller.next();
    phase = DuoPhase.learn;
  }
}
