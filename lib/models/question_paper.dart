class QuestionPaper {
  final int? id;
  final String schoolName;
  final String subject;
  final String className;
  final String? chapter;
  final int totalMarks;
  final String? timeDuration;
  final String? examDate;
  final String? examType;
  final String board;
  final String? difficulty;
  final String? instructions;
  final bool isAiGenerated;
  final bool isPublished;
  final bool includeAnswerKey;
  final String? createdAt;
  final List<QuestionPaperQuestion> questions;

  QuestionPaper({
    this.id,
    this.schoolName = 'Padashetty Coaching Class',
    required this.subject,
    required this.className,
    this.chapter,
    required this.totalMarks,
    this.timeDuration,
    this.examDate,
    this.examType,
    this.board = 'CBSE',
    this.difficulty,
    this.instructions,
    this.isAiGenerated = false,
    this.isPublished = false,
    this.includeAnswerKey = false,
    this.createdAt,
    this.questions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'school_name': schoolName,
      'subject': subject,
      'class_name': className,
      'chapter': chapter,
      'total_marks': totalMarks,
      'time_duration': timeDuration,
      'exam_date': examDate,
      'exam_type': examType,
      'board': board,
      'difficulty': difficulty,
      'instructions': instructions,
      'is_ai_generated': isAiGenerated,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory QuestionPaper.fromMap(Map<String, dynamic> map) {
    List<QuestionPaperQuestion> qs = [];
    if (map['questions'] != null) {
      qs = (map['questions'] as List)
          .map((q) => QuestionPaperQuestion.fromMap(q))
          .toList();
    }
    return QuestionPaper(
      id: map['id'],
      schoolName: map['school_name'] ?? 'Padashetty Coaching Class',
      subject: map['subject'] ?? '',
      className: map['class_name'] ?? '',
      chapter: map['chapter'],
      totalMarks: map['total_marks'] ?? 0,
      timeDuration: map['time_duration'],
      examDate: map['exam_date']?.toString().split('T').first,
      examType: map['exam_type'],
      board: map['board'] ?? 'CBSE',
      difficulty: map['difficulty'],
      instructions: map['instructions'],
      isAiGenerated: map['is_ai_generated'] ?? false,
      isPublished: map['is_published'] ?? false,
      includeAnswerKey: map['include_answer_key'] ?? false,
      createdAt: map['created_at']?.toString(),
      questions: qs,
    );
  }
}

class QuestionPaperQuestion {
  final int? id;
  final int? paperId;
  final String? section;
  final int questionNumber;
  final String questionText;
  final String questionType; // MCQ, Short Answer, Long Answer, Fill in the Blank
  final int marks;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String? correctAnswer;

  QuestionPaperQuestion({
    this.id,
    this.paperId,
    this.section,
    required this.questionNumber,
    required this.questionText,
    required this.questionType,
    required this.marks,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'section': section,
      'question_number': questionNumber,
      'question_text': questionText,
      'question_type': questionType,
      'marks': marks,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
    };
  }

  factory QuestionPaperQuestion.fromMap(Map<String, dynamic> map) {
    return QuestionPaperQuestion(
      id: map['id'],
      paperId: map['paper_id'],
      section: map['section'],
      questionNumber: map['question_number'] ?? 0,
      questionText: map['question_text'] ?? '',
      questionType: map['question_type'] ?? 'MCQ',
      marks: map['marks'] ?? 0,
      optionA: map['option_a'],
      optionB: map['option_b'],
      optionC: map['option_c'],
      optionD: map['option_d'],
      correctAnswer: map['correct_answer'],
    );
  }

  QuestionPaperQuestion copyWith({
    int? id,
    int? paperId,
    String? section,
    int? questionNumber,
    String? questionText,
    String? questionType,
    int? marks,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctAnswer,
  }) {
    return QuestionPaperQuestion(
      id: id ?? this.id,
      paperId: paperId ?? this.paperId,
      section: section ?? this.section,
      questionNumber: questionNumber ?? this.questionNumber,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      marks: marks ?? this.marks,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }
}
