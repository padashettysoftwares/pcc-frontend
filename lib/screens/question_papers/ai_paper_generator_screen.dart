import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question_paper.dart';
import '../../providers/question_paper_provider.dart';
import '../../utils/theme.dart';
import 'paper_preview_screen.dart';

class AiPaperGeneratorScreen extends StatefulWidget {
  const AiPaperGeneratorScreen({super.key});

  @override
  State<AiPaperGeneratorScreen> createState() => _AiPaperGeneratorScreenState();
}

class _AiPaperGeneratorScreenState extends State<AiPaperGeneratorScreen> {
  final _subjectCtrl = TextEditingController();
  final _textbookCtrl = TextEditingController(text: 'NCERT');
  final _chapterCtrl = TextEditingController();
  final _totalMarksCtrl = TextEditingController(text: '80');
  final _durationCtrl = TextEditingController(text: '3 hours');
  final _instructionsCtrl = TextEditingController();

  String _className = '10';
  String _difficulty = 'Mixed';
  String _board = 'CBSE';
  String _model = 'deepseek/deepseek-chat';

  int _mcqCount = 5;
  int _shortCount = 5;
  int _longCount = 3;
  int _fillCount = 2;

  bool _isGenerating = false;

  final _classes = ['6', '7', '8', '9', '10', '11', '12'];
  final _difficulties = ['Easy', 'Medium', 'Hard', 'Mixed'];
  final _boards = ['CBSE', 'ICSE', 'State Board'];
  final _models = [
    {'label': 'DeepSeek Chat', 'value': 'deepseek/deepseek-chat'},
    {'label': 'GPT-4o Mini', 'value': 'openai/gpt-4o-mini'},
    {'label': 'Claude 3.5 Sonnet', 'value': 'anthropic/claude-3.5-sonnet'},
    {'label': 'Gemini Pro', 'value': 'google/gemini-pro'},
    {'label': 'Llama 3.1 70B', 'value': 'meta-llama/llama-3.1-70b-instruct'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Question Paper', style: AppTextStyles.subHeading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI-Powered Generator', style: AppTextStyles.subHeading.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          'Generate professional question papers using AI models',
                          style: AppTextStyles.body.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subject + Class
            _sectionTitle('Subject & Class'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _className,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: _classes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _className = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _textbookCtrl,
              decoration: const InputDecoration(labelText: 'Textbook'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chapterCtrl,
              decoration: const InputDecoration(labelText: 'Chapter(s)', hintText: 'e.g., Chapter 1, 2, 3'),
            ),
            const SizedBox(height: 24),

            // Exam config
            _sectionTitle('Exam Configuration'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalMarksCtrl,
                    decoration: const InputDecoration(labelText: 'Total Marks'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: _difficulties.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _board,
                    decoration: const InputDecoration(labelText: 'Board'),
                    items: _boards.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _board = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question distribution
            _sectionTitle('Question Distribution'),
            const SizedBox(height: 12),
            _buildSlider('MCQ Questions', _mcqCount, 0, 20, (v) => setState(() => _mcqCount = v.round())),
            _buildSlider('Short Answer', _shortCount, 0, 15, (v) => setState(() => _shortCount = v.round())),
            _buildSlider('Long Answer', _longCount, 0, 10, (v) => setState(() => _longCount = v.round())),
            _buildSlider('Fill in the Blank', _fillCount, 0, 10, (v) => setState(() => _fillCount = v.round())),
            const SizedBox(height: 24),

            // AI Model
            _sectionTitle('AI Model'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _model,
              decoration: const InputDecoration(labelText: 'Choose Model'),
              items: _models.map((m) => DropdownMenuItem(
                value: m['value'],
                child: Text(m['label']!),
              )).toList(),
              onChanged: (v) => setState(() => _model = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Special Instructions (optional)',
                alignLabelWithHint: true,
                hintText: 'e.g., Include diagram-based questions...',
              ),
            ),
            const SizedBox(height: 32),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Questions',
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTextStyles.subHeading.copyWith(color: AppColors.primary));
  }

  Widget _buildSlider(String label, int value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.body),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              divisions: max.toInt(),
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('$value', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    if (_subjectCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final provider = context.read<QuestionPaperProvider>();
    final questions = await provider.aiGenerate({
      'subject': _subjectCtrl.text,
      'class_name': _className,
      'textbook': _textbookCtrl.text,
      'chapters': _chapterCtrl.text,
      'total_marks': int.tryParse(_totalMarksCtrl.text) ?? 80,
      'time_duration': _durationCtrl.text,
      'difficulty': _difficulty,
      'board': _board,
      'model': _model,
      'question_distribution': {
        'mcq': _mcqCount,
        'short': _shortCount,
        'long': _longCount,
        'fill': _fillCount,
      },
      'special_instructions': _instructionsCtrl.text,
    });

    setState(() => _isGenerating = false);

    if (questions != null && questions.isNotEmpty && mounted) {
      final paper = QuestionPaper(
        subject: _subjectCtrl.text,
        className: _className,
        chapter: _chapterCtrl.text,
        totalMarks: int.tryParse(_totalMarksCtrl.text) ?? 80,
        timeDuration: _durationCtrl.text,
        examType: 'Unit Test',
        board: _board,
        difficulty: _difficulty,
        instructions: _instructionsCtrl.text,
        isAiGenerated: true,
        questions: questions,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaperPreviewScreen(paper: paper, isNewPaper: true)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to generate questions')),
      );
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _textbookCtrl.dispose();
    _chapterCtrl.dispose();
    _totalMarksCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }
}
