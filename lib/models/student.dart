class Student {
  final int? id;
  final String studentId;
  final String name;
  final String className;
  final String parentName;
  final String parentPhone;
  final String admissionDate;
  final String? photoPath;
  final String? parentUsername;
  final String? parentPassword;

  Student({
    this.id,
    required this.studentId,
    required this.name,
    required this.className,
    required this.parentName,
    required this.parentPhone,
    required this.admissionDate,
    this.photoPath,
    this.parentUsername,
    this.parentPassword,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'class_name': className,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'admission_date': admissionDate,
      'photo_path': photoPath,
      'parent_username': parentUsername,
      'parent_password': parentPassword,
    };
  }

  @override
  String toString() {
    return 'Student{id: $id, studentId: $studentId, name: $name, className: $className, parentName: $parentName, parentPhone: $parentPhone, admissionDate: $admissionDate}';
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentId: map['student_id'],
      name: map['name'],
      className: map['class_name'],
      parentName: map['parent_name'],
      parentPhone: map['parent_phone'],
      admissionDate: map['admission_date'],
      photoPath: map['photo_path'],
      parentUsername: map['parent_username'],
      parentPassword: map['parent_password'],
    );
  }
}
