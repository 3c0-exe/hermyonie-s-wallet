import 'package:flutter/material.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../core/theme.dart';

class NudgeDialog extends StatelessWidget {
  final String message;
  final String category;

  const NudgeDialog({super.key, required this.message, required this.category});

  static Future<void> show(
    BuildContext context,
    String message,
    String category,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => NudgeDialog(message: message, category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PesowiseColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PesowiseColors.blushBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PesowiseColors.chipBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                WalletIcons.piggyBank,
                color: PesowiseColors.strong,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Spending Check ✨',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: PesowiseColors.strong,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: PesowiseColors.muted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PesowiseColors.strong,
                  foregroundColor: PesowiseColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it 🌸',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
