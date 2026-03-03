import 'package:flutter/material.dart';
import '../../models/test.dart';
import '../../widgets/metric_card.dart';
import '../../utils/theme.dart';

class TestAnalyticsScreen extends StatelessWidget {
  final Test test;
  const TestAnalyticsScreen({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Analysis: ${test.testName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Class Average',
                    value: '76%',
                    icon: Icons.trending_up,
                    accentColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Highest Score',
                    value: '98',
                    icon: Icons.emoji_events_outlined,
                    accentColor: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Score Distribution', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text('Chart coming soon', style: AppTextStyles.body),
              ),
            ),

            const SizedBox(height: 24),
            Text('Top Performers', style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => _buildRankTile(i + 1, 'Student Name ${i + 1}', 98 - i * 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildRankTile(int rank, String name, int score) {
    final colors = [AppColors.warning, AppColors.textTertiary, const Color(0xFFCD7F32)];
    final color = rank <= 3 ? colors[rank - 1] : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTextStyles.bodyMedium)),
          Text(
            '$score/${test.totalMarks}',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
