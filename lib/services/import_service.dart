import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/money.dart';
import 'ledger_service.dart';
import 'transaction_service.dart';

class ImportRow {
  final String label, category, externalId;
  final DateTime date;
  final double amount;
  final bool isExpense;
  const ImportRow({
    required this.label,
    required this.category,
    required this.externalId,
    required this.date,
    required this.amount,
    required this.isExpense,
  });
}

class ImportService {
  /// Canonical CSV: date,description,amount,type,category,reference.
  /// References should be stable statement IDs, not arbitrary row numbers.
  static List<ImportRow> parse(String raw, String walletId) {
    if (raw.length > 2000000) {
      throw const FormatException('CSV is too large (maximum 2 MB).');
    }
    final rows = _csv(raw.replaceFirst('\uFEFF', ''));
    if (rows.length < 2) {
      throw const FormatException('Add a header and at least one transaction.');
    }
    final headers = rows.first.map((v) => v.trim().toLowerCase()).toList();
    for (final name in ['date', 'description', 'amount', 'type']) {
      if (!headers.contains(name)) {
        throw FormatException(
          'Missing "$name" column. Use the template in Imports.',
        );
      }
    }
    final parsed = <ImportRow>[];
    final seen = <String>{};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((v) => v.trim().isEmpty)) continue;
      if (row.length != headers.length) {
        throw FormatException(
          'Row ${i + 1}: column count does not match the header.',
        );
      }
      String value(String key) =>
          headers.contains(key) ? row[headers.indexOf(key)].trim() : '';
      final date = DateTime.tryParse(value('date')),
          amount = Money.parse(value('amount')),
          type = value('type').toLowerCase(),
          label = value('description');
      if (date == null ||
          amount == null ||
          amount <= 0 ||
          !['expense', 'income'].contains(type) ||
          label.isEmpty) {
        throw FormatException(
          'Row ${i + 1}: use an ISO date, positive amount and expense/income type.',
        );
      }
      if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        throw FormatException(
          'Row ${i + 1}: future transactions belong in Plan.',
        );
      }
      final reference = value('reference');
      final fingerprint = base64Url.encode(
        utf8.encode(
          '$walletId|${reference.isNotEmpty ? 'reference:$reference' : '${date.toIso8601String()}|$label|${Money.cents(amount)}|$type'}',
        ),
      );
      if (!seen.add(fingerprint)) continue;
      parsed.add(
        ImportRow(
          label: label,
          date: date,
          amount: amount,
          isExpense: type == 'expense',
          category: value('category').isEmpty ? 'Other' : value('category'),
          externalId: fingerprint,
        ),
      );
      if (parsed.length > 2000) {
        throw const FormatException(
          'Import at most 2,000 transactions at a time.',
        );
      }
    }
    return parsed;
  }

  static bool alreadyImported(ImportRow row) => Hive.box<Transaction>(
    'transactions',
  ).values.any((t) => t.externalId == row.externalId);
  static Future<int> save(List<ImportRow> rows, String walletId) =>
      LedgerService.mutate(() async {
        final w = Hive.box<Wallet>('wallets').get(walletId);
        if (w == null || w.archived) {
          throw const FormatException('Select an active account.');
        }
        var count = 0;
        for (final row in rows) {
          if (alreadyImported(row)) continue;
          await TransactionService.writeEntry(
            walletId: walletId,
            label: row.label,
            amount: row.amount,
            isExpense: row.isExpense,
            category: row.category,
            date: row.date,
            externalId: row.externalId,
            note: 'Imported from statement CSV',
          );
          count++;
        }
        return count;
      });
  static List<List<String>> _csv(String raw) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c == '"') {
        if (quoted && i + 1 < raw.length && raw[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (c == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((c == '\n' || c == '\r') && !quoted) {
        if (c == '\r' && i + 1 < raw.length && raw[i + 1] == '\n') i++;
        row.add(field.toString());
        rows.add(row);
        row = [];
        field = StringBuffer();
      } else {
        field.write(c);
      }
    }
    if (quoted) throw const FormatException('CSV has an unclosed quote.');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
