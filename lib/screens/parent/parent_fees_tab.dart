import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/student.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class ParentFeesTab extends StatefulWidget {
  final Student student;
  final Map<String, dynamic>? fee;
  final VoidCallback onPaymentComplete;

  const ParentFeesTab({
    super.key,
    required this.student,
    this.fee,
    required this.onPaymentComplete,
  });

  @override
  State<ParentFeesTab> createState() => _ParentFeesTabState();
}

class _ParentFeesTabState extends State<ParentFeesTab> {
  final _apiService = ApiService();
  List<dynamic> _paymentHistory = [];
  Map<String, dynamic>? _latestFee;

  Map<String, dynamic>? get _fee => _latestFee ?? widget.fee;
  double get totalFees => double.tryParse(_fee?['total_fees']?.toString() ?? '0') ?? 0;
  double get paidAmount => double.tryParse(_fee?['paid_amount']?.toString() ?? '0') ?? 0;
  double get dueAmount => double.tryParse(_fee?['due_amount']?.toString() ?? '0') ?? 0;

  @override
  void initState() {
    super.initState();
    _refreshFeeData();
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final history = await _apiService.getPaymentHistory(widget.student.studentId);
      if (mounted) setState(() => _paymentHistory = history);
    } catch (_) {}
  }

  Future<void> _refreshFeeData() async {
    try {
      final feeData = await _apiService.getStudentFees(widget.student.studentId);
      if (mounted) {
        setState(() => _latestFee = feeData);
      }
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _refreshFeeData();
    await _loadPaymentHistory();
    widget.onPaymentComplete();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).pcc;
    final progress = totalFees > 0 ? (paidAmount / totalFees).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: c.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF6C5CE7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fees',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ══════════ Payment Summary Card ══════════
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Section',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment Summary',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: GoogleFonts.inter(fontSize: 14, color: c.textSecondary)),
                          Text('₹${_fmt(totalFees)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation(
                            progress >= 0.8 ? const Color(0xFF10B981) : const Color(0xFF6C5CE7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paid ₹${_fmt(paidAmount)}',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Due ₹${_fmt(dueAmount)}',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ══════════ Fee Status Note ══════════
                if (dueAmount > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please pay your pending fees at the coaching center.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // ══════════ Payment History ══════════
                Text(
                  'Payment History',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _paymentHistory.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.receipt_long_rounded, size: 28, color: c.textTertiary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No payments yet',
                              style: GoogleFonts.inter(fontSize: 14, color: c.textTertiary),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: _paymentHistory.map((p) => _paymentTile(p)).toList(),
                      ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _paymentTile(dynamic payment) {
    final c = Theme.of(context).pcc;
    final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
    final date = payment['payment_date']?.toString().split('T')[0] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${_fmt(amount)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(date, style: GoogleFonts.inter(fontSize: 12, color: c.textTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Success',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double num) {
    if (num >= 1000) {
      return num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return num.toStringAsFixed(0);
  }
}
