// ---------------------------------------------------------------------------
// Models — equivalent to the TypeScript types in the React Native version.
// Dart is strongly typed so we define these once and get compile-time safety
// everywhere, no 'any' types needed.
// ---------------------------------------------------------------------------

class Skill {
  final String id;
  final String language;
  final String name;
  final String? prerequisiteSkillId;

  Skill({
    required this.id,
    required this.language,
    required this.name,
    this.prerequisiteSkillId,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        language: json['language'] as String,
        name: json['name'] as String,
        prerequisiteSkillId: json['prerequisite_skill_id'] as String?,
      );
}

class Exercise {
  final String id;
  final String skillId;
  final String type; // 'multiple_choice' | 'fill_in_blank'
  final String promptText;
  final String promptScript;
  final String transliteration;
  final String correctAnswer;
  final List<String>? options;
  final int difficulty;

  Exercise({
    required this.id,
    required this.skillId,
    required this.type,
    required this.promptText,
    required this.promptScript,
    required this.transliteration,
    required this.correctAnswer,
    this.options,
    required this.difficulty,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // options arrives as a JSON array string from Supabase JSONB column
    List<String>? opts;
    if (json['options'] != null) {
      final raw = json['options'];
      if (raw is List) {
        opts = raw.map((e) => e.toString()).toList();
      }
    }

    final translit = (json['transliteration'] as String?) ?? (json['prompt_transliteration'] as String?) ?? '';

    return Exercise(
      id: json['id'] as String,
      skillId: json['skill_id'] as String,
      type: json['type'] as String,
      promptText: json['prompt_text'] as String,
      promptScript: json['prompt_script'] as String,
      transliteration: translit,
      correctAnswer: json['correct_answer'] as String,
      options: opts,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }
}

class ExerciseBundle {
  final Skill skill;
  final Exercise exercise;
  final String? hint; // returned by backend when answer is wrong

  ExerciseBundle({
    required this.skill,
    required this.exercise,
    this.hint,
  });

  factory ExerciseBundle.fromJson(Map<String, dynamic> json) => ExerciseBundle(
        skill: Skill.fromJson(json['skill'] as Map<String, dynamic>),
        exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
        hint: json['hint'] as String?,
      );
}

class SkillMastery {
  final String skillId;
  final double masteryScore;

  SkillMastery({required this.skillId, required this.masteryScore});

  factory SkillMastery.fromJson(Map<String, dynamic> json) => SkillMastery(
        skillId: json['skill_id'] as String,
        masteryScore: (json['mastery_score'] as num).toDouble(),
      );
}
