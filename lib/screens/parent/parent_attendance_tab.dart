import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class ParentAttendanceTab extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ParentAttendanceTab({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentAttendanceTab> createState() => _ParentAttendanceTabState();
}

class _ParentAttendanceTabState extends State<ParentAttendanceTab> {
  final _api = ApiService();
  DateTime _focusedMonth = DateTime.now();
  Map<String, String> _attendanceMap = {}; // date -> status
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final startDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      final records = await _api.getStudentAttendance(
        widget.studentId,
        startDate: startStr,
        endDate: endStr,
      );
      final stats = await _api.getAttendanceStats(widget.studentId);

      final map = <String, String>{};
      for (var r in records) {
        final date = r['date']?.toString().split('T')[0] ?? '';
        map[date] = r['status'] ?? 'Absent';
      }

      setState(() {
        _attendanceMap = map;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadAttendance();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Stats Row ──
                if (_stats != null) ...[
                  Row(
                    children: [
                      _miniStat(
                        '${double.tryParse(_stats!['percentage']?.toString() ?? '0')?.toStringAsFixed(0) ?? '0'}%',
                        'Overall',
                        const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 10),
                      _miniStat(
                        '${_stats!['present'] ?? 0}',
                        'Present',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 10),
                      _miniStat(
                        '${_stats!['absent'] ?? 0}',
                        'Absent',
                        const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 10),
                      _miniStat(
                        '${_stats!['leave'] ?? 0}',
                        'Leave',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Calendar Section ──
                Text(
                  'Attendance Section',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monthly Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar card
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      _buildCalendarHeader(),
                      const SizedBox(height: 16),
                      _buildWeekdayLabels(),
                      const SizedBox(height: 8),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7)),
                            )
                          : _buildCalendarGrid(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Legend
                _buildLegend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    final c = Theme.of(context).pcc;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: c.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final c = Theme.of(context).pcc;
    final monthYear = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          monthYear,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        Row(
          children: [
            _iconBtn(Icons.chevron_left_rounded, _prevMonth),
            const SizedBox(width: 4),
            _iconBtn(Icons.chevron_right_rounded, _nextMonth),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    final c = Theme.of(context).pcc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.fieldFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18, color: c.textSecondary),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final c = Theme.of(context).pcc;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: days.map((d) {
        return Expanded(
          child: Center(
            child: Text(
              d,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textTertiary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final c = Theme.of(context).pcc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday; // Mon = 1
    final totalDays = lastDay.day;
    final today = DateTime.now();

    final cells = <Widget>[];

    // Empty cells for days before month start
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final status = _attendanceMap[dateStr];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSunday = date.weekday == 7;
      final isFuture = date.isAfter(today);

      Color bgColor = Colors.transparent;
      Color textColor = c.textPrimary;

      if (isFuture) {
        textColor = c.textTertiary;
      } else if (status == 'Present') {
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
      } else if (status == 'Absent') {
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
      } else if (status == 'Leave') {
        bgColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
      } else if (isSunday) {
        bgColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB);
        textColor = c.textTertiary;
      }

      cells.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: const Color(0xFF6C5CE7), width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: cells,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(const Color(0xFF10B981), 'Present'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFFEF4444), 'Absent'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFFF59E0B), 'Leave'),
        const SizedBox(width: 16),
        _legendDot(const Color(0xFFE5E7EB), 'Holiday'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    final c = Theme.of(context).pcc;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
