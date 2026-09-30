import 'dart:convert';
import 'package:http/http.dart' as http;
import 'wallet_service.dart';
import 'transaction_service.dart';
import 'debt_service.dart';
import '../utils/money.dart';
import '../utils/formatters.dart';

class AssistantService {
  static String accessToken = '';
  static Uri get _endpoint {
    const base = String.fromEnvironment('ASSISTANT_BASE_URL');
    return (base.isEmpty ? Uri.base : Uri.parse(base)).resolve(
      '/api/assistant',
    );
  }

  static Future<Map<String, dynamic>> prepare(String message) async {
    if (accessToken.isEmpty) {
      throw const FormatException(
        'Add your assistant passphrase in Settings → Assistant access.',
      );
    }
    if (message.trim().isEmpty) {
      throw const FormatException('Tell the assistant what you want to do.');
    }
    try {
      final response = await http
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'message': message.trim(),
              'accounts': WalletService.getAll()
                  .map(
                    (w) => {'id': w.id, 'name': w.name, 'type': w.accountType},
                  )
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 35));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw FormatException(
          data['error'] is String
              ? data['error']
              : 'The assistant is unavailable. Try again later.',
        );
      }
      final plan = data['plan'];
      if (plan is! Map<String, dynamic>) {
        throw const FormatException(
          'The assistant did not return a valid action.',
        );
      }
      validate(plan);
      return plan;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Could not reach the assistant. Manual entries still work.',
      );
    }
  }

  static void validate(Map<String, dynamic> p) {
    final action = p['action'];
    if (![
      'create_account',
      'record_transaction',
      'record_transfer',
      'create_debt',
      'set_cap',
      'show_summary',
      'clarify',
    ].contains(action)) {
      throw const FormatException('Unsupported assistant action.');
    }
    String text(String key) {
      final v = p[key];
      if (v is! String || v.trim().isEmpty || v.length > 2000) {
        throw FormatException('Please provide $key.');
      }
      return v;
    }

    double number(String key) {
      final v = p[key];
      if (v is! num) throw FormatException('Please provide $key.');
      return Money.positive(v.toDouble());
    }

    void account(String key) {
      final id = text(key);
      if (!WalletService.getAll().any((w) => w.id == id)) {
        throw const FormatException(
          'The assistant could not match an active account. Use its exact name.',
        );
      }
    }

    switch (action) {
      case 'create_account':
        text('name');
        if (![
          'cash',
          'bank',
          'ewallet',
          'credit',
          'loan',
        ].contains(p['accountType'])) {
          throw const FormatException('Please specify the account type.');
        }
        final opening = p['openingBalance'];
        if (opening is! num || !opening.isFinite || opening < 0) {
          throw const FormatException(
            'Please specify a valid opening balance.',
          );
        }
        Money.normalize(opening.toDouble());
        if (p['creditLimit'] != null) number('creditLimit');
        if (p['spendingCap'] != null) number('spendingCap');
      case 'record_transaction':
        account('accountId');
        text('name');
        number('amount');
        if (p['isExpense'] is! bool) {
          throw const FormatException('Specify expense or income.');
        }
        text('category');
      case 'record_transfer':
        account('accountId');
        account('toAccountId');
        number('amount');
        if (p['accountId'] == p['toAccountId']) {
          throw const FormatException('Choose different transfer accounts.');
        }
      case 'create_debt':
        account('accountId');
        text('name');
        text('creditor');
        number('amount');
        if (p['installmentAmount'] != null) number('installmentAmount');
        if (p['isRecurring'] is! bool) {
          throw const FormatException('Specify whether this bill repeats.');
        }
        if (p['dueDate'] != null &&
            DateTime.tryParse(p['dueDate'].toString()) == null) {
          throw const FormatException('Invalid due date.');
        }
      case 'set_cap':
        account('accountId');
        number('amount');
      default:
        break;
    }
  }

  static String describe(Map<String, dynamic> p) {
    String account(String key) =>
        WalletService.getAll().where((w) => w.id == p[key]).firstOrNull?.name ??
        'Account';
    String amount(String key) => p[key] is num
        ? Formatters.currency((p[key] as num).toDouble())
        : 'Not set';
    return switch (p['action']) {
      'create_account' =>
        'Create ${p['name']}\nType: ${p['accountType']}\n${['credit', 'loan'].contains(p['accountType']) ? 'Opening amount owed' : 'Opening balance'}: ${amount('openingBalance')}\nPersonal cap: ${amount('spendingCap')}\nProvider limit: ${amount('creditLimit')}',
      'record_transaction' =>
        '${p['isExpense'] == true ? 'Expense' : 'Income / refund'}: ${amount('amount')}\n${p['name']}\nAccount: ${account('accountId')}\nCategory: ${p['category']}',
      'record_transfer' =>
        'Move ${amount('amount')}\nFrom ${account('accountId')}\nTo ${account('toAccountId')}\nExcluded from income and spending.',
      'set_cap' =>
        'Set ${account('accountId')} personal cap to ${amount('amount')}.\nThis does not change the provider’s limit.',
      'create_debt' =>
        'Plan ${p['name']}\nAmount: ${amount('amount')}\nPayee: ${p['creditor']}\nFrom: ${account('accountId')}\nDue: ${p['dueDate'] ?? 'Not set'}\n${p['isRecurring'] == true
            ? 'Repeats monthly'
            : p['installmentAmount'] != null
            ? 'Installment: ${amount('installmentAmount')}'
            : 'One-off obligation'}',
      'show_summary' =>
        'Cash available: ${Formatters.currency(WalletService.getTotalBalance())}\nCard / loan balances: ${Formatters.currency(WalletService.getTotalOwed())}\nPlanned obligations: ${Formatters.currency(DebtService.getTotalDebt())}',
      _ =>
        p['message'] is String ? p['message'] : 'Please provide more detail.',
    };
  }

  static Future<void> apply(Map<String, dynamic> p) async {
    validate(p);
    double n(String key) => (p[key] as num).toDouble();
    double? optional(String key) => p[key] == null ? null : n(key);
    switch (p['action']) {
      case 'create_account':
        await WalletService.add(
          p['name'],
          'wallet',
          n('openingBalance'),
          accountType: p['accountType'],
          creditLimit: optional('creditLimit'),
          spendingCap: optional('spendingCap'),
        );
      case 'record_transaction':
        await TransactionService.add(
          walletId: p['accountId'],
          label: p['name'],
          amount: n('amount'),
          isExpense: p['isExpense'],
          category: p['category'],
          date: DateTime.now(),
          note: 'Added with assistant',
        );
      case 'record_transfer':
        await TransactionService.transfer(
          fromId: p['accountId'],
          toId: p['toAccountId'],
          amount: n('amount'),
        );
      case 'set_cap':
        await WalletService.setCap(p['accountId'], n('amount'));
      case 'create_debt':
        await DebtService.add(
          label: p['name'],
          amount: n('amount'),
          creditor: p['creditor'],
          walletId: p['accountId'],
          dueDate: p['dueDate'] == null ? null : DateTime.parse(p['dueDate']),
          isRecurring: p['isRecurring'],
          installmentAmount: optional('installmentAmount'),
        );
      default:
        break;
    }
  }
}
