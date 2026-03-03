import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../models/fee.dart';
import '../../services/admission_pdf_service.dart';
import 'fee_history_screen.dart';
import '../../utils/theme.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<StudentProvider>(context, listen: false).fetchStudents();
        Provider.of<FeeProvider>(context, listen: false).fetchFees();
      }
    });
  }

  Future<void> _generateFeeReceipt(String studentId, double total, double paid, double due) async {
    try {
      final studentProv = Provider.of<StudentProvider>(context, listen: false);
      final student = studentProv.students.firstWhere(
        (s) => s.studentId == studentId,
      );

      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/pcc.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {}

      final pdfBytes = await AdmissionPdfService().generateFeeReceipt(
        student,
        totalFees: total,
        paidAmount: paid,
        dueAmount: due,
        logoBytes: logoBytes,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Fee_Receipt_${student.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: $e')),
        );
      }
    }
  }

  void _showUpdateFeeDialog(BuildContext context, String studentId, String studentName) {
    final feeProvider = Provider.of<FeeProvider>(context, listen: false);
    final existingFee = feeProvider.getFee(studentId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FeeActionSheet(
        studentId: studentId,
        studentName: studentName,
        currentTotal: existingFee?.totalFees ?? 0,
        currentPaid: existingFee?.paidAmount ?? 0,
        currentDue: existingFee?.dueAmount ?? 0,
        feeProvider: feeProvider,
        onReceiptRequest: (total, paid, due) => _generateFeeReceipt(studentId, total, paid, due),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Fees'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<StudentProvider, FeeProvider>(
        builder: (context, studentProv, feeProv, _) {
          if (studentProv.isLoading || feeProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (studentProv.students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 14),
                  Text('No students found', style: AppTextStyles.body),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: studentProv.students.length,
            padding: const EdgeInsets.all(20),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = studentProv.students[index];
              final fee = feeProv.getFee(student.studentId);
              final total = fee?.totalFees ?? 0.0;
              final paid = fee?.paidAmount ?? 0.0;
              final due = fee?.dueAmount ?? 0.0;

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
                    onTap: () => _showUpdateFeeDialog(context, student.studentId, student.name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: due > 0 ? AppColors.errorLight : AppColors.successLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              due > 0 ? Icons.receipt_long_outlined : Icons.check_circle_outline,
                              size: 18,
                              color: due > 0 ? AppColors.error : AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  '${student.className}  ·  Paid ₹${paid.toStringAsFixed(0)} / ₹${total.toStringAsFixed(0)}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${due.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: due > 0 ? AppColors.error : AppColors.success,
                                ),
                              ),
                              Text(due > 0 ? 'due' : 'clear', style: AppTextStyles.caption),
                            ],
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.history, size: 18, color: AppColors.textTertiary),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FeeHistoryScreen(student: student)));
                            },
                            tooltip: 'View History',
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Fee Action Bottom Sheet — Immutable Ledger UI
// ══════════════════════════════════════════════════════════════════
class _FeeActionSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  final double currentTotal;
  final double currentPaid;
  final double currentDue;
  final FeeProvider feeProvider;
  final void Function(double total, double paid, double due) onReceiptRequest;

  const _FeeActionSheet({
    required this.studentId,
    required this.studentName,
    required this.currentTotal,
    required this.currentPaid,
    required this.currentDue,
    required this.feeProvider,
    required this.onReceiptRequest,
  });

  @override
  State<_FeeActionSheet> createState() => _FeeActionSheetState();
}

class _FeeActionSheetState extends State<_FeeActionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _totalCtrl = TextEditingController();
  final _payCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _totalCtrl.text = widget.currentTotal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _totalCtrl.dispose();
    _payCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTotalUpdate() async {
    final total = double.tryParse(_totalCtrl.text);
    final reason = _reasonCtrl.text.trim();
    if (total == null || total < 0) return setState(() => _error = 'Enter a valid amount');
    if (reason.length < 5) return setState(() => _error = 'Reason must be at least 5 characters');

    setState(() { _loading = true; _error = null; });
    try {
      await widget.feeProvider.updateTotalFees(widget.studentId, total, reason);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_payCtrl.text);
    final reason = _reasonCtrl.text.trim();
    if (amount == null || amount <= 0) return setState(() => _error = 'Enter a valid amount');
    if (reason.length < 3) return setState(() => _error = 'Reason is required (min 3 chars)');

    setState(() { _loading = true; _error = null; });
    try {
      await widget.feeProvider.addPayment(widget.studentId, amount, reason);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('₹${amount.toStringAsFixed(0)} payment recorded'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fees: ${widget.studentName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('Total', '₹${widget.currentTotal.toStringAsFixed(0)}', const Color(0xFF6C5CE7)),
                const SizedBox(width: 8),
                _chip('Paid', '₹${widget.currentPaid.toStringAsFixed(0)}', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _chip('Due', '₹${widget.currentDue.toStringAsFixed(0)}', const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl,
            onTap: (_) => setState(() { _error = null; _reasonCtrl.clear(); }),
            labelColor: const Color(0xFF6C5CE7),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6C5CE7),
            tabs: const [Tab(text: 'Update Total'), Tab(text: 'Record Payment')],
          ),
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildTab(
                  controller: _totalCtrl,
                  label: 'Total Fees (₹)',
                  reasonHint: 'e.g. Updated after discount',
                  buttonLabel: 'Update Total Fee',
                  buttonColor: const Color(0xFF6C5CE7),
                  onSubmit: _submitTotalUpdate,
                ),
                _buildTab(
                  controller: _payCtrl,
                  label: 'Payment Amount (₹)',
                  reasonHint: 'e.g. Cash received for March',
                  helperText: 'Max: ₹${widget.currentDue.toStringAsFixed(0)}',
                  buttonLabel: 'Record Payment',
                  buttonColor: const Color(0xFF10B981),
                  onSubmit: _submitPayment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required TextEditingController controller,
    required String label,
    required String reasonHint,
    String? helperText,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.currency_rupee), helperText: helperText)),
          const SizedBox(height: 12),
          TextField(controller: _reasonCtrl, decoration: InputDecoration(labelText: 'Reason *', hintText: reasonHint, prefixIcon: const Icon(Icons.note)), maxLines: 2),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: Colors.white),
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
