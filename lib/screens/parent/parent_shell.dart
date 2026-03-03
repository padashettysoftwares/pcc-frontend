import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/student.dart';
import '../../utils/theme.dart';
import 'parent_home_tab.dart';
import 'parent_attendance_tab.dart';
import 'parent_fees_tab.dart';
import 'parent_profile_tab.dart';
import 'parent_papers_tab.dart';
import 'parent_mcq_tab.dart';

class ParentShell extends StatefulWidget {
  final String studentId;
  const ParentShell({super.key, required this.studentId});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _currentIndex = 0;
  final _api = ApiService();
  Student? _student;
  Map<String, dynamic>? _fee;
  Map<String, dynamic>? _attendanceStats;
  List<dynamic> _recentMarks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final studentData = await _api.getStudent(widget.studentId);
      final feeData = await _api.getStudentFees(widget.studentId);
      final attendData = await _api.getAttendanceStats(widget.studentId);

      List<dynamic> marks = [];
      try {
        marks = await _api.getStudentMarks(widget.studentId);
      } catch (_) {}

      setState(() {
        _student = Student(
          id: studentData['id'],
          studentId: studentData['student_id'],
          name: studentData['name'],
          className: studentData['class_name'],
          parentName: studentData['parent_name'],
          parentPhone: studentData['parent_phone'],
          admissionDate: studentData['admission_date'],
          photoPath: studentData['photo_path'],
          parentUsername: studentData['parent_username'],
          parentPassword: '',
        );
        _fee = feeData;
        _attendanceStats = attendData;
        _recentMarks = marks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.scaffold,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C5CE7),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_error != null || _student == null) {
      return Scaffold(
        backgroundColor: c.scaffold,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 20),
              Text('Something went wrong', style: AppTextStyles.subHeading),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _error ?? 'Unable to load data',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tabs = [
      ParentHomeTab(
        student: _student!,
        fee: _fee,
        attendanceStats: _attendanceStats,
        recentMarks: _recentMarks,
        onPayFees: () => setState(() => _currentIndex = 2),
        onRefresh: _loadData,
      ),
      ParentAttendanceTab(
        studentId: _student!.studentId,
        studentName: _student!.name,
      ),
      ParentFeesTab(
        student: _student!,
        fee: _fee,
        onPaymentComplete: _loadData,
      ),
      ParentPapersTab(
        studentId: _student!.studentId,
        className: _student!.className,
      ),
      ParentMcqTab(
        studentId: _student!.studentId,
        studentName: _student!.name,
      ),
      ParentProfileTab(
        student: _student!,
        onLogout: () {
          ApiService().logout();
        },
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_currentIndex == 0 || isDark)
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.scaffold,
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: c.navBg,
            border: Border(
              top: BorderSide(color: c.navBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                  _navItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Attend'),
                  _navItem(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Fees'),
                  _navItem(3, Icons.description_rounded, Icons.description_outlined, 'Papers'),
                  _navItem(4, Icons.quiz_rounded, Icons.quiz_outlined, 'Tests'),
                  _navItem(5, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    final c = Theme.of(context).pcc;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C5CE7).withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 22,
              color: isActive ? const Color(0xFF6C5CE7) : c.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF6C5CE7) : c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
