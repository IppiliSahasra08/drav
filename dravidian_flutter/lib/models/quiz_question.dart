class QuizQuestion {
  final String category;
  final String type; // 'mcq' | 'typing'
  final String question;
  final String character;
  final List<String>? options;
  final String answer;

  QuizQuestion({
    required this.category,
    required this.type,
    required this.question,
    required this.character,
    this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        category: json['category'] as String? ?? 'General',
        type: json['type'] as String,
        question: json['question'] as String? ?? '',
        character: json['character'] as String? ?? '',
        options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        answer: json['answer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'type': type,
        'question': question,
        'character': character,
        'options': options,
        'answer': answer,
      };
}
