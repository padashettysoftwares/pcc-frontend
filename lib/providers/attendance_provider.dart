import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';

class AttendanceProvider with ChangeNotifier {
  final _api = ApiService();
  List<Map<String, dynamic>> _attendanceList = [];
  bool _isLoading = false;
  int _todayPresentCount = 0;
  Map<String, int> _weeklyStats = {};

  List<Map<String, dynamic>> get attendanceList => _attendanceList;
  bool get isLoading => _isLoading;
  int get todayPresentCount => _todayPresentCount;
  Map<String, int> get weeklyStats => _weeklyStats;

  Future<void> fetchAttendance(String date, String className) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getAttendanceByDate(date);
      _attendanceList = data.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAttendance(Attendance attendance) async {
    await _api.markAttendance({
      'studentId': attendance.studentId,
      'date': attendance.date,
      'status': attendance.status,
    });
    notifyListeners();
  }
  
  Future<void> saveBatchAttendance(List<Attendance> attendances) async {
      _isLoading = true;
      notifyListeners();
      try {
          final records = attendances.map((att) => {
            'studentId': att.studentId,
            'date': att.date,
            'status': att.status,
          }).toList();
          await _api.bulkMarkAttendance(records);
          
          if (attendances.isNotEmpty) {
            final refreshed = await _api.getAttendanceByDate(attendances.first.date);
            _attendanceList = refreshed.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
          }
      } catch(e) {
          debugPrint("Error saving batch attendance: $e");
      } finally {
          _isLoading = false;
          notifyListeners();
      }
  }

  Future<void> fetchDashboardStats() async {
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0];
      
      try {
        final rawData = await _api.getAttendanceByDate(dateStr);
        final data = rawData.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
        _todayPresentCount = data.where((r) => r['status'] == 'Present').length;
        
        // Fetch weekly trends
        final weeklyData = await _api.getWeeklyAttendanceTrends();
        _weeklyStats = Map<String, int>.from(weeklyData.map((key, value) => MapEntry(key.toString(), value as int)));
      } catch (e) {
        debugPrint("Error fetching dashboard stats: $e");
      }
      notifyListeners();
  }

  Future<double> getStudentAttendancePercentage(String studentId) async {
    try {
      final stats = await _api.getAttendanceStats(studentId);
      return double.parse(stats['percentage'].toString());
    } catch (e) {
      debugPrint("Error calculating attendance percentage: $e");
      return 0.0;
    }
  }
}
