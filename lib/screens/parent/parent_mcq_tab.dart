import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mcq_test_provider.dart';
import '../../utils/theme.dart';
import 'mcq_test_screen.dart';
import 'mcq_score_history_screen.dart';

class ParentMcqTab extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ParentMcqTab({super.key, required this.studentId, required this.studentName});

  @override
  State<ParentMcqTab> createState() => _ParentMcqTabState();
}

class _ParentMcqTabState extends State<ParentMcqTab> {
  String _selectedClass = '10';
  final String _selectedSubject = 'Science';
  String? _selectedChapter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<McqTestProvider>().loadChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Take a Test', style: AppTextStyles.subHeading),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Score History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => McqScoreHistoryScreen(
                studentId: widget.studentId,
                studentName: widget.studentName,
              )),
            ),
          ),
        ],
      ),
      body: Consumer<McqTestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final chapters = provider.getChaptersForClass(_selectedClass, _selectedSubject);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.quiz_rounded, color: Colors.white, size: 36),
                      const SizedBox(height: 12),
                      Text('MCQ Self-Test', style: AppTextStyles.subHeading.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Practice CBSE Science chapter-wise\nClass 8, 9 & 10',
                        style: AppTextStyles.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Class selector
                Text('Select Class', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: ['8', '9', '10'].map((c) {
                    final isSelected = _selectedClass == c;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedClass = c;
                            _selectedChapter = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? AppShadows.premium : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Class $c',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Chapter list
                Text('Choose Chapter', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 10),
                if (chapters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.warningDark, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chapters not available. Make sure the server is running.',
                            style: AppTextStyles.body.copyWith(color: AppColors.warningDark),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...chapters.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final chapter = entry.value;
                    final isSelected = _selectedChapter == chapter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChapter = chapter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.4),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surfaceBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                chapter,
                                style: AppTextStyles.body.copyWith(
                                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Start test button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _selectedChapter == null ? null : _startTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.surfaceBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    label: Text(
                      'Start Test (10 MCQs)',
                      style: AppTextStyles.buttonLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startTest() {
    if (_selectedChapter == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => McqTestScreen(
          studentId: widget.studentId,
          className: _selectedClass,
          subject: _selectedSubject,
          chapter: _selectedChapter!,
        ),
      ),
    );
  }
}
