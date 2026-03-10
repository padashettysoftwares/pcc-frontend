import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../models/student.dart';
import '../../providers/fee_provider.dart';
import '../../services/admission_pdf_service.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class FeeHistoryScreen extends StatefulWidget {
  final Student student;
  const FeeHistoryScreen({super.key, required this.student});

  @override
  State<FeeHistoryScreen> createState() => _FeeHistoryScreenState();
}

class _FeeHistoryScreenState extends State<FeeHistoryScreen> {
  final _api = ApiService();
  List<dynamic> _ledger = [];
  Map<String, dynamic>? _feeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getPaymentLedger(widget.student.studentId),
        _api.getStudentFees(widget.student.studentId),
      ]);
      if (!mounted) return;
      setState(() {
        _ledger = results[0] as List<dynamic>;
        _feeData = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading fee data: $e');
    }
  }

  double _safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _fmt(double n) {
    if (n >= 1000) {
      return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return n.toStringAsFixed(0);
  }

  Future<void> _generateReceipt() async {
    try {
      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/pcc.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {}

      final total = _safeDouble(_feeData?['total_fees']);
      final paid = _safeDouble(_feeData?['paid_amount']);
      final due = _safeDouble(_feeData?['due_amount']);

      final pdfBytes = await AdmissionPdfService().generateFeeReceipt(
        widget.student,
        totalFees: total,
        paidAmount: paid,
        dueAmount: due,
        logoBytes: logoBytes,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Fee_Receipt_${widget.student.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _generateAdmissionForm() async {
    try {
      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/pcc.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {}

      final total = _safeDouble(_feeData?['total_fees']);
      final paid = _safeDouble(_feeData?['paid_amount']);

      final pdfBytes = await AdmissionPdfService().generateAdmissionForm(
        widget.student,
        logoBytes: logoBytes,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Admission_${widget.student.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating form: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _safeDouble(_feeData?['total_fees']);
    final paid = _safeDouble(_feeData?['paid_amount']);
    final due = _safeDouble(_feeData?['due_amount']);
    final progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Fees: ${widget.student.name}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Fee Summary Card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF635BFF), Color(0xFF8B5FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Total Fees', '₹${_fmt(total)}'),
                          const SizedBox(height: 8),
                          _summaryRow('Paid', '₹${_fmt(paid)}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                          _summaryRow('Due Amount', '₹${_fmt(due)}', bold: true),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% Paid',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Action Buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            icon: Icons.receipt_long_rounded,
                            label: 'Fee Receipt',
                            color: const Color(0xFF10B981),
                            onTap: _generateReceipt,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.description_outlined,
                            label: 'Admission Form',
                            color: const Color(0xFF6C5CE7),
                            onTap: _generateAdmissionForm,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Transaction History ──
                    Text('Transaction History', style: AppTextStyles.subHeading),
                    const SizedBox(height: 12),

                    if (_ledger.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 12),
                            Text('No transactions yet', style: AppTextStyles.body),
                          ],
                        ),
                      )
                    else
                      ..._ledger.map((entry) => _transactionTile(entry)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: bold ? 1.0 : 0.85),
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: bold ? 22 : 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionTile(dynamic entry) {
    final amount = _safeDouble(entry['amount']);
    final date = (entry['payment_date'] ?? entry['created_at'] ?? '').toString().split('T')[0];
    final reason = entry['reason']?.toString() ?? '';
    final type = entry['entry_type']?.toString() ?? 'payment';

    Color tileColor;
    IconData tileIcon;
    String typeLabel;

    switch (type.toLowerCase()) {
      case 'payment':
        tileColor = const Color(0xFF10B981);
        tileIcon = Icons.arrow_downward_rounded;
        typeLabel = 'Payment';
        break;
      case 'adjustment':
        tileColor = const Color(0xFFF59E0B);
        tileIcon = Icons.tune_rounded;
        typeLabel = 'Adjustment';
        break;
      case 'total_update':
        tileColor = const Color(0xFF6C5CE7);
        tileIcon = Icons.edit_rounded;
        typeLabel = 'Fee Update';
        break;
      default:
        tileColor = AppColors.textSecondary;
        tileIcon = Icons.receipt_rounded;
        typeLabel = type;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: tileColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tileIcon, color: tileColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${_fmt(amount.abs())}',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(reason, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 2),
                Text(date, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tileColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tileColor),
            ),
          ),
        ],
      ),
    );
  }
}
