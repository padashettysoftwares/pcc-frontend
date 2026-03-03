import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/student.dart';
import '../../utils/theme.dart';
import 'parent_news_screen.dart';

class ParentHomeTab extends StatelessWidget {
  final Student student;
  final Map<String, dynamic>? fee;
  final Map<String, dynamic>? attendanceStats;
  final List<dynamic> recentMarks;
  final VoidCallback onPayFees;
  final VoidCallback onRefresh;

  const ParentHomeTab({
    super.key,
    required this.student,
    this.fee,
    this.attendanceStats,
    required this.recentMarks,
    required this.onPayFees,
    required this.onRefresh,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    final totalFees = double.tryParse(fee?['total_fees']?.toString() ?? '0') ?? 0;
    final paidAmount = double.tryParse(fee?['paid_amount']?.toString() ?? '0') ?? 0;
    final dueAmount = double.tryParse(fee?['due_amount']?.toString() ?? '0') ?? 0;
    final attendPct = double.tryParse(attendanceStats?['percentage']?.toString() ?? '0') ?? 0;
    final present = int.tryParse(attendanceStats?['present']?.toString() ?? '0') ?? 0;
    final total = int.tryParse(attendanceStats?['total']?.toString() ?? '0') ?? 0;

    // Calculate average score from recent marks
    double avgScore = 0;
    if (recentMarks.isNotEmpty) {
      final lastMarks = recentMarks.take(5).toList();
      double sumPct = 0;
      for (var m in lastMarks) {
        final marks = double.tryParse(m['marks_obtained']?.toString() ?? '0') ?? 0;
        final maxMarks = double.tryParse(m['total_marks']?.toString() ?? '100') ?? 100;
        sumPct += (maxMarks > 0 ? (marks / maxMarks) * 100 : 0);
      }
      avgScore = sumPct / lastMarks.length;
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF6C5CE7),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ══════════ GRADIENT HEADER ══════════
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()},',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.parentName.isNotEmpty
                                      ? student.parentName
                                      : 'Parent',
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${student.name} – ${student.className}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Student avatar
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: student.photoPath != null && student.photoPath!.isNotEmpty
                                  ? _buildStudentPhoto(student.photoPath!)
                                  : Center(
                                      child: Text(
                                        student.name[0].toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ── Two stat circles ──
                      Row(
                        children: [
                          _circularStat(
                            '${attendPct.toStringAsFixed(0)}%',
                            'Attendance',
                            attendPct / 100,
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 20),
                          _circularStat(
                            '${avgScore.toStringAsFixed(0)}%',
                            'Avg Score',
                            avgScore / 100,
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ══════════ BODY CONTENT ══════════
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Info Cards Row ──
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          context: context,
                          icon: Icons.currency_rupee_rounded,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          label: 'Pending Fees',
                          value: '₹${_formatNumber(dueAmount)}',
                          subtitle: dueAmount > 0 ? 'Due' : 'All Clear',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoCard(
                          context: context,
                          icon: Icons.assignment_outlined,
                          iconBg: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                          label: 'Classes Attended',
                          value: '$present/$total',
                          subtitle: 'This term',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── News Section Button ──
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParentNewsScreen(studentId: student.studentId),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'News & Notifications',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'View all messages from coaching',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Performance Section ──
                  Text(
                    'Performance Section',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Academic Performance Trend',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPerformanceChart(context),

                  const SizedBox(height: 24),

                  // ── Fee Summary Card ──
                  if (dueAmount > 0)
                    _buildFeeCard(context, totalFees, paidAmount, dueAmount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularStat(String value, String label, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Center(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Icon(Icons.trending_up_rounded, size: 16, color: color),
          ],
        ),
      ],
    );
  }

  Widget _infoCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    final c = Theme.of(context).pcc;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: c.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    final c = Theme.of(context).pcc;
    // Build chart spots from recent marks
    List<FlSpot> spots = [];
    List<String> labels = [];

    if (recentMarks.isNotEmpty) {
      final lastMarks = recentMarks.take(5).toList().reversed.toList();
      for (int i = 0; i < lastMarks.length; i++) {
        final marks = double.tryParse(lastMarks[i]['marks_obtained']?.toString() ?? '0') ?? 0;
        final maxMarks = double.tryParse(lastMarks[i]['total_marks']?.toString() ?? '100') ?? 100;
        final pct = maxMarks > 0 ? (marks / maxMarks) * 100 : 0;
        spots.add(FlSpot(i.toDouble(), pct.toDouble()));
        labels.add('Test ${i + 1}');
      }
    } else {
      // Placeholder data
      spots = [
        const FlSpot(0, 78), const FlSpot(1, 82), const FlSpot(2, 85),
        const FlSpot(3, 80), const FlSpot(4, 84),
      ];
      labels = ['Test 1', 'Test 2', 'Test 3', 'Test 4', 'Test 5'];
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: c.border,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: c.textTertiary,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[idx],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: c.textTertiary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF6C5CE7),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: c.card,
                  strokeWidth: 2.5,
                  strokeColor: const Color(0xFF6C5CE7),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                    const Color(0xFF6C5CE7).withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${s.y.toInt()}%',
                  GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeeCard(BuildContext context, double totalFees, double paidAmount, double dueAmount) {
    final c = Theme.of(context).pcc;
    final progress = totalFees > 0 ? (paidAmount / totalFees).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Section',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Payment Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.inter(fontSize: 14, color: c.textSecondary)),
              Text('₹${_formatNumber(totalFees)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation(
                progress >= 0.8 ? const Color(0xFF10B981) : const Color(0xFF6C5CE7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid ₹${_formatNumber(paidAmount)}',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
              ),
              Text(
                'Due ₹${_formatNumber(dueAmount)}',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // View Fees button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPayFees,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'View Fees',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double num) {
    if (num >= 1000) {
      return num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return num.toStringAsFixed(0);
  }

  /// Handles both local file paths and network URLs for student photo
  Widget _buildStudentPhoto(String path) {
    final fallback = Center(
      child: Text(
        student.name[0].toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }
}
