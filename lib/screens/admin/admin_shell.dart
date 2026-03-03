import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/theme.dart';
import 'admin_dashboard_tab.dart';
import '../students/student_list_screen.dart';
import '../attendance/attendance_screen.dart';
import '../tests/test_list_screen.dart';
import '../fees/fees_screen.dart';
import '../reports/reports_screen.dart';

class AdminShell extends StatefulWidget {
  final String role;
  final String staffName;

  const AdminShell({super.key, this.role = 'super_admin', this.staffName = 'Admin'});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  List<_NavItem> get _navItems {
    final role = widget.role;
    final items = <_NavItem>[];

    // Home — everyone sees (role-aware dashboard)
    items.add(_NavItem(Icons.grid_view_rounded, 'Home',
        AdminDashboardTab(role: role, staffName: widget.staffName)));

    if (role == 'super_admin' || role == 'admin') {
      // Super Admin: Home, Students, Attend, Tests, Fees, Reports
      items.add(_NavItem(Icons.people_rounded, 'Students', const StudentListScreen()));
      items.add(_NavItem(Icons.check_circle_rounded, 'Attend', const AttendanceScreen()));
      items.add(_NavItem(Icons.assignment_rounded, 'Tests', const TestListScreen()));
      items.add(_NavItem(Icons.receipt_long_rounded, 'Fees', const FeesScreen()));
      items.add(_NavItem(Icons.bar_chart_rounded, 'Reports', const ReportsScreen()));
    } else if (role == 'teacher') {
      // Teacher: Home, Students, Attend, Tests, Reports
      items.add(_NavItem(Icons.people_rounded, 'Students', const StudentListScreen()));
      items.add(_NavItem(Icons.check_circle_rounded, 'Attend', const AttendanceScreen()));
      items.add(_NavItem(Icons.assignment_rounded, 'Tests', const TestListScreen()));
      items.add(_NavItem(Icons.bar_chart_rounded, 'Reports', const ReportsScreen()));
    } else if (role == 'front_desk') {
      // Front Desk: Home, Fees, Reports
      items.add(_NavItem(Icons.receipt_long_rounded, 'Fees', const FeesScreen()));
      items.add(_NavItem(Icons.bar_chart_rounded, 'Reports', const ReportsScreen()));
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentProvider>().fetchStudents();
      context.read<FeeProvider>().fetchFees();
      context.read<AttendanceProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).pcc;
    final items = _navItems;

    if (_index >= items.length) _index = 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.scaffold,
        body: IndexedStack(
          index: _index,
          children: items.map((i) => i.screen).toList(),
        ),
        bottomNavigationBar: _nav(c, items),
      ),
    );
  }

  Widget _nav(dynamic c, List<_NavItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(
          top: BorderSide(color: c.navBorder.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++)
                _item(i, items[i].icon, items[i].label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final active = _index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_index != i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF6C5CE7).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: active ? const Color(0xFF6C5CE7) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? const Color(0xFF6C5CE7) : const Color(0xFF9CA3AF),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavItem(this.icon, this.label, this.screen);
}
