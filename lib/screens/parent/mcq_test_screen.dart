import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mcq_test_provider.dart';
import '../../utils/theme.dart';

class McqTestScreen extends StatefulWidget {
  final String studentId;
  final String className;
  final String subject;
  final String chapter;

  const McqTestScreen({
    super.key,
    required this.studentId,
    required this.className,
    required this.subject,
    required this.chapter,
  });

  @override
  State<McqTestScreen> createState() => _McqTestScreenState();
}

class _McqTestScreenState extends State<McqTestScreen> {
  bool _showAllQuestions = false;
  int _currentIndex = 0;
  bool _submitted = false;
  bool _isSubmitting = false;
  final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<McqTestProvider>().generateQuestions(
        className: widget.className,
        subject: widget.subject,
        chapter: widget.chapter,
      );
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter, style: AppTextStyles.subHeading.copyWith(fontSize: 15)),
        actions: [
          if (!_submitted)
            TextButton.icon(
              icon: Icon(_showAllQuestions ? Icons.view_carousel : Icons.view_list, size: 18),
              label: Text(_showAllQuestions ? 'One by one' : 'All at once'),
              onPressed: () => setState(() => _showAllQuestions = !_showAllQuestions),
            ),
        ],
      ),
      body: Consumer<McqTestProvider>(
        builder: (context, provider, _) {
          if (provider.isGenerating) {
            return _buildLoading();
          }
          if (provider.questions.isEmpty) {
            return _buildError(provider.error);
          }
          if (_submitted) {
            return _buildResults(provider);
          }
          if (_showAllQuestions) {
            return _buildAllQuestions(provider);
          }
          return _buildOneByOne(provider);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('Generating questions...', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text('Using AI to create your test', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildError(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load questions', style: AppTextStyles.subHeading),
            const SizedBox(height: 8),
            Text(error ?? 'Please try again', style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<McqTestProvider>().generateQuestions(
                className: widget.className,
                subject: widget.subject,
                chapter: widget.chapter,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── One-by-one view ──
  Widget _buildOneByOne(McqTestProvider provider) {
    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentIndex + 1) / provider.questions.length,
          backgroundColor: AppColors.surfaceBg,
          color: AppColors.primary,
          minHeight: 4,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.questions.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) => _buildQuestionCard(provider, i),
          ),
        ),
        // Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: () {
                    _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  child: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              Text(
                '${_currentIndex + 1} / ${provider.questions.length}',
                style: AppTextStyles.bodyMedium,
              ),
              const Spacer(),
              if (_currentIndex < provider.questions.length - 1)
                ElevatedButton(
                  onPressed: () {
                    _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  child: const Text('Next'),
                )
              else
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(provider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('Submit'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(McqTestProvider provider, int index) {
    final q = provider.questions[index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${q.questionNumber}', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(q.questionText, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          ...['A', 'B', 'C', 'D'].map((opt) {
            final text = opt == 'A' ? q.optionA : opt == 'B' ? q.optionB : opt == 'C' ? q.optionC : q.optionD;
            final isSelected = q.selectedAnswer == opt;
            return GestureDetector(
              onTap: () => provider.selectAnswer(index, opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : AppColors.surfaceBg,
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(opt, style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text, style: AppTextStyles.body.copyWith(
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── All-at-once view ──
  Widget _buildAllQuestions(McqTestProvider provider) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.questions.length,
            itemBuilder: (ctx, i) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildQuestionCard(provider, i),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submit(provider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit Test', style: AppTextStyles.buttonLarge),
            ),
          ),
        ),
      ],
    );
  }

  // ── Results view ──
  Widget _buildResults(McqTestProvider provider) {
    final scoreVal = provider.score;
    final total = provider.questions.length;
    final pct = (scoreVal / total * 100).toStringAsFixed(0);
    final isGood = scoreVal >= (total * 0.6);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isGood ? AppColors.successGradient : AppColors.errorGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text('$scoreVal / $total', style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 48)),
                Text('$pct% Score', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  isGood ? 'Great job! 🎉' : 'Keep practicing! 💪',
                  style: AppTextStyles.subHeading.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _submitted = false;
                      _currentIndex = 0;
                    });
                    context.read<McqTestProvider>().generateQuestions(
                      className: widget.className,
                      subject: widget.subject,
                      chapter: widget.chapter,
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Try Again'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Answers review
          Text('Answer Review', style: AppTextStyles.subHeading),
          const SizedBox(height: 12),
          ...provider.questions.asMap().entries.map((entry) {
            final q = entry.value;
            final isCorrect = q.isCorrect;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.successLight.withValues(alpha: 0.3) : AppColors.errorLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Q${q.questionNumber}', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(q.questionText, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (q.selectedAnswer != null)
                    Text(
                      'Your answer: ${q.selectedAnswer}',
                      style: TextStyle(
                        color: isCorrect ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    'Correct answer: ${q.correctAnswer}',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _submit(McqTestProvider provider) async {
    setState(() => _isSubmitting = true);
    final saved = await provider.submitTest(
      studentId: widget.studentId,
      className: widget.className,
      subject: widget.subject,
      chapter: widget.chapter,
    );
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? '✓ Score saved successfully'
                : '⚠ Score could not be saved (server offline) — results still shown below',
          ),
          backgroundColor: saved ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
