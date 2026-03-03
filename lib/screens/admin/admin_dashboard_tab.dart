import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';
import '../question_papers/question_paper_list_screen.dart';
import 'staff_management_screen.dart';
import 'notification_screen.dart';
import 'analytics_export_screen.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'audit_log_screen.dart';

class AdminDashboardTab extends StatelessWidget {
  final String role;
  final String staffName;

  const AdminDashboardTab({super.key, this.role = 'super_admin', this.staffName = 'Admin'});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = DateFormat('EEEE, d MMMM').format(now);
    final c = Theme.of(context).pcc;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: CustomScrollView(
        slivers: [
          // ═══════ GRADIENT HEADER ═══════
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
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
                      // ── Top row ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $staffName',
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      role.replaceAll('_', ' ').toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    date,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Center(
                                  child: Text(staffName.isNotEmpty ? staffName[0].toUpperCase() : 'A',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text('Are you sure you want to logout?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Logout'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    final api = ApiService();
                                    await api.logout();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Dark mode toggle row ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dark ? 'Dark Mode' : 'Light Mode',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 24,
                              child: Switch(
                                value: dark,
                                onChanged: (_) => context.read<ThemeProvider>().toggle(),
                                activeThumbColor: Colors.white,
                                activeTrackColor: Colors.white.withValues(alpha: 0.35),
                                inactiveThumbColor: Colors.white.withValues(alpha: 0.9),
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Inline metrics row ──
                      Consumer3<StudentProvider, FeeProvider,
                          AttendanceProvider>(
                        builder: (ctx, sProv, fProv, aProv, _) {
                          final total = sProv.students.length;
                          final present = aProv.todayPresentCount;
                          return Row(
                            children: [
                              _headerStat('Students', '$total',
                                  Icons.school_rounded),
                              const SizedBox(width: 20),
                              _headerStat('Present', '$present',
                                  Icons.check_circle_rounded),
                              const SizedBox(width: 20),
                              _headerStat(
                                  'Absent',
                                  '${total - present}',
                                  Icons.cancel_rounded),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ═══════ BODY ═══════
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Metrics Grid ──
                Consumer3<StudentProvider, FeeProvider, AttendanceProvider>(
                  builder: (ctx, sProv, fProv, aProv, _) {
                    final fmt = NumberFormat.compactCurrency(
                        symbol: '₹', decimalDigits: 1);
                    return Column(
                      children: [
                        // Row 1: Role-dependent
                        Row(children: [
                          if (role != 'teacher') ...[
                            Expanded(
                                child: _metricCard(
                              'Total Revenue',
                              fmt.format(fProv.totalCollected),
                              'Collected',
                              Icons.trending_up_rounded,
                              const Color(0xFF10B981),
                              c,
                            )),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                              child: _metricCard(
                            'Active Today',
                            '${aProv.todayPresentCount}',
                            '/ ${sProv.students.length} students',
                            Icons.people_rounded,
                            const Color(0xFF6C5CE7),
                            c,
                          )),
                          if (role == 'teacher') ...[
                            const SizedBox(width: 12),
                            Expanded(
                                child: _metricCard(
                              'Total Students',
                              '${sProv.students.length}',
                              'Enrolled',
                              Icons.school_rounded,
                              const Color(0xFF3B82F6),
                              c,
                            )),
                          ],
                        ]),
                        const SizedBox(height: 12),
                        // Row 2: Role-dependent
                        Row(children: [
                          if (role != 'teacher') ...[
                            Expanded(
                                child: _metricCard(
                              'Pending Fees',
                              fmt.format(fProv.totalPending),
                              'Outstanding',
                              Icons.receipt_long_rounded,
                              const Color(0xFFF59E0B),
                              c,
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _metricCard(
                              'Total Students',
                              '${sProv.students.length}',
                              'Enrolled',
                              Icons.school_rounded,
                              const Color(0xFF3B82F6),
                              c,
                            )),
                          ] else ...[
                            Expanded(
                                child: _metricCard(
                              'Attendance',
                              '${sProv.students.isNotEmpty ? ((aProv.todayPresentCount / sProv.students.length) * 100).toStringAsFixed(0) : 0}%',
                              'Today\'s Rate',
                              Icons.check_circle_rounded,
                              const Color(0xFF10B981),
                              c,
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _metricCard(
                              'Absent',
                              '${sProv.students.length - aProv.todayPresentCount}',
                              'Today',
                              Icons.cancel_rounded,
                              const Color(0xFFEF4444),
                              c,
                            )),
                          ],
                        ]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Question Papers Card ──
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuestionPaperListScreen()),
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
                      borderRadius: BorderRadius.circular(14),
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Question Papers',
                                style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                                )),
                              const SizedBox(height: 2),
                              Text('Create, manage & distribute papers',
                                style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white70,
                                )),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Quick Actions Row (role-based) ──
                _buildQuickActions(context),

                const SizedBox(height: 28),

                // ── Chart Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Attendance Trends',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Text('This Week',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: c.textSecondary,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16, color: c.textTertiary),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Chart ──
                Container(
                  height: 260,
                  padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: dark ? 0.15 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Consumer<AttendanceProvider>(
                    builder: (ctx, aProv, _) {
                      final stats = aProv.weeklyStats;
                      final spots = <FlSpot>[];
                      final now2 = DateTime.now();
                      for (var i = 6; i >= 0; i--) {
                        final d = now2.subtract(Duration(days: i));
                        final key = d.toIso8601String().split('T')[0];
                        spots.add(FlSpot(
                            (6 - i).toDouble(), (stats[key] ?? 0).toDouble()));
                      }

                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: c.border.withValues(alpha: 0.6),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                interval: 10,
                                getTitlesWidget: (v, _) => Text(
                                  v.toInt().toString(),
                                  style: GoogleFonts.inter(
                                      color: c.textTertiary,
                                      fontSize: 11),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (v, _) {
                                  final d = DateTime.now().subtract(
                                      Duration(days: 6 - v.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(DateFormat('E').format(d),
                                        style: GoogleFonts.inter(
                                            color: c.textTertiary,
                                            fontSize: 11)),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: 50,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: const Color(0xFF6C5CE7),
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) =>
                                    FlDotCirclePainter(
                                  radius: 3,
                                  color: c.card,
                                  strokeWidth: 2,
                                  strokeColor: const Color(0xFF6C5CE7),
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF6C5CE7)
                                        .withValues(alpha: 0.1),
                                    const Color(0xFF6C5CE7)
                                        .withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header stat chip ──
  static Widget _headerStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  // ── Metric card ──
  static Widget _metricCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color accent,
    dynamic c,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.textTertiary,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 2),
          Text(sub,
              style: GoogleFonts.inter(
                  fontSize: 12, color: c.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <Widget>[];

    // Super Admin sees Staff Management
    if (role == 'super_admin' || role == 'admin') {
      actions.add(Expanded(child: _quickAction(context, 'Staff', Icons.people_alt_rounded, const Color(0xFF3498DB), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen()));
      })));
      actions.add(const SizedBox(width: 10));
    }

    // Teacher + Super Admin see Question Papers
    if (role == 'super_admin' || role == 'admin' || role == 'teacher') {
      actions.add(Expanded(child: _quickAction(context, 'Papers', Icons.description_rounded, const Color(0xFF8E44AD), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionPaperListScreen()));
      })));
      actions.add(const SizedBox(width: 10));
    }

    // Everyone gets Notifications
    actions.add(Expanded(child: _quickAction(context, 'Notify', Icons.notifications_rounded, const Color(0xFFF39C12), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
    })));
    actions.add(const SizedBox(width: 10));

    // Everyone gets Export
    actions.add(Expanded(child: _quickAction(context, 'Export', Icons.analytics_rounded, const Color(0xFF2ECC71), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsExportScreen()));
    })));

    // Super Admin gets Audit Log
    if (role == 'super_admin' || role == 'admin') {
      actions.add(const SizedBox(width: 10));
      actions.add(Expanded(child: _quickAction(context, 'Audit', Icons.history_rounded, const Color(0xFFE74C3C), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen()));
      })));
    }

    return Row(children: actions);
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final c = Theme.of(context).pcc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.fieldBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }
}
