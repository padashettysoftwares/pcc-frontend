class Attendance {
  final int? id;
  final String studentId;
  final String date;
  final String status; // 'Present' or 'Absent'

  Attendance({
    this.id,
    required this.studentId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'date': date,
      'status': status,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['student_id'],
      date: map['date'],
      status: map['status'],
    );
  }
}
