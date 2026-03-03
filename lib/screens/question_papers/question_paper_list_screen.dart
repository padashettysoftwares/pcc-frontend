import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../models/question_paper.dart';
import '../../providers/question_paper_provider.dart';
import '../../services/api_service.dart';
import '../../services/question_paper_pdf_service.dart';
import '../../utils/theme.dart';
import 'manual_paper_builder_screen.dart';
import 'ai_paper_generator_screen.dart';
import 'paper_preview_screen.dart';

class QuestionPaperListScreen extends StatefulWidget {
  const QuestionPaperListScreen({super.key});

  @override
  State<QuestionPaperListScreen> createState() => _QuestionPaperListScreenState();
}

class _QuestionPaperListScreenState extends State<QuestionPaperListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestionPaperProvider>().loadPapers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question Papers', style: AppTextStyles.subHeading),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<QuestionPaperProvider>().loadPapers(),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
      body: Consumer<QuestionPaperProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.papers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.papers.isEmpty) {
            return _buildErrorState(context, provider);
          }
          if (provider.papers.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadPapers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.papers.length,
              itemBuilder: (context, index) => _buildPaperCard(provider.papers[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFFC62828)),
            ),
            const SizedBox(height: 20),
            Text('Could not load papers', style: AppTextStyles.subHeading),
            const SizedBox(height: 8),
            Text(
              'Make sure the server is running and your device is on the same network.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadPapers(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can still create a new paper using the buttons below ↓',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.description_outlined, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No Question Papers Yet', style: AppTextStyles.subHeading),
          const SizedBox(height: 8),
          Text(
            'Create your first question paper\nmanually or using AI',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'ai',
          backgroundColor: AppColors.success,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiPaperGeneratorScreen()),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'manual',
          backgroundColor: AppColors.primary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManualPaperBuilderScreen()),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPaperCard(QuestionPaper paper) {
    final provider = context.read<QuestionPaperProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: paper.isPublished ? AppColors.successLight : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paper.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: paper.isPublished ? AppColors.successDark : AppColors.warningDark,
                    ),
                  ),
                ),
                if (paper.isAiGenerated) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.infoDark),
                        SizedBox(width: 4),
                        Text('AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.infoDark)),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, paper),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'preview', child: Text('Preview')),
                    const PopupMenuItem(value: 'pdf', child: Text('Generate PDF')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              '${paper.subject} — Class ${paper.className}',
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
            ),
            if (paper.chapter != null && paper.chapter!.isNotEmpty)
              Text(paper.chapter!, style: AppTextStyles.body),
            const SizedBox(height: 8),

            // Meta row
            Row(
              children: [
                _metaChip(Icons.grade_outlined, '${paper.totalMarks} marks'),
                const SizedBox(width: 12),
                if (paper.timeDuration != null)
                  _metaChip(Icons.timer_outlined, paper.timeDuration!),
                const SizedBox(width: 12),
                if (paper.examType != null)
                  _metaChip(Icons.event_note_outlined, paper.examType!),
              ],
            ),
            const SizedBox(height: 12),

            // Toggles
            Row(
              children: [
                Expanded(
                  child: _toggleRow(
                    'Publish',
                    paper.isPublished,
                    (val) => provider.togglePublish(paper.id!, val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _toggleRow(
                    'Answer Key',
                    paper.includeAnswerKey,
                    (val) => provider.togglePublish(paper.id!, paper.isPublished, includeAnswerKey: val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        SizedBox(
          height: 24,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, QuestionPaper paper) async {
    switch (action) {
      case 'preview':
        // Fetch full paper with questions
        try {
          final data = await ApiService().getQuestionPaper(paper.id!);
          final fullPaper = QuestionPaper.fromMap(data);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaperPreviewScreen(paper: fullPaper)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading paper: $e')),
            );
          }
        }
        break;
      case 'pdf':
        try {
          final data = await ApiService().getQuestionPaper(paper.id!);
          final fullPaper = QuestionPaper.fromMap(data);
          final pdfBytes = await QuestionPaperPdfService().generateQuestionPaperPdf(fullPaper);
          if (mounted) {
            await Printing.layoutPdf(onLayout: (_) => pdfBytes);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating PDF: $e')),
            );
          }
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Paper?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          context.read<QuestionPaperProvider>().deletePaper(paper.id!);
        }
        break;
    }
  }
}
