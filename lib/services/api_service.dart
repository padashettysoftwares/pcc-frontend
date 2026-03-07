import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';

class ApiService {
  // TODO: Replace with your actual API URL when deployed
  // Use your machine's LAN IP for physical device, or 10.0.2.2 for Android emulator
  // static const String baseUrl = 'http://192.168.1.9:3000/api';
  static const String baseUrl = 'https://pcc-backend-production-465a.up.railway.app/api';
  
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  String? _token;
  String? _role;
  String? _name;
  String? _studentId;
  int? _instituteId;
  String? _instituteName;
  String? _instituteCode;

  String? get role => _role;
  String? get name => _name;
  String? get studentId => _studentId;
  int? get instituteId => _instituteId;
  String? get instituteName => _instituteName;
  String? get instituteCode => _instituteCode;
  String? get token => _token;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Initialize and load token
  Future<void> init() async {
    _token = await _storage.read(key: 'auth_token');
    _role = await _storage.read(key: 'auth_role');
    _name = await _storage.read(key: 'auth_name');
    _studentId = await _storage.read(key: 'auth_student_id');
    final instId = await _storage.read(key: 'auth_institute_id');
    _instituteId = instId != null ? int.tryParse(instId) : null;
    _instituteName = await _storage.read(key: 'auth_institute_name');
    _instituteCode = await _storage.read(key: 'auth_institute_code');
    
    if (_token != null) {
      registerDeviceToken().catchError((e) => print("Token sync failed: $e"));
    }
  }

  // Save token
  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> saveAuthData({required String role, String? name, String? studentId, int? instituteId, String? instituteName, String? instituteCode}) async {
    _role = role;
    _name = name;
    _studentId = studentId;
    _instituteId = instituteId;
    _instituteName = instituteName;
    _instituteCode = instituteCode;
    await _storage.write(key: 'auth_role', value: role);
    if (name != null) await _storage.write(key: 'auth_name', value: name);
    if (studentId != null) await _storage.write(key: 'auth_student_id', value: studentId);
    if (instituteId != null) await _storage.write(key: 'auth_institute_id', value: instituteId.toString());
    if (instituteName != null) await _storage.write(key: 'auth_institute_name', value: instituteName);
    if (instituteCode != null) await _storage.write(key: 'auth_institute_code', value: instituteCode);
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _name = null;
    _studentId = null;
    _instituteId = null;
    _instituteName = null;
    _instituteCode = null;
    await _storage.deleteAll();
  }

  // Get headers
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Handle response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(response.body);
    } else {
      dynamic error;
      try {
        error = json.decode(response.body);
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
      throw Exception(error['error'] ?? 'Unknown error occurred');
    }
  }

  // Common wrapper to handle missing internet connections
  Future<http.Response> _executeWithRetry(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        throw Exception('No Internet Connection. Please check your network and try again.');
      }
      rethrow;
    }
  }

  // Register device token with backend
  Future<void> registerDeviceToken() async {
    try {
      final token = await NotificationService.getDeviceToken();
      if (token == null) return;
      
      await http.post(
        Uri.parse('$baseUrl/notifications/register-token'),
        headers: _getHeaders(),
        body: json.encode({
          'token': token,
          'device_info': 'Flutter Android App'
        }),
      );
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  // ==================== AUTH ====================
  
  Future<Map<String, dynamic>> adminLogin(String username, String password, {String? totpCode}) async {
    final body = <String, dynamic>{'username': username, 'password': password};
    if (totpCode != null && totpCode.isNotEmpty) body['totpCode'] = totpCode;
    
    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$baseUrl/auth/admin/login'),
      headers: _getHeaders(),
      body: json.encode(body),
    ));
    final data = _handleResponse(response);
    if (data['token'] != null) {
      await saveToken(data['token']);
      await saveAuthData(
        role: data['role'] ?? 'super_admin',
        name: data['name'] ?? 'Admin',
        instituteId: data['instituteId'] != null ? int.tryParse(data['instituteId'].toString()) : null,
        instituteName: data['instituteName'] ?? '',
        instituteCode: data['instituteCode'] ?? '',
      );
      await registerDeviceToken();
    }
    return data;
  }

  Future<Map<String, dynamic>> parentLogin(String username, String password) async {
    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$baseUrl/auth/parent/login'),
      headers: _getHeaders(),
      body: json.encode({
        'username': username,
        'password': password,
      }),
    ));
    final data = _handleResponse(response);
    if (data['token'] != null) {
      await saveToken(data['token']);
      await saveAuthData(
        role: 'parent',
        studentId: data['studentId'],
        instituteId: data['instituteId'] != null ? int.tryParse(data['instituteId'].toString()) : null,
        instituteName: data['instituteName'] ?? '',
        instituteCode: data['instituteCode'] ?? '',
      );
      await registerDeviceToken();
    }
    return data;
  }

  // ==================== STUDENTS ====================
  
  Future<List<dynamic>> getStudents() async {
    final response = await _executeWithRetry(() => http.get(
      Uri.parse('$baseUrl/students?limit=1000'),
      headers: _getHeaders(),
    ));
    final result = _handleResponse(response);
    if (result is Map && result.containsKey('data')) return List<dynamic>.from(result['data']);
    return result;
  }

  Future<Map<String, dynamic>> getStudent(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> studentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/students'),
      headers: _getHeaders(),
      body: json.encode(studentData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateStudent(String studentId, Map<String, dynamic> studentData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/students/$studentId'),
      headers: _getHeaders(),
      body: json.encode(studentData),
    );
    return _handleResponse(response);
  }

  Future<void> deleteStudent(String studentId, {bool deleteFees = false}) async {
    final response = await _executeWithRetry(() => http.delete(
      Uri.parse('$baseUrl/students/$studentId?deleteFees=$deleteFees'),
      headers: _getHeaders(),
    ));
    _handleResponse(response);
  }

  // ==================== ATTENDANCE ====================
  
  Future<List<dynamic>> getStudentAttendance(String studentId, {String? startDate, String? endDate}) async {
    var url = '$baseUrl/attendance/student/$studentId';
    if (startDate != null && endDate != null) {
      url += '?startDate=$startDate&endDate=$endDate';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getAttendanceByDate(String date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/date/$date'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> markAttendance(Map<String, dynamic> attendanceData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: _getHeaders(),
      body: json.encode(attendanceData),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> bulkMarkAttendance(List<Map<String, dynamic>> records) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/bulk'),
      headers: _getHeaders(),
      body: json.encode({'records': records}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAttendanceStats(String studentId, {String? startDate, String? endDate}) async {
    var url = '$baseUrl/attendance/stats/$studentId';
    if (startDate != null && endDate != null) {
      url += '?startDate=$startDate&endDate=$endDate';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getWeeklyAttendanceTrends() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/trends/weekly'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // ==================== TESTS ====================
  
  Future<List<dynamic>> getTests({String? className}) async {
    var url = '$baseUrl/tests?limit=200';
    if (className != null) {
      url += '&className=$className';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );
    final result = _handleResponse(response);
    if (result is Map && result.containsKey('data')) return List<dynamic>.from(result['data']);
    return result;
  }

  Future<List<dynamic>> getStudentTests(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tests/student/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createTest(Map<String, dynamic> testData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tests'),
      headers: _getHeaders(),
      body: json.encode(testData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateTest(int testId, Map<String, dynamic> testData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tests/$testId'),
      headers: _getHeaders(),
      body: json.encode(testData),
    );
    return _handleResponse(response);
  }

  Future<void> deleteTest(int testId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tests/$testId'),
      headers: _getHeaders(),
    );
    _handleResponse(response);
  }

  // ==================== MARKS ====================
  
  Future<List<dynamic>> getTestMarks(int testId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/marks/test/$testId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getStudentMarks(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/marks/student/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> enterMarks(Map<String, dynamic> marksData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/marks'),
      headers: _getHeaders(),
      body: json.encode(marksData),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> bulkEnterMarks(List<Map<String, dynamic>> records) async {
    final response = await http.post(
      Uri.parse('$baseUrl/marks/bulk'),
      headers: _getHeaders(),
      body: json.encode({'records': records}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getTestAnalytics(int testId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/marks/analytics/$testId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // ==================== FEES ====================
  
  Future<List<dynamic>> getAllFees() async {
    final response = await _executeWithRetry(() => http.get(
      Uri.parse('$baseUrl/fees?limit=1000'),
      headers: _getHeaders(),
    ));
    final result = _handleResponse(response);
    if (result is Map && result.containsKey('data')) return List<dynamic>.from(result['data']);
    return result;
  }

  Future<Map<String, dynamic>> getStudentFees(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fees/student/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateFees(String studentId, Map<String, dynamic> feeData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/fees/$studentId'),
      headers: _getHeaders(),
      body: json.encode(feeData),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateTotalFees(String studentId, double totalFees, String reason) async {
    final response = await http.put(
      Uri.parse('$baseUrl/fees/$studentId/total'),
      headers: _getHeaders(),
      body: json.encode({'totalFees': totalFees, 'reason': reason}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addPayment(String studentId, double amount, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fees/payment'),
      headers: _getHeaders(),
      body: json.encode({
        'studentId': studentId,
        'amount': amount,
        'reason': reason,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addAdjustment(String studentId, double amount, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fees/adjustment'),
      headers: _getHeaders(),
      body: json.encode({
        'studentId': studentId,
        'amount': amount,
        'reason': reason,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getFeeStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/fees/stats/summary'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getPaymentLedger(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fees/ledger/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Backward compat alias
  Future<List<dynamic>> getPaymentHistory(String studentId) => getPaymentLedger(studentId);

  // ==================== QUESTION PAPERS ====================

  Future<Map<String, dynamic>> createQuestionPaper(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/question-papers'),
      headers: _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getQuestionPapers({String? className}) async {
    var url = '$baseUrl/question-papers?limit=200';
    if (className != null) url += '&class_name=$className';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    final result = _handleResponse(response);
    if (result is Map && result.containsKey('data')) return List<dynamic>.from(result['data']);
    return result;
  }

  Future<Map<String, dynamic>> getQuestionPaper(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/question-papers/$id'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateQuestionPaper(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/question-papers/$id'),
      headers: _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<void> deleteQuestionPaper(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/question-papers/$id'),
      headers: _getHeaders(),
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> publishQuestionPaper(int id, {bool? isPublished, bool? includeAnswerKey}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/question-papers/$id/publish'),
      headers: _getHeaders(),
      body: json.encode({
        'is_published': isPublished,
        'include_answer_key': includeAnswerKey,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getPublishedQuestionPapers({String? className}) async {
    var url = '$baseUrl/question-papers/published';
    if (className != null) url += '?class_name=$className';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> aiGenerateQuestions(Map<String, dynamic> params) async {
    final response = await http.post(
      Uri.parse('$baseUrl/question-papers/ai-generate'),
      headers: _getHeaders(),
      body: json.encode(params),
    );
    return _handleResponse(response);
  }

  // ==================== MCQ SELF-TESTS ====================

  Future<Map<String, dynamic>> getMcqChapters({String? className, String? subject}) async {
    var url = '$baseUrl/mcq-tests/chapters';
    final params = <String>[];
    if (className != null) params.add('class_name=$className');
    if (subject != null) params.add('subject=$subject');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> generateMcqQuestions({
    required String className,
    required String subject,
    required String chapter,
  }) async {
    final response = await _executeWithRetry(() => http.post(
      Uri.parse('$baseUrl/mcq-tests/generate'),
      headers: _getHeaders(),
      body: json.encode({
        'class_name': className,
        'subject': subject,
        'chapter': chapter,
      }),
    ));
    // The backend endpoint returns `{ questions: [...] }` so we just handle it
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> submitMcqTest({
    required String studentId,
    required String className,
    required String subject,
    required String chapter,
    required int score,
    required int total,
    required List<Map<String, dynamic>> questionsData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mcq-tests/submit'),
      headers: _getHeaders(),
      body: json.encode({
        'student_id': studentId,
        'class_name': className,
        'subject': subject,
        'chapter': chapter,
        'score': score,
        'total': total,
        'questions_data': questionsData,
      }),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getMcqScores(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mcq-tests/scores/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // ==================== NOTIFICATIONS ====================

  Future<Map<String, dynamic>> sendNotification({required String title, required String body, String? targetClass, String targetType = 'all', String channel = 'both'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: _getHeaders(),
      body: json.encode({'title': title, 'body': body, 'targetClass': targetClass, 'targetType': targetType, 'channel': channel}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendFeeReminder({String channel = 'both'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/fee-reminder'),
      headers: _getHeaders(),
      body: json.encode({'channel': channel}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendHolidayNotification({required String holidayName, required String date, String? description, String channel = 'both'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/holiday'),
      headers: _getHeaders(),
      body: json.encode({'holidayName': holidayName, 'date': date, 'description': description, 'channel': channel}),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications?page=$page&limit=$limit'),
      headers: _getHeaders(),
    );
    final result = _handleResponse(response);
    if (result is Map && result.containsKey('data')) return List<dynamic>.from(result['data']);
    return result;
  }

  Future<List<dynamic>> getStudentNotifications(String studentId, {int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/student/$studentId?page=$page&limit=$limit'),
      headers: _getHeaders(),
    );
    final result = _handleResponse(response);
    if (result is Map && result.containsKey('data')) return List<dynamic>.from(result['data']);
    return result;
  }

  Future<Map<String, dynamic>> updateNotification({required int id, String? title, String? body}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: _getHeaders(),
      body: json.encode({'title': title, 'body': body}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> registerFcmToken(String studentId, String token, {String? deviceInfo}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/register-token'),
      headers: _getHeaders(),
      body: json.encode({'studentId': studentId, 'token': token, 'deviceInfo': deviceInfo}),
    );
    return _handleResponse(response);
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/dashboard'), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<List<dynamic>> getFeeSummaryByClass() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/fee-summary'), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<List<dynamic>> getAttendanceTrends({int weeks = 8}) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/attendance-trends?weeks=$weeks'), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<List<dynamic>> getPerformanceBySubject() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/performance'), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<List<dynamic>> getClassDistribution() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/class-distribution'), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<String> exportStudentsCsv() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/export/students'), headers: _getHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) return response.body;
    throw Exception('Export failed');
  }

  Future<String> exportFeesCsv() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/export/fees'), headers: _getHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) return response.body;
    throw Exception('Export failed');
  }

  Future<String> exportAttendanceCsv({String? startDate, String? endDate}) async {
    var url = '$baseUrl/analytics/export/attendance';
    if (startDate != null && endDate != null) url += '?startDate=$startDate&endDate=$endDate';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    if (response.statusCode >= 200 && response.statusCode < 300) return response.body;
    throw Exception('Export failed');
  }

  // ==================== STAFF MANAGEMENT ====================

  Future<List<dynamic>> getStaffList() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/staff'), headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/staff'),
      headers: _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateStaff(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/staff/$id'),
      headers: _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<void> deleteStaff(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/auth/staff/$id'), headers: _getHeaders());
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _getHeaders(),
      body: json.encode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    return _handleResponse(response);
  }

  // ==================== CONSENT (DPDP Act) ====================

  Future<Map<String, dynamic>> getConsentStatus(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/consent-status/$studentId'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> acceptConsent() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/accept-consent'),
      headers: _getHeaders(),
      body: json.encode({}),
    );
    return _handleResponse(response);
  }

  // ==================== AUDIT LOG ====================

  Future<Map<String, dynamic>> getAuditLog({int page = 1, int limit = 50, String? action}) async {
    var url = '$baseUrl/analytics/audit-log?page=$page&limit=$limit';
    if (action != null) url += '&action=$action';
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    return _handleResponse(response);
  }
}
