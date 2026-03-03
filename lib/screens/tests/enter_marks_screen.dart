import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/test.dart';
import '../../providers/test_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/theme.dart';

class EnterMarksScreen extends StatefulWidget {
  final Test test;
  const EnterMarksScreen({super.key, required this.test});

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final testProvider = Provider.of<TestProvider>(context, listen: false);
    final marks = await testProvider.getMarksForTest(widget.test.id!);
    for (var mark in marks) {
      _controllers[mark['student_id']] = TextEditingController(text: mark['marks_obtained'].toString());
    }
    setState(() => _isLoading = false);
  }

  void _saveMarks() {
    final List<Map<String, dynamic>> marksList = [];
    bool hasError = false;
    
    _controllers.forEach((studentId, controller) {
      final val = double.tryParse(controller.text);
      if (val != null) {
        if (val > 720) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marks cannot exceed 720'), backgroundColor: Colors.red),
          );
          hasError = true;
          return;
        }
        if (val > widget.test.totalMarks) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Marks cannot exceed ${widget.test.totalMarks}'), backgroundColor: Colors.red),
          );
          hasError = true;
          return;
        }
        marksList.add({'student_id': studentId, 'test_id': widget.test.id, 'marks_obtained': val});
      }
    });
    
    if (hasError) return;
    
    Provider.of<TestProvider>(context, listen: false).saveMarks(widget.test.id!, marksList);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final students = Provider.of<StudentProvider>(context, listen: false)
        .students
        .where((s) => s.className == widget.test.className)
        .toList();
    for (var s in students) {
      if (!_controllers.containsKey(s.studentId)) {
        _controllers[s.studentId] = TextEditingController();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Marks: ${widget.test.testName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(child: Text('No students in ${widget.test.className}', style: AppTextStyles.body))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                student.name[0].toUpperCase(),
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(student.name, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _controllers[student.studentId],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '/ ${widget.test.totalMarks}',
                                hintStyle: AppTextStyles.caption,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return null;
                                final marks = double.tryParse(val);
                                if (marks == null) return 'Invalid';
                                if (marks > 720) return 'Max 720';
                                if (marks > widget.test.totalMarks) return 'Too high';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveMarks,
              child: const Text('Save Marks'),
            ),
          ),
        ),
      ),
    );
  }
}
