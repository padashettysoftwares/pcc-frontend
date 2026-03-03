import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question_paper.dart';
import '../../providers/question_paper_provider.dart';
import '../../utils/theme.dart';
import 'paper_preview_screen.dart';

class ManualPaperBuilderScreen extends StatefulWidget {
  const ManualPaperBuilderScreen({super.key});

  @override
  State<ManualPaperBuilderScreen> createState() => _ManualPaperBuilderScreenState();
}

class _ManualPaperBuilderScreenState extends State<ManualPaperBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameCtrl = TextEditingController(text: 'Padashetty Coaching Class');
  final _subjectCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();
  final _totalMarksCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  String _examType = 'Unit Test';
  String _board = 'CBSE';
  DateTime _examDate = DateTime.now();

  final List<_QuestionEntry> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionEntry(
        number: _questions.length + 1,
        section: 'A',
        type: 'MCQ',
        marks: 1,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      for (int i = 0; i < _questions.length; i++) {
        _questions[i].number = i + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Question Paper', style: AppTextStyles.subHeading),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Paper Details ──
              _sectionTitle('Paper Details'),
              const SizedBox(height: 12),
              _buildTextField(_schoolNameCtrl, 'School Name'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_subjectCtrl, 'Subject', required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_classCtrl, 'Class', required: true)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_chapterCtrl, 'Chapter / Unit'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_totalMarksCtrl, 'Total Marks', required: true, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_durationCtrl, 'Duration (e.g., 3 hours)')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDropdown('Exam Type', _examType, ['Unit Test', 'Mid-Term', 'Final', 'Practice'], (v) => setState(() => _examType = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown('Board', _board, ['CBSE', 'ICSE', 'State Board'], (v) => setState(() => _board = v!))),
                ],
              ),
              const SizedBox(height: 12),
              // Date picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _examDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _examDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Text(
                        'Exam Date: ${_examDate.day}/${_examDate.month}/${_examDate.year}',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(_instructionsCtrl, 'Instructions (optional)', maxLines: 3),
              const SizedBox(height: 24),

              // ── Questions ──
              _sectionTitle('Questions'),
              const SizedBox(height: 12),
              ..._questions.asMap().entries.map((entry) => _buildQuestionCard(entry.key, entry.value)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
              const SizedBox(height: 24),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePaper,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save & Preview'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTextStyles.subHeading.copyWith(color: AppColors.primary));
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      {bool required = false, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildQuestionCard(int index, _QuestionEntry q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q${q.number}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _removeQuestion(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: q.section,
                  decoration: const InputDecoration(labelText: 'Section', isDense: true),
                  items: ['A', 'B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => q.section = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: q.type,
                  decoration: const InputDecoration(labelText: 'Type', isDense: true),
                  items: ['MCQ', 'Short Answer', 'Long Answer', 'Fill in the Blank']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => q.type = v!),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextFormField(
                  initialValue: q.marks.toString(),
                  decoration: const InputDecoration(labelText: 'Marks', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => q.marks = int.tryParse(v) ?? 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Question Text', alignLabelWithHint: true),
            onChanged: (v) => q.text = v,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          if (q.type == 'MCQ') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Option A', isDense: true), onChanged: (v) => q.optionA = v)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Option B', isDense: true), onChanged: (v) => q.optionB = v)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Option C', isDense: true), onChanged: (v) => q.optionC = v)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Option D', isDense: true), onChanged: (v) => q.optionD = v)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Correct Answer'),
            onChanged: (v) => q.correctAnswer = v,
          ),
        ],
      ),
    );
  }

  Future<void> _savePaper() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final questions = _questions.map((q) => QuestionPaperQuestion(
      section: q.section,
      questionNumber: q.number,
      questionText: q.text,
      questionType: q.type,
      marks: q.marks,
      optionA: q.optionA,
      optionB: q.optionB,
      optionC: q.optionC,
      optionD: q.optionD,
      correctAnswer: q.correctAnswer,
    )).toList();

    final paper = QuestionPaper(
      schoolName: _schoolNameCtrl.text,
      subject: _subjectCtrl.text,
      className: _classCtrl.text,
      chapter: _chapterCtrl.text,
      totalMarks: int.tryParse(_totalMarksCtrl.text) ?? 0,
      timeDuration: _durationCtrl.text,
      examDate: '${_examDate.year}-${_examDate.month.toString().padLeft(2, '0')}-${_examDate.day.toString().padLeft(2, '0')}',
      examType: _examType,
      board: _board,
      instructions: _instructionsCtrl.text,
      questions: questions,
    );

    final created = await context.read<QuestionPaperProvider>().createPaper(paper);
    setState(() => _isSaving = false);

    if (created != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PaperPreviewScreen(paper: created)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save paper')),
      );
    }
  }

  @override
  void dispose() {
    _schoolNameCtrl.dispose();
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    _chapterCtrl.dispose();
    _totalMarksCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }
}

class _QuestionEntry {
  int number;
  String section;
  String type;
  int marks;
  String text = '';
  String? optionA, optionB, optionC, optionD;
  String? correctAnswer;

  _QuestionEntry({
    required this.number,
    required this.section,
    required this.type,
    required this.marks,
  });
}
