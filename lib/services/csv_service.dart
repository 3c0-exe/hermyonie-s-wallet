import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ledger_service.dart';
import 'store_codec.dart';

/// Legacy name retained for Drive compatibility. Backups are versioned JSON.
class CsvService {
  static String exportAllToJson() =>
      const JsonEncoder.withIndent('  ').convert(StoreCodec.snapshot());
  static Future<void> exportAll() async {
    await FilePicker.saveFile(
      dialogTitle: 'Save wallet backup',
      fileName:
          'hermyonies-wallet-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(exportAllToJson())),
    );
  }

  static Future<void> restoreJson(String raw) async {
    if (utf8.encode(raw).length > 10000000) {
      throw const FormatException('Backup is too large (maximum 10 MB).');
    }
    final records = StoreCodec.decode(jsonDecode(raw) as Map<String, dynamic>);
    await LedgerService.mutate(() => StoreCodec.replace(records));
  }

  static Future<void> importAll(BuildContext context) async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || !context.mounted) return;
      final raw = await result.xFile.readAsString();
      final records = StoreCodec.decode(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (!context.mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore this backup?'),
          content: Text(
            '${records['wallets']!.length} accounts and ${records['transactions']!.length} transactions. This replaces the current data on this device. Export a backup first if you need to keep it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await restoreJson(raw);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup restored.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Could not restore this backup. Your data was kept.',
            ),
          ),
        );
      }
    }
  }
}
