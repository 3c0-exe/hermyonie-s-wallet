// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../core/hive_boxes.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/jam_session.dart';
import '../models/jam_person.dart';
import '../models/jam_expense.dart';
import '../services/wallet_service.dart';
import '../services/transaction_service.dart';
import '../services/debt_service.dart';
import '../services/jam_service.dart';

class CsvService {
  // ── Export ──────────────────────────────────────────────
  static void exportAll() {
    final now = DateTime.now();
    final label = DateFormat('yyyy-MM-dd').format(now);

    final data = {
      'exported_at': now.toIso8601String(),
      'version': 1,
      'wallets': WalletService.getAll().map((w) => {
        'id': w.id,
        'name': w.name,
        'icon': w.icon,
        'balance': w.balance,
        'createdAt': w.createdAt.toIso8601String(),
      }).toList(),
      'transactions': TransactionService.getAll().map((t) => {
        'id': t.id,
        'walletId': t.walletId,
        'label': t.label,
        'amount': t.amount,
        'isExpense': t.isExpense,
        'category': t.category,
        'date': t.date.toIso8601String(),
        'note': t.note,
      }).toList(),
      'debts': DebtService.getAll().map((d) => {
        'id': d.id,
        'label': d.label,
        'amount': d.amount,
        'creditor': d.creditor,
        'walletId': d.walletId,
        'dueDate': d.dueDate?.toIso8601String(),
        'isRecurring': d.isRecurring,
        'note': d.note,
        'createdAt': d.createdAt.toIso8601String(),
      }).toList(),
      'jamSessions': JamService.getAllSessions().map((s) => {
        'id': s.id,
        'name': s.name,
        'createdAt': s.createdAt.toIso8601String(),
        'isSettled': s.isSettled,
      }).toList(),
      'jamPersons': Hive.box<JamPerson>(HiveBoxes.jamPersons).values.map((p) => {
        'id': p.id,
        'sessionId': p.sessionId,
        'name': p.name,
        'isOwner': p.isOwner,
      }).toList(),
      'jamExpenses': Hive.box<JamExpense>(HiveBoxes.jamExpenses).values.map((e) => {
        'id': e.id,
        'personId': e.personId,
        'sessionId': e.sessionId,
        'description': e.description,
        'amount': e.amount,
      }).toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(json);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'pesowise_backup_$label.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ── Import ──────────────────────────────────────────────
  static Future<void> importAll(BuildContext context) async {
    final upload = html.FileUploadInputElement()
      ..accept = '.json'
      ..click();

    await upload.onChange.first;
    final file = upload.files?.first;
    if (file == null) return;

    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;

    final raw = reader.result as String;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      if (context.mounted) {
        _showSnack(context, 'Invalid backup file. 😔');
      }
      return;
    }

    // Confirm before wiping
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore backup?',
            style: TextStyle(
                color: Color(0xFFD4537E), fontWeight: FontWeight.w700)),
        content: const Text(
            'This will replace ALL current data with the backup. This cannot be undone.',
            style: TextStyle(color: Color(0xFFE0AAC0))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFE0AAC0)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore',
                  style: TextStyle(
                      color: Color(0xFFD4537E),
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ── Wipe all boxes ──
      await Hive.box<Wallet>(HiveBoxes.wallets).clear();
      await Hive.box<Transaction>(HiveBoxes.transactions).clear();
      await Hive.box<Debt>(HiveBoxes.debts).clear();
      await Hive.box<JamSession>(HiveBoxes.jamSessions).clear();
      await Hive.box<JamPerson>(HiveBoxes.jamPersons).clear();
      await Hive.box<JamExpense>(HiveBoxes.jamExpenses).clear();

      // ── Restore wallets ──
      final walletBox = Hive.box<Wallet>(HiveBoxes.wallets);
      for (final w in (data['wallets'] as List)) {
        final wallet = Wallet()
          ..id = w['id']
          ..name = w['name']
          ..icon = w['icon']
          ..balance = (w['balance'] as num).toDouble()
          ..createdAt = DateTime.parse(w['createdAt']);
        await walletBox.put(wallet.id, wallet);
      }

      // ── Restore transactions ──
      final txBox = Hive.box<Transaction>(HiveBoxes.transactions);
      for (final t in (data['transactions'] as List)) {
        final tx = Transaction()
          ..id = t['id']
          ..walletId = t['walletId']
          ..label = t['label']
          ..amount = (t['amount'] as num).toDouble()
          ..isExpense = t['isExpense']
          ..category = t['category']
          ..date = DateTime.parse(t['date'])
          ..note = t['note'];
        await txBox.put(tx.id, tx);
      }

      // ── Restore debts ──
      final debtBox = Hive.box<Debt>(HiveBoxes.debts);
      for (final d in (data['debts'] as List)) {
        final debt = Debt()
          ..id = d['id']
          ..label = d['label']
          ..amount = (d['amount'] as num).toDouble()
          ..creditor = d['creditor']
          ..walletId = d['walletId']
          ..dueDate = d['dueDate'] != null ? DateTime.parse(d['dueDate']) : null
          ..isRecurring = d['isRecurring']
          ..note = d['note']
          ..createdAt = DateTime.parse(d['createdAt']);
        await debtBox.put(debt.id, debt);
      }

      // ── Restore jam sessions ──
      final sessionBox = Hive.box<JamSession>(HiveBoxes.jamSessions);
      for (final s in (data['jamSessions'] as List)) {
        final session = JamSession()
          ..id = s['id']
          ..name = s['name']
          ..createdAt = DateTime.parse(s['createdAt'])
          ..isSettled = s['isSettled'];
        await sessionBox.put(session.id, session);
      }

      // ── Restore jam persons ──
      final personBox = Hive.box<JamPerson>(HiveBoxes.jamPersons);
      for (final p in (data['jamPersons'] as List)) {
        final person = JamPerson()
          ..id = p['id']
          ..sessionId = p['sessionId']
          ..name = p['name']
          ..isOwner = p['isOwner'];
        await personBox.put(person.id, person);
      }

      // ── Restore jam expenses ──
      final expenseBox = Hive.box<JamExpense>(HiveBoxes.jamExpenses);
      for (final e in (data['jamExpenses'] as List)) {
        final expense = JamExpense()
          ..id = e['id']
          ..personId = e['personId']
          ..sessionId = e['sessionId']
          ..description = e['description']
          ..amount = (e['amount'] as num).toDouble();
        await expenseBox.put(expense.id, expense);
      }

      if (context.mounted) {
        _showSnack(context, 'Backup restored successfully 🌸');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Restore failed. File might be corrupted. 😔');
      }
    }
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD4537E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}