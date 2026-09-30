import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../models/debt.dart';
import '../../models/jam_session.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/debt_service.dart';
import '../../services/jam_service.dart';
import '../../widgets/transaction_tile.dart';
import '../../utils/formatters.dart';
import '../transactions/add_transaction_screen.dart';
import '../jam/jam_sessions_screen.dart';
import '../../services/csv_service.dart';
import '../../services/google_drive_service.dart';
import '../../widgets/backup_reminder_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackupReminderDialog.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PesowiseColors.background,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Wallet>(HiveBoxes.wallets).listenable(),
          builder: (context, _, __) => ValueListenableBuilder(
            valueListenable: Hive.box<Transaction>(
              HiveBoxes.transactions,
            ).listenable(),
            builder: (context, _, __) => ValueListenableBuilder(
              valueListenable: Hive.box<Debt>(HiveBoxes.debts).listenable(),
              builder: (context, _, __) {
                final totalBalance = WalletService.getTotalBalance();
                final totalDebt = DebtService.getTotalDebt();
                final wallets = WalletService.getAll();

                if (wallets.isNotEmpty &&
                    (_selectedWalletId == null ||
                        !wallets.any((w) => w.id == _selectedWalletId))) {
                  _selectedWalletId = null;
                }

                final allTx = TransactionService.getAll();
                final filteredTx = _selectedWalletId == null
                    ? allTx.take(5).toList()
                    : allTx
                          .where((t) => t.walletId == _selectedWalletId)
                          .take(5)
                          .toList();

                final selectedWalletName = _selectedWalletId == null
                    ? 'All'
                    : wallets
                              .where((w) => w.id == _selectedWalletId)
                              .map((w) => w.name)
                              .firstOrNull ??
                          'All';

                final now = DateTime.now();
                final monthlyExpenses = allTx
                    .where(
                      (t) =>
                          t.isExpense &&
                          t.date.month == now.month &&
                          t.date.year == now.year,
                    )
                    .fold(0.0, (sum, t) => sum + t.amount);
                final monthlyIncome = allTx
                    .where(
                      (t) =>
                          !t.isExpense &&
                          t.date.month == now.month &&
                          t.date.year == now.year,
                    )
                    .fold(0.0, (sum, t) => sum + t.amount);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                            decoration: const BoxDecoration(
                              color: PesowiseColors.accent,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(28),
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Good day! 🌸',
                                          style: TextStyle(
                                            color: PesowiseColors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          Formatters.monthYear(DateTime.now()),
                                          style: const TextStyle(
                                            color: PesowiseColors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              CsvService.importAll(context),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: PesowiseColors.white
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              WalletIcons.upload,
                                              color: PesowiseColors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => CsvService.exportAll(),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: PesowiseColors.white
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              WalletIcons.download,
                                              color: PesowiseColors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              GoogleDriveService.backupToDrive(
                                                context,
                                              ),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: PesowiseColors.white
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              WalletIcons.cloud,
                                              color: PesowiseColors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AddTransactionScreen(),
                                            ),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: PesowiseColors.white
                                                  .withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              WalletIcons.plus,
                                              color: PesowiseColors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: PesowiseColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.currency(totalBalance),
                                  style: const TextStyle(
                                    color: PesowiseColors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (totalDebt > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'After debts: ${Formatters.currency(totalBalance - totalDebt)}',
                                    style: TextStyle(
                                      color: PesowiseColors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _summaryChip(
                                      WalletIcons.arrowDownLeft,
                                      'Income',
                                      Formatters.currency(monthlyIncome),
                                    ),
                                    const SizedBox(width: 10),
                                    _summaryChip(
                                      WalletIcons.arrowUpRight,
                                      'Expenses',
                                      Formatters.currency(monthlyExpenses),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Wallets ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'My Wallets',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: PesowiseColors.strong,
                                  ),
                                ),
                                Text(
                                  '${wallets.length} wallet${wallets.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PesowiseColors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (wallets.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'No wallets yet — add one in the Wallets tab.',
                                style: TextStyle(
                                  color: PesowiseColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: wallets.length + 1,
                                itemBuilder: (context, i) {
                                  if (i == 0) {
                                    final isSel = _selectedWalletId == null;
                                    return GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedWalletId = null,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 150,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? PesowiseColors.strong
                                              : PesowiseColors.background,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isSel
                                                ? PesowiseColors.strong
                                                : PesowiseColors.muted,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'All Wallets',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSel
                                                    ? PesowiseColors.white
                                                    : PesowiseColors.muted,
                                              ),
                                            ),
                                            Text(
                                              Formatters.currency(totalBalance),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: isSel
                                                    ? PesowiseColors.white
                                                    : PesowiseColors.strong,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final w = wallets[i - 1];
                                  final isSel = w.id == _selectedWalletId;
                                  return GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedWalletId = w.id,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 150,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? PesowiseColors.strong
                                            : PesowiseColors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSel
                                              ? PesowiseColors.strong
                                              : PesowiseColors.blushBorder,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            w.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSel
                                                  ? PesowiseColors.white
                                                  : PesowiseColors.muted,
                                            ),
                                          ),
                                          Text(
                                            Formatters.currency(w.balance),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isSel
                                                  ? PesowiseColors.white
                                                  : PesowiseColors.strong,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 24),

                          // ── Jam Sessions card ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ValueListenableBuilder(
                              valueListenable: Hive.box<JamSession>(
                                HiveBoxes.jamSessions,
                              ).listenable(),
                              builder: (context, _, __) {
                                final active = JamService.getAllSessions()
                                    .where((s) => !s.isSettled)
                                    .length;
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const JamSessionsScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: PesowiseColors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: PesowiseColors.blushBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: PesowiseColors.chipBg,
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                          child: const Icon(
                                            WalletIcons.users,
                                            size: 18,
                                            color: PesowiseColors.strong,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Jam Sessions',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: PesowiseColors.strong,
                                                ),
                                              ),
                                              Text(
                                                active == 0
                                                    ? 'No active sessions'
                                                    : '$active active session${active == 1 ? '' : 's'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: PesowiseColors.muted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          WalletIcons.chevronRight,
                                          size: 16,
                                          color: PesowiseColors.muted,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Recent ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Recent · $selectedWalletName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: PesowiseColors.strong,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    if (filteredTx.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'No transactions for this wallet.',
                            style: TextStyle(
                              color: PesowiseColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) =>
                                TransactionTile(transaction: filteredTx[i]),
                            childCount: filteredTx.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PesowiseColors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PesowiseColors.white),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: PesowiseColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 12,
                  color: PesowiseColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
