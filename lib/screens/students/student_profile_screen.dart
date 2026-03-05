import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/test_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'add_edit_student_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final Student student;
  final bool enableEdit;

  const StudentProfileScreen({super.key, required this.student, this.enableEdit = true});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _attendancePercentage = 0.0;
  double _averageScore = 0.0;
  List<double> _performanceTrend = [];
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStudentStats();
  }

  Future<void> _loadStudentStats() async {
    setState(() => _isLoadingStats = true);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final testProvider = Provider.of<TestProvider>(context, listen: false);
    final attendance = await attendanceProvider.getStudentAttendancePercentage(widget.student.studentId);
    final avgScore = await testProvider.getStudentAverageScore(widget.student.studentId);
    final trend = await testProvider.getStudentPerformanceTrend(widget.student.studentId);
    setState(() {
      _attendancePercentage = attendance;
      _averageScore = avgScore;
      _performanceTrend = trend;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context).students.firstWhere(
      (s) => s.studentId == widget.student.studentId,
      orElse: () => widget.student,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          if (widget.enableEdit)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditStudentScreen(student: student)),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Attendance'),
            Tab(text: 'Fees'),
            Tab(text: 'Academics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(student),
          _buildAttendanceTab(student),
          _buildFeesTab(student),
          _buildAcademicsTab(student),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: student.photoPath != null ? FileImage(File(student.photoPath!)) : null,
                  child: student.photoPath == null
                      ? Text(student.name[0].toUpperCase(),
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: AppTextStyles.subHeading),
                      const SizedBox(height: 4),
                      Text('${student.className}  ·  ID: ${student.studentId}', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Parent Details', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _infoRow(Icons.person_outline, 'Parent Name', student.parentName),
                Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                _infoRow(Icons.phone_outlined, 'Phone', student.parentPhone),
                if (widget.enableEdit) ...[
                  Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                  _infoRow(Icons.lock_outline, 'Username', student.parentUsername ?? 'N/A'),
                  Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                  _infoRow(Icons.vpn_key_outlined, 'Password', student.parentPassword ?? 'N/A'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Quick Stats', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
          const SizedBox(height: 10),

          if (_isLoadingStats)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else
            Row(
              children: [
                Expanded(child: _statCard('Attendance', '${_attendancePercentage.toStringAsFixed(1)}%', Icons.check_circle_outline, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Avg Score', '${_averageScore.toStringAsFixed(1)}%', Icons.trending_up, AppColors.success)),
              ],
            ),

          if (widget.enableEdit) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () => _showDeleteConfirmation(context, student),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
          const Spacer(),
          Flexible(child: Text(value, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(value, style: AppTextStyles.metricValue.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(Student student) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getAttendanceStats(student.studentId),
      builder: (context, statsSnapshot) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService().getStudentAttendance(student.studentId),
          builder: (context, recordsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting ||
                recordsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (statsSnapshot.hasError && recordsSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error loading attendance', style: AppTextStyles.body),
                  ],
                ),
              );
            }

            final stats = statsSnapshot.data ?? {};
            final records = recordsSnapshot.data ?? [];
            final total = _safeInt(stats['total']);
            final present = _safeInt(stats['present']);
            final absent = _safeInt(stats['absent']);
            final leave = _safeInt(stats['leave']);
            final percentage = _safeDouble(stats['percentage']);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Summary', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _miniStatBox('Total', '$total', AppColors.primary)),
                            const SizedBox(width: 8),
                            Expanded(child: _miniStatBox('Present', '$present', AppColors.success)),
                            const SizedBox(width: 8),
                            Expanded(child: _miniStatBox('Absent', '$absent', AppColors.error)),
                            const SizedBox(width: 8),
                            Expanded(child: _miniStatBox('Leave', '$leave', Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 8,
                                  backgroundColor: AppColors.border.withValues(alpha: 0.3),
                                  color: percentage >= 75 ? AppColors.success : (percentage >= 50 ? Colors.orange : AppColors.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${percentage.toStringAsFixed(1)}%', style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Recent Records', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
                  const SizedBox(height: 10),
                  if (records.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No attendance records yet', style: AppTextStyles.body),
                    ))
                  else
                    ...records.take(30).map((record) {
                      final status = record['status'] ?? '';
                      final date = record['date'] ?? '';
                      final color = status == 'Present'
                          ? AppColors.success
                          : status == 'Absent'
                              ? AppColors.error
                              : Colors.orange;
                      final icon = status == 'Present'
                          ? Icons.check_circle_outline
                          : status == 'Absent'
                              ? Icons.cancel_outlined
                              : Icons.info_outline;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: color),
                            const SizedBox(width: 12),
                            Expanded(child: Text(date.toString().split('T').first, style: AppTextStyles.body)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildFeesTab(Student student) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService().getStudentFees(student.studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                Text('No fee records found', style: AppTextStyles.body),
              ],
            ),
          );
        }

        final feeData = snapshot.data!;
        final totalFees = _safeDouble(feeData['total_fees']);
        final paidAmount = _safeDouble(feeData['paid_amount']);
        final dueAmount = _safeDouble(feeData['due_amount']);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fee Summary', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
                const SizedBox(height: 20),
                _buildFeeRow('Total Fees', '₹${totalFees.toStringAsFixed(0)}'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                ),
                _buildFeeRow('Paid Amount', '₹${paidAmount.toStringAsFixed(0)}', color: AppColors.success),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                ),
                _buildFeeRow('Due Amount', '₹${dueAmount.toStringAsFixed(0)}', color: AppColors.error),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeeRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary,
        )),
      ],
    );
  }

  Widget _buildAcademicsTab(Student student) {
    if (_isLoadingStats || _performanceTrend.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school_outlined, size: 28, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              _isLoadingStats ? 'Loading...' : 'No test records found',
              style: AppTextStyles.body,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Trend', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            height: 260,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, drawVerticalLine: false, horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5), strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                    ),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _performanceTrend.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('T${index + 1}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        );
                      }
                      return const SizedBox();
                    },
                  )),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: (_performanceTrend.length - 1).toDouble(),
                minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _performanceTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3, color: AppColors.cardBg, strokeWidth: 2, strokeColor: AppColors.primary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true, color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Student student) {
    bool deleteFees = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                const Text('Delete Student', style: TextStyle(color: AppColors.error)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to permanently delete ${student.name}? This action cannot be undone.', style: AppTextStyles.body),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: deleteFees,
                        onChanged: (val) => setState(() => deleteFees = val ?? false),
                        activeColor: AppColors.error,
                      ),
                      const Expanded(
                        child: Text(
                          'Also delete all fee & payment ledger records?',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('WARNING: If you do not check this box, deletion will fail if the student has payment history due to financial auditing rules.', 
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(ctx);
                  _executeDelete(student, deleteFees);
                },
                child: const Text('Delete Permanently'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _executeDelete(Student student, bool deleteFees) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      await Provider.of<StudentProvider>(context, listen: false).deleteStudent(student.studentId, deleteFees: deleteFees);
      
      if (!mounted) return;
      Navigator.pop(context); 
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error, duration: const Duration(seconds: 4)),
      );
    }
  }
}
