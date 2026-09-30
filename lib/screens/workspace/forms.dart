import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../models/wallet.dart';
import '../../models/debt.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/debt_service.dart';
import '../../utils/categories.dart';
import '../../utils/money.dart';
import '../../utils/formatters.dart';
import 'components.dart';

class ActionSheet extends StatelessWidget {
  const ActionSheet({super.key});
  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Make a new entry',
    subtitle: 'A small update keeps the big picture clear.',
    child: Column(
      children: [
        _action(
          context,
          WalletIcons.wallet,
          'Account',
          'Cash, bank, e-wallet, credit or loan',
          const AccountForm(),
        ),
        _action(
          context,
          WalletIcons.receipt,
          'Transaction',
          'A purchase, income or refund',
          const EntryForm(),
        ),
        _action(
          context,
          WalletIcons.arrowLeftRight,
          'Transfer or repayment',
          'Move money without counting it as spending',
          const TransferForm(),
        ),
        _action(
          context,
          WalletIcons.calendarDays,
          'Bill or installment',
          'Plan a due date and payment schedule',
          const DebtForm(),
        ),
      ],
    ),
  );
  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget form,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white,
      leading: Icon(icon, color: PesowiseColors.strong),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(WalletIcons.chevronRight, size: 18),
      onTap: () {
        final parent = Navigator.of(context).context;
        Navigator.pop(context);
        openSheet(parent, form);
      },
    ),
  );
}

class AccountForm extends StatelessWidget {
  const AccountForm({super.key});
  @override
  Widget build(BuildContext context) => const _Editor(kind: 'account');
}

class EntryForm extends StatelessWidget {
  final String? initialWalletId;
  const EntryForm({super.key, this.initialWalletId});
  @override
  Widget build(BuildContext context) =>
      _Editor(kind: 'entry', initialWalletId: initialWalletId);
}

class TransferForm extends StatelessWidget {
  final String? initialToId;
  const TransferForm({super.key, this.initialToId});
  @override
  Widget build(BuildContext context) =>
      _Editor(kind: 'transfer', initialToId: initialToId);
}

class DebtForm extends StatelessWidget {
  const DebtForm({super.key});
  @override
  Widget build(BuildContext context) => const _Editor(kind: 'debt');
}

class ReconcileForm extends StatelessWidget {
  final Wallet wallet;
  const ReconcileForm({super.key, required this.wallet});
  @override
  Widget build(BuildContext context) =>
      _Editor(kind: 'reconcile', wallet: wallet);
}

class CapForm extends StatelessWidget {
  final Wallet wallet;
  const CapForm({super.key, required this.wallet});
  @override
  Widget build(BuildContext context) => _Editor(kind: 'cap', wallet: wallet);
}

class PaymentForm extends StatelessWidget {
  final Debt debt;
  const PaymentForm({super.key, required this.debt});
  @override
  Widget build(BuildContext context) => _Editor(kind: 'payment', debt: debt);
}

class _Editor extends StatefulWidget {
  final String kind;
  final String? initialWalletId, initialToId;
  final Wallet? wallet;
  final Debt? debt;
  const _Editor({
    required this.kind,
    this.initialWalletId,
    this.initialToId,
    this.wallet,
    this.debt,
  });
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String _type = 'cash', _mode = 'once', _category = 'Food & Drink';
  String? _source, _target, _error;
  bool _expense = true, _busy = false;
  DateTime? _date;
  TextEditingController _c(String name) =>
      _controllers.putIfAbsent(name, () => TextEditingController());
  List<Wallet> get _cash =>
      WalletService.getAll().where((w) => !w.isLiability).toList();
  List<Wallet> get _all => WalletService.getAll();
  @override
  void initState() {
    super.initState();
    _date = widget.kind == 'entry' ? DateTime.now() : null;
    _source =
        widget.initialWalletId ??
        (widget.kind == 'entry' ? _all.firstOrNull?.id : _cash.firstOrNull?.id);
    _target = widget.initialToId;
    if (widget.kind == 'account') _c('amount').text = '0';
    if (widget.wallet != null) {
      _c(
        'amount',
      ).text = (widget.kind == 'cap'
              ? widget.wallet!.spendingCap ?? widget.wallet!.creditLimit ?? 0
              : widget.wallet!.balance)
          .toStringAsFixed(2);
    }
    if (widget.debt != null) {
      _c('amount').text = widget.debt!.nextPayment.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Please fill in this field.' : null;
  String? _amount(String? v, {bool zero = false}) {
    final n = Money.parse(v ?? '');
    if (n == null) return 'Enter a valid amount.';
    if (zero ? n < 0 : n <= 0) {
      return zero
          ? 'Amount cannot be negative.'
          : 'Amount must be greater than zero.';
    }
    return null;
  }

  Widget _field(
    String key,
    String label, {
    bool money = false,
    bool optional = false,
    bool zero = false,
    String? hint,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: _c(key),
      keyboardType: money
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      maxLines: lines,
      textCapitalization: money
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: money ? '₱ ' : null,
      ),
      validator: (v) => optional && (v == null || v.trim().isEmpty)
          ? null
          : money
          ? _amount(v, zero: zero)
          : _required(v),
    ),
  );
  Widget _accounts(
    String label,
    List<Wallet> accounts,
    String? selected,
    ValueChanged<String?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$selected'),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: accounts
          .map(
            (w) => DropdownMenuItem(
              value: w.id,
              child: Text(w.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _busy ? null : changed,
      validator: (v) => v == null ? 'Choose an account.' : null,
    ),
  );
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2020),
      lastDate: widget.kind == 'entry' ? now : DateTime(now.year + 10),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    double amount(String key) => Money.parse(_c(key).text)!;
    double? optional(String key) =>
        _c(key).text.trim().isEmpty ? null : amount(key);
    try {
      switch (widget.kind) {
        case 'account':
          final due = _c('day').text.trim();
          final day = due.isEmpty ? null : int.tryParse(due);
          if (due.isNotEmpty && (day == null || day < 1 || day > 31)) {
            throw const FormatException('Due day must be between 1 and 31.');
          }
          await WalletService.add(
            _c('name').text,
            _type == 'credit'
                ? 'credit-card'
                : _type == 'bank'
                ? 'building'
                : _type == 'ewallet'
                ? 'smartphone'
                : 'wallet',
            amount('amount'),
            accountType: _type,
            creditLimit: _type == 'credit' ? optional('limit') : null,
            spendingCap: ['credit', 'loan'].contains(_type)
                ? optional('cap')
                : null,
            dueDay: day,
          );
        case 'entry':
          await TransactionService.add(
            walletId: _source!,
            label: _c('name').text,
            amount: amount('amount'),
            isExpense: _expense,
            category: _category,
            date: _date!,
            note: _c('note').text.trim().isEmpty
                ? null
                : _c('note').text.trim(),
          );
        case 'transfer':
          await TransactionService.transfer(
            fromId: _source!,
            toId: _target!,
            amount: amount('amount'),
            note: _c('note').text.trim(),
          );
        case 'debt':
          await DebtService.add(
            label: _c('name').text,
            amount: amount('amount'),
            creditor: _c('payee').text,
            walletId: _source!,
            dueDate: _date,
            isRecurring: _mode == 'recurring',
            installmentAmount: _mode == 'installments'
                ? amount('installment')
                : null,
            note: _c('note').text.trim(),
          );
        case 'reconcile':
          await WalletService.updateBalance(
            widget.wallet!.id,
            amount('amount'),
          );
        case 'cap':
          await WalletService.setCap(widget.wallet!.id, amount('amount'));
        case 'payment':
          await DebtService.markAsPaid(
            widget.debt!.id,
            amount: amount('amount'),
          );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Could not save. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind, liability = ['credit', 'loan'].contains(_type);
    final selected = _all.where((w) => w.id == _source).firstOrNull;
    final title = switch (kind) {
      'account' => 'Add an account',
      'entry' => 'Record a transaction',
      'transfer' => 'Move your money',
      'debt' => 'Plan a payment',
      'cap' => 'Set a personal cap',
      'reconcile' => 'Reconcile your balance',
      _ => 'Record a payment',
    };
    final subtitle = switch (kind) {
      'account' =>
        'Track it here. This does not open or connect a real account.',
      'entry' => 'A little detail makes your totals more useful.',
      'transfer' => 'Transfers and repayments won’t inflate your spending.',
      'debt' => 'One-off bills, monthly bills or a fixed installment plan.',
      'cap' =>
        'A tracking limit for you. Your provider’s limit stays the same.',
      'reconcile' => 'Match your statement with a recorded balance adjustment.',
      _ => 'Only record money you have actually paid.',
    };
    final noAccounts =
        (kind == 'entry' && _all.isEmpty) ||
        ((kind == 'transfer' || kind == 'debt') && _cash.isEmpty);
    return FormSheet(
      title: title,
      subtitle: subtitle,
      child: noAccounts
          ? EmptyPanel(
              icon: WalletIcons.wallet,
              title: 'Add a cash account first',
              description:
                  'You need an account to record transactions or fund payments.',
              actionLabel: 'Add account',
              onAction: () {
                final parent = Navigator.of(context).context;
                Navigator.pop(context);
                openSheet(parent, const AccountForm());
              },
            )
          : Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kind == 'account') ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in [
                          ('Cash', 'cash'),
                          ('GCash', 'ewallet'),
                          ('Maya', 'ewallet'),
                          ('Atome', 'credit'),
                          ('Bank', 'bank'),
                          ('Loan', 'loan'),
                        ])
                          ActionChip(
                            label: Text(p.$1),
                            onPressed: () => setState(() {
                              _c('name').text = p.$1;
                              _type = p.$2;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _field('name', 'Account name', hint: 'e.g. GCash or Atome'),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_type),
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Account type',
                      ),
                      items: [
                        for (final t in [
                          ('cash', 'Cash'),
                          ('bank', 'Bank'),
                          ('ewallet', 'E-wallet'),
                          ('credit', 'Credit card'),
                          ('loan', 'Loan'),
                        ])
                          DropdownMenuItem(value: t.$1, child: Text(t.$2)),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'amount',
                      liability ? 'Current amount owed' : 'Opening balance',
                      money: true,
                      zero: true,
                    ),
                    if (_type == 'credit')
                      _field(
                        'limit',
                        'Provider credit limit (optional)',
                        money: true,
                        optional: true,
                      ),
                    if (liability) ...[
                      _field(
                        'cap',
                        'Personal spending cap (optional)',
                        money: true,
                        optional: true,
                      ),
                      _field(
                        'day',
                        'Monthly due day (optional)',
                        optional: true,
                        hint: '1 to 31',
                      ),
                    ],
                  ],
                  if (kind == 'entry') ...[
                    _accounts(
                      'Account',
                      _all,
                      _source,
                      (v) => setState(() => _source = v),
                    ),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(
                            selected?.isLiability == true
                                ? 'Purchase'
                                : 'Expense',
                          ),
                          icon: const Icon(WalletIcons.arrowUpRight, size: 16),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(
                            selected?.isLiability == true ? 'Refund' : 'Income',
                          ),
                          icon: const Icon(WalletIcons.arrowDownLeft, size: 16),
                        ),
                      ],
                      selected: {_expense},
                      onSelectionChanged: (v) => setState(() {
                        _expense = v.first;
                        _category =
                            (_expense ? Categories.expense : Categories.income)
                                .first;
                      }),
                    ),
                    const SizedBox(height: 20),
                    _field('name', 'Description', hint: 'e.g. Lunch or salary'),
                    _field('amount', 'Amount', money: true),
                    DropdownButtonFormField<String>(
                      key: ValueKey('$_expense-$_category'),
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: (_expense ? Categories.expense : Categories.income)
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (kind == 'transfer') ...[
                    _accounts(
                      'From account',
                      _cash,
                      _source,
                      (v) => setState(() {
                        _source = v;
                        if (_target == v) _target = null;
                      }),
                    ),
                    _accounts(
                      'To account',
                      _all.where((w) => w.id != _source).toList(),
                      _target,
                      (v) => setState(() => _target = v),
                    ),
                    _field('amount', 'Amount to move', money: true),
                  ],
                  if (kind == 'debt') ...[
                    _field(
                      'name',
                      'Description',
                      hint: 'e.g. Internet or installment',
                    ),
                    _field('payee', 'Payee / creditor'),
                    DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(labelText: 'Schedule'),
                      items: const [
                        DropdownMenuItem(
                          value: 'once',
                          child: Text('One-off obligation'),
                        ),
                        DropdownMenuItem(
                          value: 'recurring',
                          child: Text('Recurring monthly bill'),
                        ),
                        DropdownMenuItem(
                          value: 'installments',
                          child: Text('Monthly installment plan'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _mode = v!),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'amount',
                      _mode == 'installments'
                          ? 'Total remaining obligation'
                          : 'Bill amount',
                      money: true,
                    ),
                    if (_mode == 'installments')
                      _field('installment', 'Monthly installment', money: true),
                    _accounts(
                      'Pay from',
                      _cash,
                      _source,
                      (v) => setState(() => _source = v),
                    ),
                  ],
                  if (kind == 'entry' || kind == 'debt') ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _pickDate,
                      icon: const Icon(WalletIcons.calendarDays, size: 18),
                      label: Text(
                        _date == null
                            ? 'Choose due date (optional)'
                            : '${kind == 'entry' ? 'Date' : 'Next due'}: ${DateFormat('MMM d, yyyy').format(_date!)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field('note', 'Note (optional)', optional: true, lines: 2),
                  ],
                  if (kind == 'transfer')
                    _field('note', 'Note (optional)', optional: true),
                  if (['cap', 'reconcile', 'payment'].contains(kind)) ...[
                    if (widget.wallet != null)
                      Text(
                        widget.wallet!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (widget.debt != null)
                      Text(
                        '${widget.debt!.label} · ${Formatters.currency(widget.debt!.amount)} remaining',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 16),
                    _field(
                      'amount',
                      kind == 'cap'
                          ? 'Personal cap'
                          : kind == 'reconcile'
                          ? 'Actual balance'
                          : 'Payment amount',
                      money: true,
                      zero: kind == 'reconcile',
                    ),
                  ],
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB14128)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            kind == 'payment'
                                ? 'Record payment'
                                : kind == 'transfer'
                                ? 'Move money'
                                : 'Save',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
