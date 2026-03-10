import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class ConsentScreen extends StatefulWidget {
  final String studentId;
  final VoidCallback onConsentAccepted;

  const ConsentScreen({
    super.key,
    required this.studentId,
    required this.onConsentAccepted,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  Future<void> _submitConsent() async {
    if (!_accepted) return;
    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      await api.acceptConsent();
      if (!mounted) return;
      // Reset loading before navigating away, to avoid setState-after-dispose
      setState(() => _isLoading = false);
      widget.onConsentAccepted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF635BFF), Color(0xFF8B5FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Protection Consent',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'As per DPDP Act 2023, India',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // T&C Content
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Terms & Conditions', style: AppTextStyles.subHeading),
                          const SizedBox(height: 16),
                          _buildTermItem(
                            '1. Data Collection',
                            'We collect and process your child\'s name, class, admission date, attendance records, fee payment records, and test marks solely for educational management purposes.',
                          ),
                          _buildTermItem(
                            '2. Purpose of Data',
                            'All collected data is used exclusively for managing your child\'s academic records, tracking attendance, managing fee payments, sending notifications, and generating progress reports.',
                          ),
                          _buildTermItem(
                            '3. Data Storage & Security',
                            'Your data is stored securely in encrypted databases hosted in India. All communications are encrypted using industry-standard TLS/SSL. We use JWT-based authentication and role-based access control.',
                          ),
                          _buildTermItem(
                            '4. Data Sharing',
                            'We do NOT share your personal data with any third parties. Your data is only accessible by authorized institute staff members.',
                          ),
                          _buildTermItem(
                            '5. Your Rights (DPDP Act 2023)',
                            'You have the right to: (a) Access your data, (b) Request correction of inaccurate data, (c) Request deletion of your data, (d) Withdraw consent at any time by contacting the institute.',
                          ),
                          _buildTermItem(
                            '6. Data Retention',
                            'Your data will be retained for the duration of your child\'s enrollment and for a period of 3 years after completion, as required for academic record keeping.',
                          ),
                          _buildTermItem(
                            '7. Contact',
                            'For any data-related queries or to exercise your rights, please contact the institute administration directly.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Consent Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _accepted,
                          onChanged: (v) => setState(() => _accepted = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _accepted = !_accepted),
                          child: Text(
                            'I have read and agree to the above Terms & Conditions and consent to the processing of my child\'s data.',
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_accepted && !_isLoading) ? _submitConsent : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text('Accept & Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.body.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
