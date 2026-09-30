import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/debt.dart';
import '../models/jam_session.dart';
import '../models/jam_person.dart';
import '../models/jam_expense.dart';
import '../utils/money.dart';

class StoreCodec {
  static const boxes = [
    'wallets',
    'transactions',
    'debts',
    'jamSessions',
    'jamPersons',
    'jamExpenses',
  ];
  static Box<dynamic> box(String name) => switch (name) {
    'wallets' => Hive.box<Wallet>(name),
    'transactions' => Hive.box<Transaction>(name),
    'debts' => Hive.box<Debt>(name),
    'jamSessions' => Hive.box<JamSession>(name),
    'jamPersons' => Hive.box<JamPerson>(name),
    'jamExpenses' => Hive.box<JamExpense>(name),
    _ => throw ArgumentError('Unknown box $name'),
  };
  static Map<String, dynamic> wallet(Wallet w) => {
    'id': w.id,
    'name': w.name,
    'icon': w.icon,
    'balance': w.balance,
    'createdAt': w.createdAt.toIso8601String(),
    'accountType': w.accountType,
    'creditLimit': w.creditLimit,
    'spendingCap': w.spendingCap,
    'dueDay': w.dueDay,
    'archived': w.archived,
  };
  static Map<String, dynamic> transaction(Transaction t) => {
    'id': t.id,
    'walletId': t.walletId,
    'label': t.label,
    'amount': t.amount,
    'isExpense': t.isExpense,
    'category': t.category,
    'date': t.date.toIso8601String(),
    'note': t.note,
    'entryType': t.entryType,
    'toWalletId': t.toWalletId,
    'debtId': t.debtId,
    'debtBefore': t.debtBefore,
    'externalId': t.externalId,
  };
  static Map<String, dynamic> debt(Debt d) => {
    'id': d.id,
    'label': d.label,
    'amount': d.amount,
    'creditor': d.creditor,
    'walletId': d.walletId,
    'dueDate': d.dueDate?.toIso8601String(),
    'isRecurring': d.isRecurring,
    'note': d.note,
    'createdAt': d.createdAt.toIso8601String(),
    'installmentAmount': d.installmentAmount,
    'totalAmount': d.totalAmount,
    'paidAmount': d.paidAmount,
    'isPaid': d.isPaid,
    'anchorDay': d.anchorDay,
  };
  static String requiredText(Map m, String key) {
    final value = m[key];
    if (value is! String || value.trim().isEmpty || value.length > 4000) {
      throw FormatException('Invalid $key.');
    }
    return value;
  }

  static String? optionalText(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.length > 10000) {
      throw const FormatException('Invalid text field.');
    }
    return value;
  }

  static double number(dynamic value) {
    if (value is! num) throw const FormatException('Invalid amount.');
    return Money.normalize(value.toDouble());
  }

  static bool flag(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is! bool) throw const FormatException('Invalid boolean field.');
    return value;
  }

  static DateTime date(dynamic value) {
    if (value is! String || DateTime.tryParse(value) == null) {
      throw const FormatException('Invalid date.');
    }
    return DateTime.parse(value);
  }

  static Wallet readWallet(Map m) {
    final type = m['accountType'] ?? 'cash';
    if (!['cash', 'bank', 'ewallet', 'credit', 'loan'].contains(type)) {
      throw const FormatException('Invalid account type.');
    }
    final day = m['dueDay'];
    if (day != null && (day is! int || day < 1 || day > 31)) {
      throw const FormatException('Invalid due day.');
    }
    final w = Wallet()
      ..id = requiredText(m, 'id')
      ..name = requiredText(m, 'name')
      ..icon = requiredText(m, 'icon')
      ..balance = number(m['balance'])
      ..createdAt = date(m['createdAt'])
      ..accountType = type
      ..creditLimit = m['creditLimit'] == null ? null : number(m['creditLimit'])
      ..spendingCap = m['spendingCap'] == null ? null : number(m['spendingCap'])
      ..dueDay = day
      ..archived = flag(m['archived']);
    if ((w.creditLimit ?? 0) < 0 || (w.spendingCap ?? 0) < 0) {
      throw const FormatException('Limits cannot be negative.');
    }
    return w;
  }

  static Transaction readTransaction(Map m) {
    final type = m['entryType'] ?? 'standard';
    if (!['standard', 'transfer', 'repayment', 'adjustment'].contains(type)) {
      throw const FormatException('Invalid transaction type.');
    }
    final t = Transaction()
      ..id = requiredText(m, 'id')
      ..walletId = requiredText(m, 'walletId')
      ..label = requiredText(m, 'label')
      ..amount = number(m['amount'])
      ..isExpense = flag(m['isExpense'])
      ..category = requiredText(m, 'category')
      ..date = date(m['date'])
      ..note = optionalText(m['note'])
      ..entryType = type
      ..toWalletId = optionalText(m['toWalletId'])
      ..debtId = optionalText(m['debtId'])
      ..debtBefore = optionalText(m['debtBefore'])
      ..externalId = optionalText(m['externalId']);
    if (t.amount <= 0) {
      throw const FormatException('Transaction amount must be positive.');
    }
    if (t.isTransfer && (t.toWalletId == null || t.toWalletId == t.walletId)) {
      throw const FormatException('Invalid transfer.');
    }
    return t;
  }

  static Debt readDebt(Map m) {
    final d = Debt()
      ..id = requiredText(m, 'id')
      ..label = requiredText(m, 'label')
      ..amount = number(m['amount'])
      ..creditor = requiredText(m, 'creditor')
      ..walletId = requiredText(m, 'walletId')
      ..dueDate = m['dueDate'] == null ? null : date(m['dueDate'])
      ..isRecurring = flag(m['isRecurring'])
      ..note = optionalText(m['note'])
      ..createdAt = date(m['createdAt'])
      ..installmentAmount = m['installmentAmount'] == null
          ? null
          : number(m['installmentAmount'])
      ..totalAmount = m['totalAmount'] == null ? null : number(m['totalAmount'])
      ..paidAmount = number(m['paidAmount'] ?? 0)
      ..isPaid = flag(m['isPaid'])
      ..anchorDay = m['anchorDay'] == null
          ? null
          : (m['anchorDay'] as num).toInt();
    if (d.amount < 0 ||
        d.paidAmount < 0 ||
        (d.installmentAmount != null && d.installmentAmount! <= 0) ||
        (d.totalAmount ?? 0) < 0) {
      throw const FormatException('Invalid debt amount.');
    }
    return d;
  }

  static Map<String, dynamic> snapshot() => {
    'version': 2,
    'exported_at': DateTime.now().toIso8601String(),
    'wallets': Hive.box<Wallet>('wallets').values.map(wallet).toList(),
    'transactions': Hive.box<Transaction>(
      'transactions',
    ).values.map(transaction).toList(),
    'debts': Hive.box<Debt>('debts').values.map(debt).toList(),
    'jamSessions': Hive.box<JamSession>('jamSessions').values
        .map(
          (s) => {
            'id': s.id,
            'name': s.name,
            'createdAt': s.createdAt.toIso8601String(),
            'isSettled': s.isSettled,
          },
        )
        .toList(),
    'jamPersons': Hive.box<JamPerson>('jamPersons').values
        .map(
          (p) => {
            'id': p.id,
            'sessionId': p.sessionId,
            'name': p.name,
            'isOwner': p.isOwner,
          },
        )
        .toList(),
    'jamExpenses': Hive.box<JamExpense>('jamExpenses').values
        .map(
          (e) => {
            'id': e.id,
            'personId': e.personId,
            'sessionId': e.sessionId,
            'description': e.description,
            'amount': e.amount,
          },
        )
        .toList(),
  };

  /// Decode all records and references before touching any live box.
  static Map<String, List<dynamic>> decode(
    Map<String, dynamic> data, {
    bool validateReferences = true,
  }) {
    if (data['version'] != 1 && data['version'] != 2) {
      throw const FormatException('Unsupported backup version.');
    }
    final result = <String, List<dynamic>>{};
    for (final name in boxes) {
      final rows = data[name] ?? (name.startsWith('jam') ? [] : null);
      if (rows is! List) throw FormatException('Missing $name.');
      final ids = <String>{};
      result[name] = rows.map((raw) {
        if (raw is! Map) throw FormatException('Invalid $name record.');
        final id = requiredText(raw, 'id');
        if (!ids.add(id)) throw FormatException('Duplicate $name ID.');
        return switch (name) {
          'wallets' => readWallet(raw),
          'transactions' => readTransaction(raw),
          'debts' => readDebt(raw),
          'jamSessions' =>
            JamSession()
              ..id = id
              ..name = requiredText(raw, 'name')
              ..createdAt = date(raw['createdAt'])
              ..isSettled = flag(raw['isSettled']),
          'jamPersons' =>
            JamPerson()
              ..id = id
              ..sessionId = requiredText(raw, 'sessionId')
              ..name = requiredText(raw, 'name')
              ..isOwner = flag(raw['isOwner']),
          _ =>
            JamExpense()
              ..id = id
              ..personId = requiredText(raw, 'personId')
              ..sessionId = requiredText(raw, 'sessionId')
              ..description = requiredText(raw, 'description')
              ..amount = Money.positive(number(raw['amount'])),
        };
      }).toList();
    }
    if (!validateReferences) return result;
    final wallets = result['wallets']!.cast<Wallet>().map((w) => w.id).toSet();
    final debts = result['debts']!.cast<Debt>().map((d) => d.id).toSet();
    for (final t in result['transactions']!.cast<Transaction>()) {
      if (!wallets.contains(t.walletId) ||
          (t.toWalletId != null && !wallets.contains(t.toWalletId)) ||
          (t.debtId != null && !debts.contains(t.debtId))) {
        throw const FormatException(
          'Transaction references a missing account or obligation.',
        );
      }
      if (t.debtBefore != null) {
        final prior = readDebt(jsonDecode(t.debtBefore!) as Map);
        if (prior.id != t.debtId || !wallets.contains(prior.walletId)) {
          throw const FormatException('Invalid payment history.');
        }
      }
    }
    for (final d in result['debts']!.cast<Debt>()) {
      if (!wallets.contains(d.walletId)) {
        throw const FormatException('Debt references a missing account.');
      }
    }
    final sessions = result['jamSessions']!
        .cast<JamSession>()
        .map((s) => s.id)
        .toSet();
    final people = {
      for (final p in result['jamPersons']!.cast<JamPerson>()) p.id: p,
    };
    for (final p in people.values) {
      if (!sessions.contains(p.sessionId)) {
        throw const FormatException('Invalid shared expense session.');
      }
    }
    for (final e in result['jamExpenses']!.cast<JamExpense>()) {
      if (people[e.personId]?.sessionId != e.sessionId ||
          !sessions.contains(e.sessionId)) {
        throw const FormatException('Invalid shared expense.');
      }
    }
    return result;
  }

  static Future<void> replace(Map<String, List<dynamic>> records) async {
    for (final name in boxes) {
      // Opening with the original types keeps existing adapters and browser data.
      switch (name) {
        case 'wallets':
          await _replace(
            Hive.box<Wallet>(name),
            records[name]!.cast<Wallet>(),
            (v) => v.id,
          );
        case 'transactions':
          await _replace(
            Hive.box<Transaction>(name),
            records[name]!.cast<Transaction>(),
            (v) => v.id,
          );
        case 'debts':
          await _replace(
            Hive.box<Debt>(name),
            records[name]!.cast<Debt>(),
            (v) => v.id,
          );
        case 'jamSessions':
          await _replace(
            Hive.box<JamSession>(name),
            records[name]!.cast<JamSession>(),
            (v) => v.id,
          );
        case 'jamPersons':
          await _replace(
            Hive.box<JamPerson>(name),
            records[name]!.cast<JamPerson>(),
            (v) => v.id,
          );
        case 'jamExpenses':
          await _replace(
            Hive.box<JamExpense>(name),
            records[name]!.cast<JamExpense>(),
            (v) => v.id,
          );
      }
    }
  }

  static Future<void> _replace<T>(
    Box<T> box,
    Iterable<T> values,
    String Function(T) id,
  ) async {
    await box.clear();
    await box.putAll({for (final v in values) id(v): v});
    await box.flush();
  }
}
