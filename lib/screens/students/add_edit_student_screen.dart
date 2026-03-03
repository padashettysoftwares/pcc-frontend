import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../services/admission_pdf_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/theme.dart';
import 'dart:math';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _admissionDateController;

  String? _selectedClass;
  final List<String> _classes = List.generate(12, (index) => 'Class ${index + 1}');

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  String? _studentId;
  String? _parentUsername;
  String? _parentPassword;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.student != null;
    _studentId = widget.student?.studentId;
    _parentUsername = widget.student?.parentUsername;
    _parentPassword = widget.student?.parentPassword;
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _selectedClass = widget.student?.className ?? _classes[0];
    _parentNameController = TextEditingController(text: widget.student?.parentName ?? '');
    _parentPhoneController = TextEditingController(text: widget.student?.parentPhone ?? '');
    _admissionDateController = TextEditingController(
      text: widget.student?.admissionDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    if (widget.student?.photoPath != null) _imageFile = File(widget.student!.photoPath!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _admissionDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _admissionDateController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  String _generateUsername(String name) {
    // Create a clean username from the student's name (lowercase, no spaces)
    final base = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    // Add a short random suffix to ensure uniqueness
    final suffix = Random().nextInt(100).toString().padLeft(2, '0');
    return '${base}_$suffix';
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      final id = _isEditing ? _studentId! : 'PCC-${DateTime.now().millisecondsSinceEpoch}';
      if (!_isEditing) {
        _parentUsername = _generateUsername(_nameController.text);
        _parentPassword = _parentPhoneController.text.trim();
      }

      final student = Student(
        id: widget.student?.id,
        studentId: id,
        name: _nameController.text.trim(),
        className: _selectedClass!,
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        admissionDate: _admissionDateController.text.trim(),
        photoPath: _imageFile?.path,
        parentUsername: _parentUsername,
        parentPassword: _parentPassword,
      );

      final provider = Provider.of<StudentProvider>(context, listen: false);
      if (_isEditing) {
        provider.updateStudent(student);
      } else {
        provider.addStudent(student);
        _showCredentialsDialog(student);
        return;
      }
      Navigator.pop(context);
    }
  }

  Future<void> _downloadAdmissionForm(Student student) async {
    try {
      // Load logo
      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/pcc.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {}

      // Load student photo
      Uint8List? photoBytes;
      if (student.photoPath != null) {
        try {
          final file = File(student.photoPath!);
          if (await file.exists()) {
            photoBytes = await file.readAsBytes();
          }
        } catch (_) {}
      }

      final pdfBytes = await AdmissionPdfService().generateAdmissionForm(
        student,
        photoBytes: photoBytes,
        logoBytes: logoBytes,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Admission_Form_${student.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  void _showCredentialsDialog(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Student Added Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _credRow('Student ID', student.studentId),
            const SizedBox(height: 16),
            Text('Parent Credentials', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _credRow('Username', student.parentUsername ?? ''),
            _credRow('Password', student.parentPassword ?? ''),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download the admission form to share with the parent.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Download Admission Form'),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAdmissionForm(student).then((_) {
                if (mounted) Navigator.pop(context);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          SelectableText(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Student' : 'Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.surfaceBg,
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.textTertiary)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text('Upload photo', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Form fields in card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Information', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Student Name',
                      prefixIcon: Icons.person_outline,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        prefixIcon: const Icon(Icons.school_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _classes.map((className) {
                        return DropdownMenuItem<String>(
                          value: className,
                          child: Text(className),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClass = value);
                      },
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _admissionDateController,
                      label: 'Admission Date',
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parent Information', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _parentNameController,
                      label: 'Parent Name',
                      prefixIcon: Icons.person_outline,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _parentPhoneController,
                      label: 'Parent Phone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length != 10) return 'Phone number must be exactly 10 digits';
                        if (!RegExp(r'^[0-9]+$').hasMatch(val)) return 'Only digits allowed';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveStudent,
                  child: Text(_isEditing ? 'Update Student' : 'Add Student'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
