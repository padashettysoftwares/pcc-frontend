import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/test_provider.dart';
import 'add_test_screen.dart';
import 'enter_marks_screen.dart';
import 'test_analytics_screen.dart';
import '../../utils/theme.dart';
import '../question_papers/question_paper_list_screen.dart';
import '../question_papers/manual_paper_builder_screen.dart';
import '../question_papers/ai_paper_generator_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({super.key});

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) Provider.of<TestProvider>(context, listen: false).fetchTests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Tests'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.post_add_rounded, size: 22),
              tooltip: 'Create Question Paper',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                fixedSize: const Size(38, 38),
              ),
              onPressed: () => _showCreatePaperMenu(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add, size: 22),
              tooltip: 'Add Test',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                fixedSize: const Size(38, 38),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTestScreen())),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Question Papers Access Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Material(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuestionPaperListScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question Papers', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF6C5CE7))),
                            const SizedBox(height: 2),
                            Text('Create, manage & distribute papers', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6C5CE7), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Consumer<TestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          if (provider.tests.isEmpty) {
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
                    child: const Icon(Icons.assignment_outlined, size: 32, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 16),
                  Text('No tests created', style: AppTextStyles.subHeading),
                  const SizedBox(height: 6),
                  Text('Create your first test to get started', style: AppTextStyles.body),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: provider.tests.length,
            padding: const EdgeInsets.all(20),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final test = provider.tests[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EnterMarksScreen(test: test))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_outlined, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(test.testName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  '${test.subject}  ·  ${test.className}  ·  ${test.date}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${test.totalMarks}',
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.textTertiary),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TestAnalyticsScreen(test: test)),
                            ),
                            tooltip: 'View Analysis',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),          // close Expanded
  ],
),
);
  }

  void _showCreatePaperMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Question Paper', style: AppTextStyles.subHeading),
              const SizedBox(height: 4),
              Text('Choose how you want to build the paper', style: AppTextStyles.body),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                ),
                title: const Text('Build Manually', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Add questions section-by-section'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualPaperBuilderScreen()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00B894), size: 24),
                ),
                title: const Text('Generate with AI', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Instant AI-powered paper creation'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiPaperGeneratorScreen()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: Color(0xFF6C5CE7), size: 24),
                ),
                title: const Text('View All Papers', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Manage existing question papers'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionPaperListScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
