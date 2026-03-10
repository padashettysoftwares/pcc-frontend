import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/student.dart';
import '../services/api_service.dart';

class StudentProvider with ChangeNotifier {
  final _api = ApiService();
  List<Student> _students = [];
  bool _isLoading = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> fetchStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getStudents();
      _students = data.map<Student>((item) => Student.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint("Error fetching students: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStudent(Student student) async {
    await _api.createStudent({
      'studentId': student.studentId,
      'name': student.name,
      'className': student.className,
      'parentName': student.parentName,
      'parentPhone': student.parentPhone,
      'admissionDate': student.admissionDate,
      'photoPath': student.photoPath,
      'parentUsername': student.parentUsername ?? 'parent_${student.studentId}',
      'parentPassword': student.parentPassword ?? student.parentPhone,
    });
    await fetchStudents();
  }

  Future<void> updateStudent(Student student) async {
    await _api.updateStudent(student.studentId, {
      'name': student.name,
      'className': student.className,
      'parentName': student.parentName,
      'parentPhone': student.parentPhone,
      'admissionDate': student.admissionDate,
      'photoPath': student.photoPath,
      'parentUsername': student.parentUsername,
    });
    await fetchStudents();
  }

  Future<void> deleteStudent(String studentId, {bool deleteFees = false}) async {
    await _api.deleteStudent(studentId, deleteFees: deleteFees);
    await fetchStudents();
  }
}
