import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/metric_card.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/attendance_provider.dart';
import 'question_papers/question_paper_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
      Provider.of<FeeProvider>(context, listen: false).fetchFees();
      Provider.of<AttendanceProvider>(context, listen: false).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM').format(now);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dashboard', style: AppTextStyles.heading),
                          const SizedBox(height: 2),
                          Text(formattedDate, style: AppTextStyles.body),
                        ],
                      ),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Metrics
                  Consumer3<StudentProvider, FeeProvider, AttendanceProvider>(
                    builder: (context, studentProv, feeProv, attendProv, _) {
                      final totalStudents = studentProv.students.length;
                      final todayPresent = attendProv.todayPresentCount;
                      final revenue = feeProv.totalCollected;
                      final pending = feeProv.totalPending;
                      final currencyFormat = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 1);

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Total Revenue',
                                  value: currencyFormat.format(revenue),
                                  subValue: 'Collected',
                                  icon: Icons.trending_up,
                                  accentColor: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Active Today',
                                  value: '$todayPresent',
                                  subValue: '/ $totalStudents students',
                                  icon: Icons.people_outline,
                                  accentColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: 'Pending Fees',
                                  value: currencyFormat.format(pending),
                                  subValue: 'Outstanding',
                                  icon: Icons.receipt_long_outlined,
                                  accentColor: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: 'Total Students',
                                  value: '$totalStudents',
                                  subValue: 'Enrolled',
                                  icon: Icons.school_outlined,
                                  accentColor: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quick Actions - Question Papers
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
                                Text('Question Papers', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('Create, manage & distribute papers', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Chart Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attendance Trends', style: AppTextStyles.subHeading),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('This Week', style: AppTextStyles.label.copyWith(fontSize: 12)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chart
                  Container(
                    height: 260,
                    padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    child: Consumer<AttendanceProvider>(
                      builder: (context, attendProv, _) {
                        final stats = attendProv.weeklyStats;
                        final spots = <FlSpot>[];
                        final now = DateTime.now();

                        for (int i = 6; i >= 0; i--) {
                          final day = now.subtract(Duration(days: i));
                          final dateStr = day.toIso8601String().split('T')[0];
                          final count = stats[dateStr] ?? 0;
                          spots.add(FlSpot((6 - i).toDouble(), count.toDouble()));
                        }

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 10,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.border.withValues(alpha: 0.5),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 10,
                                  getTitlesWidget: (val, meta) => Text(
                                    val.toInt().toString(),
                                    style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11),
                                  ),
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (val, meta) {
                                    final day = DateTime.now().subtract(Duration(days: 6 - val.toInt()));
                                    final dayName = DateFormat('E').format(day);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(dayName, style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
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
                                color: AppColors.primary,
                                barWidth: 2.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                    radius: 3,
                                    color: AppColors.cardBg,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.primary,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.08),
                                      AppColors.primary.withValues(alpha: 0.0),
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
      ),
    );
  }
}
