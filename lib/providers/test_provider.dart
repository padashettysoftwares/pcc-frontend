import 'package:flutter/material.dart';
import '../models/test.dart';
import '../services/api_service.dart';

class TestProvider with ChangeNotifier {
  final _api = ApiService();
  List<Test> _tests = [];
  bool _isLoading = false;

  List<Test> get tests => _tests;
  bool get isLoading => _isLoading;

  Future<void> fetchTests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getTests();
      _tests = data.map<Test>((item) => Test.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint("Error fetching tests: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTest(Test test) async {
    await _api.createTest({
      'testName': test.testName,
      'subject': test.subject,
      'totalMarks': test.totalMarks,
      'date': test.date,
      'className': test.className,
    });
    await fetchTests();
  }

  Future<void> saveMarks(int testId, List<Map<String, dynamic>> marks) async {
      final records = marks.map((m) => {
        'studentId': m['student_id'],
        'testId': m['test_id'],
        'marksObtained': m['marks_obtained'],
      }).toList();
      await _api.bulkEnterMarks(records);
      notifyListeners();
  }
  
  Future<List<Map<String, dynamic>>> getMarksForTest(int testId) async {
      final data = await _api.getTestMarks(testId);
      return data.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Safely parse a value to double (handles both String and num from API)
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<double> getStudentAverageScore(String studentId) async {
    try {
      final marks = await _api.getStudentMarks(studentId);
      if (marks.isEmpty) return 0.0;
      
      double totalPercentage = 0.0;
      for (var record in marks) {
        final obtained = _toDouble(record['marks_obtained']);
        final total = _toDouble(record['total_marks']);
        if (total > 0) {
          totalPercentage += (obtained / total) * 100;
        }
      }
      return totalPercentage / marks.length;
    } catch (e) {
      debugPrint("Error calculating average score: $e");
      return 0.0;
    }
  }

  Future<List<double>> getStudentPerformanceTrend(String studentId) async {
    try {
      final marks = await _api.getStudentMarks(studentId);
      final trend = marks.take(6).map((record) {
        final obtained = _toDouble(record['marks_obtained']);
        final total = _toDouble(record['total_marks']);
        return total > 0 ? (obtained / total) * 100 : 0.0;
      }).toList();
      return trend.reversed.toList();
    } catch (e) {
      debugPrint("Error calculating performance trend: $e");
      return [];
    }
  }
}
