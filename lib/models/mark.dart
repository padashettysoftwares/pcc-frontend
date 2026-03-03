class Mark {
  final int? id;
  final String studentId;
  final int testId;
  final double marksObtained;

  Mark({
    this.id,
    required this.studentId,
    required this.testId,
    required this.marksObtained,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'test_id': testId,
      'marks_obtained': marksObtained,
    };
  }

  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      id: map['id'],
      studentId: map['student_id'],
      testId: map['test_id'],
      marksObtained: map['marks_obtained'],
    );
  }
}
