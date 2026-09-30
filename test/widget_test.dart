import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hermyonies_girl_math/app.dart';
import 'package:hermyonies_girl_math/models/wallet.dart';
import 'package:hermyonies_girl_math/models/transaction.dart';
import 'package:hermyonies_girl_math/models/debt.dart';
import 'package:hermyonies_girl_math/models/jam_session.dart';
import 'package:hermyonies_girl_math/models/jam_person.dart';
import 'package:hermyonies_girl_math/models/jam_expense.dart';
import 'package:hermyonies_girl_math/services/ledger_service.dart';
import 'package:hermyonies_girl_math/services/wallet_service.dart';
import 'package:hermyonies_girl_math/services/transaction_service.dart';
import 'package:hermyonies_girl_math/services/debt_service.dart';
import 'package:hermyonies_girl_math/services/csv_service.dart';
import 'package:hermyonies_girl_math/services/store_codec.dart';
import 'package:hermyonies_girl_math/services/import_service.dart';
import 'package:hermyonies_girl_math/services/assistant_service.dart';
import 'package:hermyonies_girl_math/utils/money.dart';

void main() {
  late Directory directory;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('hermyonie-tests-');
    Hive.init(directory.path);
    Hive.registerAdapter(WalletAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(JamSessionAdapter());
    Hive.registerAdapter(JamPersonAdapter());
    Hive.registerAdapter(JamExpenseAdapter());
    await Hive.openBox<Wallet>('wallets');
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<Debt>('debts');
    await Hive.openBox<JamSession>('jamSessions');
    await Hive.openBox<JamPerson>('jamPersons');
    await Hive.openBox<JamExpense>('jamExpenses');
    await LedgerService.initialize();
  });
  setUp(() async {
    for (final name in StoreCodec.boxes) {
      await StoreCodec.box(name).clear();
    }
    await Hive.box<String>('operationJournal').clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<String> account(
    String name,
    double balance, {
    String type = 'cash',
  }) async {
    await WalletService.add(name, 'wallet', balance, accountType: type);
    return WalletService.getAll().singleWhere((w) => w.name == name).id;
  }

  test('centavo arithmetic and invalid amounts', () {
    expect(Money.add(.1, .2), .3);
    expect(() => Money.positive(double.nan), throwsFormatException);
    expect(() => Money.positive(.001), throwsFormatException);
  });
  test('card purchases increase liability without adding cash', () async {
    await account('Cash', 1000);
    final card = await account('Atome', 1800, type: 'credit');
    await TransactionService.add(
      walletId: card,
      label: 'Lunch',
      amount: 150,
      isExpense: true,
      category: 'Food & Drink',
      date: DateTime.now(),
    );
    expect(WalletService.getTotalBalance(), 1000);
    expect(WalletService.getTotalOwed(), 1950);
  });
  test(
    'transfer and card repayment never inflate reports; undo reverses both sides',
    () async {
      final cash = await account('Cash', 1000),
          gcash = await account('GCash', 0, type: 'ewallet'),
          card = await account('Atome', 500, type: 'credit');
      await TransactionService.transfer(fromId: cash, toId: gcash, amount: 200);
      expect(WalletService.getTotalBalance(), 1000);
      await TransactionService.transfer(fromId: cash, toId: card, amount: 300);
      expect(WalletService.getTotalBalance(), 700);
      expect(WalletService.getTotalOwed(), 200);
      expect(TransactionService.getSpendingByCategory(), isEmpty);
      final tx = TransactionService.getAll().firstWhere(
        (t) => t.toWalletId == card,
      );
      await TransactionService.delete(tx.id);
      expect(WalletService.getTotalBalance(), 1000);
      expect(WalletService.getTotalOwed(), 500);
    },
  );
  test('serialized concurrent transfers cannot overspend', () async {
    final cash = await account('Cash', 100),
        other = await account('Bank', 0, type: 'bank');
    final results = await Future.wait([
      for (var i = 0; i < 2; i++)
        TransactionService.transfer(
          fromId: cash,
          toId: other,
          amount: 75,
        ).then((_) => true, onError: (_) => false),
    ]);
    expect(results.where((v) => v).length, 1);
    expect(Hive.box<Wallet>('wallets').get(cash)!.balance, 25);
    expect(TransactionService.getAll().length, 1);
  });
  test('partial payments retain history and can be undone', () async {
    final cash = await account('Cash', 2000);
    await DebtService.add(
      label: 'Installment',
      amount: 1000,
      creditor: 'Provider',
      walletId: cash,
      installmentAmount: 250,
      dueDate: DateTime(2026, 1, 31),
    );
    final debt = DebtService.getAll().single;
    await DebtService.markAsPaid(debt.id);
    expect(debt.amount, 750);
    expect(debt.paidAmount, 250);
    expect(debt.dueDate, DateTime(2026, 2, 28));
    await TransactionService.delete(TransactionService.getAll().single.id);
    final restored = DebtService.getAll().single;
    expect(restored.amount, 1000);
    expect(restored.dueDate, DateTime(2026, 1, 31));
    expect(WalletService.getTotalBalance(), 2000);
  });
  test('monthly bill advances instead of disappearing', () async {
    final cash = await account('Cash', 2000);
    await DebtService.add(
      label: 'Internet',
      amount: 500,
      creditor: 'ISP',
      walletId: cash,
      isRecurring: true,
      dueDate: DateTime(2026, 1, 31),
    );
    final debt = DebtService.getAll().single;
    await DebtService.markAsPaid(debt.id);
    expect(debt.isPaid, false);
    expect(debt.amount, 500);
    expect(debt.dueDate, DateTime(2026, 2, 28));
  });
  test(
    'paid obligation remains in history; linked account cannot be deleted',
    () async {
      final cash = await account('Cash', 2000);
      await DebtService.add(
        label: 'Bill',
        amount: 500,
        creditor: 'ISP',
        walletId: cash,
      );
      await DebtService.markAsPaid(DebtService.getAll().single.id);
      expect(DebtService.getAll(), isEmpty);
      expect(DebtService.getAll(includePaid: true).single.isPaid, true);
      await expectLater(WalletService.delete(cash), throwsFormatException);
    },
  );
  test('invalid restore is rejected before clearing current data', () async {
    await account('Cash', 1234);
    final data = StoreCodec.snapshot();
    (data['wallets'] as List).add({'id': 'broken'});
    await expectLater(
      CsvService.restoreJson(jsonEncode(data)),
      throwsFormatException,
    );
    expect(WalletService.getTotalBalance(), 1234);
    expect(WalletService.getAll().length, 1);
  });
  test('v1 backups remain importable and default to cash accounts', () async {
    final raw = jsonEncode({
      'version': 1,
      'wallets': [
        {
          'id': 'old',
          'name': 'Existing',
          'icon': 'wallet',
          'balance': 150.0,
          'createdAt': '2026-01-01T00:00:00',
        },
      ],
      'transactions': [],
      'debts': [],
    });
    await CsvService.restoreJson(raw);
    expect(WalletService.getAll().single.accountType, 'cash');
    expect(WalletService.getTotalBalance(), 150);
  });
  test(
    'durable pending journal restores last valid snapshot on startup',
    () async {
      final id = await account('Cash', 100);
      await Hive.box<String>(
        'operationJournal',
      ).put('pending', jsonEncode(StoreCodec.snapshot()));
      final w = Hive.box<Wallet>('wallets').get(id)!;
      w.balance = 999;
      await w.save();
      await LedgerService.initialize();
      expect(WalletService.getTotalBalance(), 100);
      expect(Hive.box<String>('operationJournal').get('pending'), isNull);
    },
  );
  test(
    'CSV quoting, validation and stable references prevent duplicates',
    () async {
      final id = await account('Cash', 1000);
      final rows = ImportService.parse(
        'date,description,amount,type,category,reference\n2026-01-01,"Lunch, coffee",150,expense,Food & Drink,receipt1\n2026-01-01,"Lunch, coffee",150,expense,Food & Drink,receipt1\n',
        id,
      );
      expect(rows.length, 1);
      expect(rows.single.label, 'Lunch, coffee');
      expect(await ImportService.save(rows, id), 1);
      expect(await ImportService.save(rows, id), 0);
      expect(WalletService.getTotalBalance(), 850);
      expect(
        () => ImportService.parse(
          'date,description,amount,type\n2026-01-01,Lunch,NaN,expense',
          id,
        ),
        throwsFormatException,
      );
    },
  );
  test('reports use one month and exclude balance reconciliation', () async {
    final id = await account('Cash', 1000);
    await TransactionService.add(
      walletId: id,
      label: 'Old',
      amount: 100,
      isExpense: true,
      category: 'Food & Drink',
      date: DateTime(2025, 1, 1),
    );
    await WalletService.updateBalance(id, 1200);
    expect(
      TransactionService.getSpendingByCategory(month: DateTime(2026, 1)),
      isEmpty,
    );
    expect(
      TransactionService.getSpendingByCategory(
        month: DateTime(2025, 1),
      )['Food & Drink'],
      100,
    );
  });
  test('assistant rejects hallucinated accounts and negative money', () async {
    expect(
      () => AssistantService.validate({
        'action': 'record_transaction',
        'accountId': 'fake',
        'name': 'Lunch',
        'amount': 100,
        'isExpense': true,
        'category': 'Food & Drink',
      }),
      throwsFormatException,
    );
    expect(
      () => AssistantService.validate({
        'action': 'create_account',
        'name': 'Atome',
        'accountType': 'credit',
        'openingBalance': -100,
      }),
      throwsFormatException,
    );
  });
  for (final width in [320.0, 390.0, 430.0, 1024.0]) {
    testWidgets('mobile-first screens render at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const PesowiseApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final tab in ['Accounts', 'Activity', 'Plan', 'Insights', 'Home']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
  }
  testWidgets('populated accounts and payments render on narrow phone', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cash = await account('GCash', 10000, type: 'ewallet');
      await WalletService.add(
        'Atome',
        'credit-card',
        1800,
        accountType: 'credit',
        spendingCap: 5000,
        creditLimit: 10000,
      );
      await DebtService.add(
        label: 'Internet',
        amount: 1500,
        creditor: 'ISP',
        walletId: cash,
        dueDate: DateTime.now(),
      );
    });
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PesowiseApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Accounts').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
