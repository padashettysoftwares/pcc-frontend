import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../utils/theme.dart';

class FeeHistoryScreen extends StatelessWidget {
  final Student student;
  const FeeHistoryScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Fees: ${student.name}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text('Transaction History', style: AppTextStyles.subHeading),
              const SizedBox(height: 6),
              Text('Coming soon', style: AppTextStyles.body),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Generate Receipt'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
