import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mcq_question.dart';
import '../../providers/mcq_test_provider.dart';
import '../../utils/theme.dart';

class McqScoreHistoryScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const McqScoreHistoryScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<McqScoreHistoryScreen> createState() => _McqScoreHistoryScreenState();
}

class _McqScoreHistoryScreenState extends State<McqScoreHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<McqTestProvider>().loadScores(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Score History', style: AppTextStyles.subHeading),
      ),
      body: Consumer<McqTestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.scores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No test history', style: AppTextStyles.body),
                  const SizedBox(height: 4),
                  Text('Complete a test to see your scores', style: AppTextStyles.caption),
                ],
              ),
            );
          }

          // Group by chapter
          final Map<String, List<McqScore>> grouped = {};
          for (final s in provider.scores) {
            grouped.putIfAbsent(s.chapter, () => []);
            grouped[s.chapter]!.add(s);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.studentName, style: AppTextStyles.subHeading.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${provider.scores.length} tests completed', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _avgScore(provider.scores),
                            style: AppTextStyles.metricValue.copyWith(color: Colors.white, fontSize: 24),
                          ),
                          Text('Avg', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // By chapter
              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(entry.key, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    ...entry.value.map((s) => _buildScoreCard(s)),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(McqScore score) {
    final pct = score.percentage;
    final isGood = pct >= 60;
    final dateStr = score.createdAt != null
        ? score.createdAt!.split('T').first
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isGood ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${score.score}/${score.total}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isGood ? AppColors.successDark : AppColors.errorDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class ${score.className} · ${score.subject}', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(dateStr, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGood ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isGood ? AppColors.successDark : AppColors.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _avgScore(List<McqScore> scores) {
    if (scores.isEmpty) return '0%';
    final avg = scores.fold<double>(0, (sum, s) => sum + s.percentage) / scores.length;
    return '${avg.toStringAsFixed(0)}%';
  }
}
