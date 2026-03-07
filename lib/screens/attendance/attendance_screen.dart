import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../utils/theme.dart';
import 'attendance_stats_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceMap = {};
  bool _isInit = true;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<StudentProvider>(context, listen: false).fetchStudents();
        }
      });
    }
  }

  Future<void> _fetchData() async {
    if (_selectedClass == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    await attProvider.fetchAttendance(dateStr, _selectedClass!);
    setState(() {
      _attendanceMap.clear();
      for (var record in attProvider.attendanceList) {
        _attendanceMap[record['student_id']] = record['status'];
      }
    });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null || _attendanceMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark attendance for at least one student')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final List<Attendance> listToSave = [];
    _attendanceMap.forEach((studentId, status) {
      listToSave.add(Attendance(studentId: studentId, date: dateStr, status: status));
    });
    await Provider.of<AttendanceProvider>(context, listen: false).saveBatchAttendance(listToSave);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance saved for ${listToSave.length} students'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final classes = studentProvider.students.map((e) => e.className).toSet().toList()..sort();
    final studentsInClass = _selectedClass == null
        ? <Student>[]
        : studentProvider.students.where((s) => s.className == _selectedClass).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Attendance'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceStatsScreen())),
            tooltip: 'View Stats',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildClassDropdown(classes)),
                    const SizedBox(width: 12),
                    _buildDateButton(),
                  ],
                ),
              ],
            ),
          ),

          // Student list
          Expanded(
            child: _selectedClass == null
                ? _buildEmptyState('Select a class to mark attendance')
                : studentsInClass.isEmpty
                    ? _buildEmptyState('No students in this class')
                    : _buildStudentList(studentsInClass),
          ),
        ],
      ),
      bottomNavigationBar: _selectedClass == null ? null : _buildSaveButton(),
    );
  }

  Widget _buildClassDropdown(List<String> classes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.cardBg,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          hint: Text('Select Class', style: AppTextStyles.body),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: classes
              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.bodyMedium)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedClass = val;
              _attendanceMap.clear();
            });
            _fetchData();
          },
        ),
      ),
    );
  }

  Widget _buildDateButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: const Text('Change'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _selectDate,
    );
  }

  Widget _buildStudentList(List<Student> students) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final student = students[index];
        final status = _attendanceMap[student.studentId];
        final isPresent = status == 'Present';
        final isAbsent = status == 'Absent';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPresent
                  ? AppColors.success.withValues(alpha: 0.5)
                  : isAbsent
                      ? AppColors.error.withValues(alpha: 0.5)
                      : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    student.name[0].toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text(student.studentId, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip('P', isPresent, AppColors.success, () {
                setState(() => _attendanceMap[student.studentId] = 'Present');
              }),
              const SizedBox(width: 6),
              _buildStatusChip('A', isAbsent, AppColors.error, () {
                setState(() => _attendanceMap[student.studentId] = 'Absent');
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42, height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_circle_outline, size: 28, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 14),
          Text(message, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveAttendance,
            child: _isSaving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Text('Save Attendance  (${_attendanceMap.length} marked)'),
          ),
        ),
      ),
    );
  }
}
