import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../models/debt.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/debt_service.dart';
import '../../utils/formatters.dart';
import '../../utils/money.dart';
import 'components.dart';
import 'forms.dart';
import 'settings_screen.dart';
import 'assistant_sheet.dart';

class WalletWorkspace extends StatefulWidget {
  const WalletWorkspace({super.key});
  @override
  State<WalletWorkspace> createState() => _WalletWorkspaceState();
}

class _WalletWorkspaceState extends State<WalletWorkspace> {
  int _tab = 0;
  String _query = '';
  String? _accountFilter;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _search = TextEditingController();
  static const _labels = ['Home', 'Accounts', 'Activity', 'Plan', 'Insights'];
  static const _icons = [
    WalletIcons.home,
    WalletIcons.wallet,
    WalletIcons.arrowLeftRight,
    WalletIcons.calendarDays,
    WalletIcons.barChart3,
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _add() => openSheet(context, const ActionSheet());
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      Hive.box<Wallet>('wallets').listenable(),
      Hive.box<Transaction>('transactions').listenable(),
      Hive.box<Debt>('debts').listenable(),
    ]),
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 900;
      return Scaffold(
        appBar: AppBar(
          backgroundColor: PesowiseColors.background,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: PesowiseColors.strong,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  WalletIcons.wallet,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Hermyonie’s',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Ask your assistant',
              onPressed: () => openSheet(context, const AssistantSheet()),
              icon: const Icon(
                WalletIcons.sparkles,
                color: PesowiseColors.strong,
              ),
            ),
            IconButton(
              tooltip: 'Settings and imports',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(WalletIcons.settings2),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                destinations: List.generate(
                  5,
                  (i) => NavigationRailDestination(
                    icon: Icon(_icons[i]),
                    label: Text(_labels[i]),
                  ),
                ),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView(
                    key: PageStorageKey(_tab),
                    padding: EdgeInsets.fromLTRB(
                      wide ? 32 : 20,
                      12,
                      wide ? 32 : 20,
                      110,
                    ),
                    children: [
                      switch (_tab) {
                        0 => _home(),
                        1 => _accounts(),
                        2 => _activity(),
                        3 => _plan(),
                        _ => _insights(),
                      },
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add,
          backgroundColor: PesowiseColors.strong,
          foregroundColor: Colors.white,
          icon: const Icon(WalletIcons.plus),
          label: const Text('Add new'),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                height: 72,
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: List.generate(
                  5,
                  (i) => NavigationDestination(
                    icon: Icon(_icons[i], size: 21),
                    label: _labels[i],
                  ),
                ),
              ),
      );
    },
  );
  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: PesowiseColors.muted, height: 1.5),
        ),
      ],
    ),
  );
  Widget _metric(String label, double value, IconData icon) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PesowiseColors.strong, size: 20),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: PesowiseColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Formatters.currency(value),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  List<Transaction> get _monthly => TransactionService.getAll()
      .where((t) => t.date.year == _month.year && t.date.month == _month.month)
      .toList();
  Widget _home() {
    final cash = WalletService.getTotalBalance(),
        owed = Money.add(
          WalletService.getTotalOwed(),
          DebtService.getTotalDebt(),
        );
    final now = DateTime.now();
    final nextPay = now.day < 15
        ? DateTime(now.year, now.month, 15)
        : DateTime(now.year, now.month + 1, 0);
    final reserved = Money.sum(
      DebtService.getAll()
          .where((d) => d.dueDate != null && !d.dueDate!.isAfter(nextPay))
          .map((d) => d.nextPayment),
    );
    final debts = DebtService.getAll().take(3),
        recent = TransactionService.getAll().take(4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Your money,\nwith a plan.',
          DateFormat('EEEE, MMMM d').format(now),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF632A44), Color(0xFF964363)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(WalletIcons.wallet, color: Color(0xFFF7DCE7), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'CASH AVAILABLE',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFF7DCE7),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatters.currency(cash),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFB58098)),
              const SizedBox(height: 10),
              const Text(
                'After upcoming payments',
                style: TextStyle(color: Color(0xFFF7DCE7), fontSize: 12),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatters.currency(Money.add(cash, -reserved)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Through ${DateFormat('MMM d').format(nextPay)} · Recorded bills only',
                style: const TextStyle(color: Color(0xFFEAD2DE), fontSize: 11),
              ),
              const SizedBox(height: 4),
              const Text(
                'Income and everyday spending are not projected.',
                style: TextStyle(
                  color: Color(0xFFEAD2DE),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _metric('Total owed', owed, WalletIcons.creditCard),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(
                'Upcoming payments',
                reserved,
                WalletIcons.calendarClock,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => openSheet(context, const AssistantSheet()),
          child: const Panel(
            color: PesowiseColors.chipBg,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(WalletIcons.sparkles, color: PesowiseColors.strong),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Less typing. More clarity.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add an account or log an expense.',
                        style: TextStyle(
                          fontSize: 12,
                          color: PesowiseColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  WalletIcons.arrowUpRight,
                  size: 20,
                  color: PesowiseColors.strong,
                ),
              ],
            ),
          ),
        ),
        SectionTitle(
          'Coming up',
          action: TextButton(
            onPressed: () => setState(() => _tab = 3),
            child: const Text('View plan'),
          ),
        ),
        if (debts.isEmpty)
          EmptyPanel(
            icon: WalletIcons.calendarCheck,
            title: 'A clearer month starts here',
            description:
                'Add your bills and installments to see what needs paying next.',
            actionLabel: 'Add a payment',
            onAction: () => openSheet(context, const DebtForm()),
          )
        else
          ...debts.map(_debtCard),
        SectionTitle(
          'Recent activity',
          action: TextButton(
            onPressed: () => setState(() => _tab = 2),
            child: const Text('View all'),
          ),
        ),
        if (recent.isEmpty)
          const EmptyPanel(
            icon: WalletIcons.receipt,
            title: 'Your first entry is a fresh start',
            description:
                'Add an account, then record a purchase, income or transfer.',
          )
        else
          ...recent.map(_transactionCard),
      ],
    );
  }

  Widget _accounts() {
    final wallets = WalletService.getAll();
    final cash = wallets.where((w) => !w.isLiability),
        credit = wallets.where((w) => w.isLiability);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Your accounts',
          'Cash you have. Credit you use. Clearly separated.',
        ),
        if (wallets.isEmpty)
          EmptyPanel(
            icon: WalletIcons.wallet,
            title: 'Give every peso a place',
            description:
                'Start with cash, a bank account or an e-wallet. Add cards and loans separately.',
            actionLabel: 'Add your first account',
            onAction: () => openSheet(context, const AccountForm()),
          ),
        if (cash.isNotEmpty) ...[
          const SectionTitle('Cash & savings'),
          ...cash.map(_accountCard),
        ],
        if (credit.isNotEmpty) ...[
          const SectionTitle('Cards & loans'),
          ...credit.map(_accountCard),
        ],
        if (wallets.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => openSheet(context, const AccountForm()),
            icon: const Icon(WalletIcons.plus),
            label: const Text('Add another account'),
          ),
        ],
      ],
    );
  }

  Widget _accountCard(Wallet w) {
    final limit = w.spendingCap ?? w.creditLimit;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: PesowiseColors.chipBg,
                  child: Icon(
                    w.isLiability
                        ? WalletIcons.creditCard
                        : w.accountType == 'bank'
                        ? WalletIcons.landmark
                        : w.accountType == 'ewallet'
                        ? WalletIcons.smartphone
                        : WalletIcons.wallet,
                    color: PesowiseColors.strong,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        w.typeLabel,
                        style: const TextStyle(
                          color: PesowiseColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Account options',
                  onSelected: (v) => _accountAction(w, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'activity',
                      child: Text('View activity'),
                    ),
                    const PopupMenuItem(
                      value: 'reconcile',
                      child: Text('Reconcile balance'),
                    ),
                    if (w.isLiability)
                      const PopupMenuItem(
                        value: 'cap',
                        child: Text('Set personal cap'),
                      ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive account'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete empty account'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              w.isLiability ? 'Amount owed' : 'Available balance',
              style: const TextStyle(color: PesowiseColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.currency(w.balance),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.8,
                ),
              ),
            ),
            if (limit != null) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (w.balance / limit).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: w.balance > limit
                      ? Colors.deepOrange
                      : PesowiseColors.strong,
                  backgroundColor: PesowiseColors.chipBg,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${w.spendingCap != null ? 'Personal cap' : 'Credit limit'} ${Formatters.currency(limit)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: PesowiseColors.muted,
                ),
              ),
              Text(
                '${w.balance > limit ? 'Over by' : 'Remaining'} ${Formatters.currency((limit - w.balance).abs())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: PesowiseColors.muted,
                ),
              ),
            ],
            if (w.creditLimit != null && w.spendingCap != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Provider limit: ${Formatters.currency(w.creditLimit!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PesowiseColors.muted,
                  ),
                ),
              ),
            if (w.dueDay != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Payment due on day ${w.dueDay} each month',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PesowiseColors.muted,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      openSheet(context, EntryForm(initialWalletId: w.id)),
                  icon: const Icon(WalletIcons.plus, size: 16),
                  label: const Text('Add entry'),
                ),
                if (w.isLiability)
                  OutlinedButton.icon(
                    onPressed: () =>
                        openSheet(context, TransferForm(initialToId: w.id)),
                    icon: const Icon(WalletIcons.arrowDownLeft, size: 16),
                    label: const Text('Repay'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accountAction(Wallet w, String action) async {
    if (action == 'reconcile') {
      await openSheet(context, ReconcileForm(wallet: w));
      return;
    }
    if (action == 'cap') {
      await openSheet(context, CapForm(wallet: w));
      return;
    }
    if (action == 'activity') {
      setState(() {
        _accountFilter = w.id;
        _tab = 2;
      });
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${action == 'archive' ? 'Archive' : 'Delete'} ${w.name}?'),
        content: Text(
          action == 'archive'
              ? 'History stays available. Reconcile this account to zero first.'
              : 'Only accounts without transaction or payment history can be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        if (action == 'archive') {
          await WalletService.archive(w.id);
        } else {
          await WalletService.delete(w.id);
        }
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
  }

  Widget _monthPicker() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () =>
              setState(() => _month = DateTime(_month.year, _month.month - 1)),
          icon: const Icon(WalletIcons.chevronLeft),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed:
              _month.year == DateTime.now().year &&
                  _month.month == DateTime.now().month
              ? null
              : () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
          icon: const Icon(WalletIcons.chevronRight),
        ),
      ],
    ),
  );
  Widget _activity() {
    final accounts = WalletService.getAll(includeArchived: true);
    if (_accountFilter != null &&
        !accounts.any((w) => w.id == _accountFilter)) {
      _accountFilter = null;
    }
    final entries = _monthly
        .where(
          (t) =>
              (_accountFilter == null ||
                  t.walletId == _accountFilter ||
                  t.toWalletId == _accountFilter) &&
              '${t.label} ${t.category} ${t.note ?? ''}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Activity', 'The story behind your balances.'),
        _monthPicker(),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search transactions',
            prefixIcon: Icon(WalletIcons.search),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_accountFilter),
          initialValue: _accountFilter,
          decoration: const InputDecoration(labelText: 'Account'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All accounts'),
            ),
            ...accounts.map(
              (w) => DropdownMenuItem(
                value: w.id,
                child: Text(w.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _accountFilter = v),
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          const EmptyPanel(
            icon: WalletIcons.search,
            title: 'No entries in this view',
            description: 'Try another month or account, or add a transaction.',
          )
        else
          ...entries.map(_transactionCard),
      ],
    );
  }

  Widget _transactionCard(Transaction t) {
    final w = Hive.box<Wallet>('wallets').get(t.walletId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: PesowiseColors.chipBg,
              child: Icon(
                t.isTransfer
                    ? WalletIcons.arrowLeftRight
                    : t.isExpense
                    ? WalletIcons.arrowUpRight
                    : WalletIcons.arrowDownLeft,
                size: 18,
                color: t.countsAsIncome
                    ? PesowiseColors.green
                    : PesowiseColors.strong,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${w?.name ?? 'Account'} · ${Formatters.shortDate(t.date)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: PesowiseColors.muted,
                    ),
                  ),
                  Text(
                    t.entryType == 'adjustment'
                        ? 'Balance adjustment'
                        : t.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: PesowiseColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${t.isTransfer
                      ? ''
                      : t.isExpense
                      ? '−'
                      : '+'}${Formatters.currency(t.amount)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.countsAsIncome
                        ? PesowiseColors.green
                        : PesowiseColors.ink,
                  ),
                ),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Undo transaction',
                    icon: const Icon(WalletIcons.undo2, size: 16),
                    onPressed: () => _undo(t),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _undo(Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Undo this transaction?'),
        content: const Text(
          'Its effect on balances and any linked payment will be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await TransactionService.delete(t.id);
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
  }

  Widget _plan() {
    final debts = DebtService.getAll(),
        paid = DebtService.getAll(includePaid: true).where((d) => d.isPaid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Make a little room.',
          'Bills, installments and the dates that matter.',
        ),
        Panel(
          color: PesowiseColors.chipBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECORDED OBLIGATIONS',
                style: TextStyle(
                  color: PesowiseColors.strong,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.currency(DebtService.getTotalDebt()),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep a debt here or as a card/loan balance, so you don’t count the same amount twice.',
                style: TextStyle(
                  fontSize: 12,
                  color: PesowiseColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Upcoming & overdue'),
        if (debts.isEmpty)
          EmptyPanel(
            icon: WalletIcons.calendarDays,
            title: 'Nothing scheduled yet',
            description:
                'Plan recurring bills or split a fixed obligation into monthly installments.',
            actionLabel: 'Add a bill or installment',
            onAction: () => openSheet(context, const DebtForm()),
          )
        else
          ...debts.map(_debtCard),
        if (paid.isNotEmpty) ...[
          const SectionTitle('Completed'),
          ...paid.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      WalletIcons.checkCircle2,
                      color: PesowiseColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        d.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${Formatters.currency(d.paidAmount)} paid',
                      style: const TextStyle(
                        color: PesowiseColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _debtCard(Debt d) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final late =
        d.dueDate != null &&
        DateTime(
          d.dueDate!.year,
          d.dueDate!.month,
          d.dueDate!.day,
        ).isBefore(today);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.creditor,
                        style: const TextStyle(
                          color: PesowiseColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.currency(d.nextPayment),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              d.dueDate == null
                  ? 'No due date'
                  : '${late ? 'Overdue · ' : ''}${DateFormat('MMM d').format(d.dueDate!)}${d.isRecurring ? ' · Monthly' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: late ? const Color(0xFFB14128) : PesowiseColors.muted,
              ),
            ),
            if (d.installmentAmount != null)
              Text(
                '${Formatters.currency(d.amount)} remaining',
                style: const TextStyle(
                  fontSize: 12,
                  color: PesowiseColors.muted,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'From ${Hive.box<Wallet>('wallets').get(d.walletId)?.name ?? 'Missing account'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PesowiseColors.muted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => openSheet(context, PaymentForm(debt: d)),
                  child: const Text('Record payment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _insights() {
    final income = Money.sum(
          _monthly.where((t) => t.countsAsIncome).map((t) => t.amount),
        ),
        expense = Money.sum(
          _monthly.where((t) => t.countsAsSpending).map((t) => t.amount),
        );
    final categories = TransactionService.getSpendingByCategory(
      month: _month,
    ).entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'See the bigger picture.',
          'Know where your money goes, one month at a time.',
        ),
        _monthPicker(),
        Row(
          children: [
            Expanded(
              child: _metric('Income', income, WalletIcons.arrowDownLeft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric('Spending', expense, WalletIcons.arrowUpRight),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Panel(
          color: PesowiseColors.chipBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Income minus spending',
                style: TextStyle(fontSize: 12, color: PesowiseColors.muted),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatters.currency(Money.add(income, -expense)),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Transfers, card repayments and balance adjustments are excluded.',
          style: TextStyle(
            fontSize: 12,
            color: PesowiseColors.muted,
            height: 1.5,
          ),
        ),
        const SectionTitle('Spending by category'),
        if (categories.isEmpty)
          const EmptyPanel(
            icon: WalletIcons.pieChart,
            title: 'Your patterns will appear here',
            description:
                'Record expenses to see this month’s spending by category.',
          )
        else
          ...categories.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          Formatters.currency(e.value),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: expense > 0 ? e.value / expense : 0,
                        minHeight: 7,
                        color: PesowiseColors.strong,
                        backgroundColor: PesowiseColors.chipBg,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${expense > 0 ? (e.value / expense * 100).toStringAsFixed(0) : 0}% of this month’s spending',
                        style: const TextStyle(
                          fontSize: 11,
                          color: PesowiseColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
