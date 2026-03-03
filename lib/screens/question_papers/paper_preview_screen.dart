import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../models/question_paper.dart';
import '../../providers/question_paper_provider.dart';
import '../../services/question_paper_pdf_service.dart';
import '../../utils/theme.dart';

class PaperPreviewScreen extends StatefulWidget {
  final QuestionPaper paper;
  final bool isNewPaper;

  const PaperPreviewScreen({super.key, required this.paper, this.isNewPaper = false});

  @override
  State<PaperPreviewScreen> createState() => _PaperPreviewScreenState();
}

class _PaperPreviewScreenState extends State<PaperPreviewScreen> {
  late QuestionPaper _paper;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _paper = widget.paper;
  }

  @override
  Widget build(BuildContext context) {
    // Group by section
    final Map<String, List<QuestionPaperQuestion>> sections = {};
    for (final q in _paper.questions) {
      final sec = q.section ?? 'A';
      sections.putIfAbsent(sec, () => []);
      sections[sec]!.add(q);
    }
    final sortedSections = sections.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Paper Preview', style: AppTextStyles.subHeading),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
            tooltip: 'Generate PDF',
            onPressed: _generatePdf,
          ),
          if (widget.isNewPaper)
            TextButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              onPressed: _isSaving ? null : _savePaper,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paper info header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_paper.schoolName, style: AppTextStyles.subHeading.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    '${_paper.subject} — Class ${_paper.className}',
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoChip(Icons.grade, '${_paper.totalMarks} Marks'),
                      const SizedBox(width: 12),
                      if (_paper.timeDuration != null) _infoChip(Icons.timer, _paper.timeDuration!),
                      const SizedBox(width: 12),
                      if (_paper.examType != null) _infoChip(Icons.event, _paper.examType!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Questions by section
            for (final sec in sortedSections) ...[
              _buildSectionHeader(sec, sections[sec]!),
              const SizedBox(height: 8),
              ...sections[sec]!.map((q) => _buildQuestionCard(q)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String section, List<QuestionPaperQuestion> questions) {
    final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            'Section $section',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${questions.length} questions · $totalMarks marks',
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionPaperQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${q.questionNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(q.questionText, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${q.marks}m',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (q.questionType == 'MCQ' && q.optionA != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _optionRow('A', q.optionA!, q.correctAnswer == 'A' || q.correctAnswer == q.optionA),
                  _optionRow('B', q.optionB ?? '', q.correctAnswer == 'B' || q.correctAnswer == q.optionB),
                  _optionRow('C', q.optionC ?? '', q.correctAnswer == 'C' || q.correctAnswer == q.optionC),
                  _optionRow('D', q.optionD ?? '', q.correctAnswer == 'D' || q.correctAnswer == q.optionD),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(q.questionType, style: const TextStyle(fontSize: 10, color: AppColors.infoDark, fontWeight: FontWeight.w500)),
                ),
                if (q.correctAnswer != null && q.correctAnswer!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ans: ${q.correctAnswer}',
                      style: const TextStyle(fontSize: 10, color: AppColors.successDark, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(String letter, String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect ? AppColors.successLight : AppColors.surfaceBg,
              border: Border.all(color: isCorrect ? AppColors.success : AppColors.border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(letter, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isCorrect ? AppColors.successDark : AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    try {
      final pdfBytes = await QuestionPaperPdfService().generateQuestionPaperPdf(_paper);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _savePaper() async {
    setState(() => _isSaving = true);
    final created = await context.read<QuestionPaperProvider>().createPaper(_paper);
    setState(() => _isSaving = false);

    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper saved successfully!')),
      );
      Navigator.of(context)..pop()..pop(); // Go back to list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save paper')),
      );
    }
  }
}
