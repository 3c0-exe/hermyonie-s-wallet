import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../services/csv_service.dart';
import '../services/reminder_service.dart';

class BackupReminderDialog extends StatelessWidget {
  const BackupReminderDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final should = await ReminderService.shouldShowReminder();
    if (!should || !context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BackupReminderDialog(),
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
              child: const Icon(LucideIcons.download,
                  color: PesowiseColors.strong, size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'Backup Reminder 🌸',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PesowiseColors.strong),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hey Hermyonie! It\'s that time again.\nPlease download a copy of your expenses so your data stays safe. 💾',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: PesowiseColors.muted,
                  fontWeight: FontWeight.w500,
                  height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  CsvService.exportAll();
                  await ReminderService.dismiss();
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PesowiseColors.strong,
                  foregroundColor: PesowiseColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Download Now 💾',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await ReminderService.dismiss();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Maybe later',
                  style: TextStyle(
                      color: PesowiseColors.muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}