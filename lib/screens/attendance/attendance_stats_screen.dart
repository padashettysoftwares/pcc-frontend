import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class AttendanceStatsScreen extends StatelessWidget {
  const AttendanceStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Attendance Stats')),
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.students.isEmpty) {
            return Center(child: Text('No students found', style: AppTextStyles.body));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: provider.students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = provider.students[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: ApiService().getAttendanceStats(student.studentId),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {'total': 0, 'present': 0, 'percentage': 0};
                  final pct = double.tryParse(stats['percentage'].toString()) ?? 0.0;
                  final present = int.tryParse(stats['present'].toString()) ?? 0;
                  final total = int.tryParse(stats['total'].toString()) ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
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
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              Text(student.className, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: pct < 75 ? AppColors.error : AppColors.success,
                              ),
                            ),
                            Text('$present/$total', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
