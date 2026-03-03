class Test {
  final int? id;
  final String testName;
  final String subject;
  final int totalMarks;
  final String date;

  final String className; // Added for filtering

  Test({
    this.id,
    required this.testName,
    required this.subject,
    required this.totalMarks,
    required this.date,
    required this.className,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'test_name': testName,
      'subject': subject,
      'total_marks': totalMarks,
      'date': date,
      'class_name': className,
    };
  }

  factory Test.fromMap(Map<String, dynamic> map) {
    return Test(
      id: map['id'],
      testName: map['test_name'],
      subject: map['subject'],
      totalMarks: map['total_marks'],
      date: map['date'],
      className: map['class_name'] ?? '',
    );
  }
}
