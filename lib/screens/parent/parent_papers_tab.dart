import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/question_paper.dart';
import '../../services/api_service.dart';
import '../../services/question_paper_pdf_service.dart';
import '../../utils/theme.dart';

class ParentPapersTab extends StatefulWidget {
  final String studentId;
  final String className;

  const ParentPapersTab({super.key, required this.studentId, required this.className});

  @override
  State<ParentPapersTab> createState() => _ParentPapersTabState();
}

class _ParentPapersTabState extends State<ParentPapersTab> {
  final _api = ApiService();
  List<QuestionPaper> _papers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getPublishedQuestionPapers(className: widget.className);
      _papers = data.map((d) => QuestionPaper.fromMap(d)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Question Papers', style: AppTextStyles.subHeading),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.body))
              : _papers.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadPapers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _papers.length,
                        itemBuilder: (ctx, i) => _buildCard(_papers[i]),
                      ),
                    ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No papers available', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildCard(QuestionPaper paper) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${paper.subject} — Class ${paper.className}',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                      ),
                      if (paper.chapter != null && paper.chapter!.isNotEmpty)
                        Text(paper.chapter!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.grade_outlined, '${paper.totalMarks} marks'),
                const SizedBox(width: 10),
                if (paper.timeDuration != null) _chip(Icons.timer_outlined, paper.timeDuration!),
                const SizedBox(width: 10),
                if (paper.examType != null) _chip(Icons.event_note_outlined, paper.examType!),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPdf(paper, includeAnswerKey: false),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('View Paper'),
                  ),
                ),
                if (paper.includeAnswerKey) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewPdf(paper, includeAnswerKey: true),
                      icon: const Icon(Icons.key, size: 16, color: Colors.white),
                      label: const Text('Answer Key'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }

  Future<void> _viewPdf(QuestionPaper paper, {required bool includeAnswerKey}) async {
    try {
      final data = await _api.getQuestionPaper(paper.id!);
      final fullPaper = QuestionPaper.fromMap(data);
      // Rebuild with answer key flag
      final displayPaper = QuestionPaper(
        id: fullPaper.id,
        schoolName: fullPaper.schoolName,
        subject: fullPaper.subject,
        className: fullPaper.className,
        chapter: fullPaper.chapter,
        totalMarks: fullPaper.totalMarks,
        timeDuration: fullPaper.timeDuration,
        examDate: fullPaper.examDate,
        examType: fullPaper.examType,
        board: fullPaper.board,
        instructions: fullPaper.instructions,
        includeAnswerKey: includeAnswerKey,
        questions: fullPaper.questions,
      );
      final pdfBytes = await QuestionPaperPdfService().generateQuestionPaperPdf(displayPaper);
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
