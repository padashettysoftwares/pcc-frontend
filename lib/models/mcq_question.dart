class McqQuestion {
  final int questionNumber;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer; // "A", "B", "C", or "D"
  String? selectedAnswer;

  McqQuestion({
    required this.questionNumber,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.selectedAnswer,
  });

  bool get isCorrect => selectedAnswer == correctAnswer;
  bool get isAnswered => selectedAnswer != null;

  factory McqQuestion.fromMap(Map<String, dynamic> map) {
    return McqQuestion(
      questionNumber: map['question_number'] ?? 0,
      questionText: map['question_text'] ?? '',
      optionA: map['option_a'] ?? '',
      optionB: map['option_b'] ?? '',
      optionC: map['option_c'] ?? '',
      optionD: map['option_d'] ?? '',
      correctAnswer: map['correct_answer'] ?? 'A',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question_number': questionNumber,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
      'selected_answer': selectedAnswer,
    };
  }
}

class McqScore {
  final int? id;
  final String? studentId;
  final String className;
  final String subject;
  final String chapter;
  final int score;
  final int total;
  final String? createdAt;

  McqScore({
    this.id,
    this.studentId,
    required this.className,
    required this.subject,
    required this.chapter,
    required this.score,
    this.total = 10,
    this.createdAt,
  });

  double get percentage => total > 0 ? (score / total) * 100 : 0;

  factory McqScore.fromMap(Map<String, dynamic> map) {
    return McqScore(
      id: map['id'],
      studentId: map['student_id'],
      className: map['class_name'] ?? '',
      subject: map['subject'] ?? '',
      chapter: map['chapter'] ?? '',
      score: map['score'] ?? 0,
      total: map['total'] ?? 10,
      createdAt: map['created_at']?.toString(),
    );
  }
}
