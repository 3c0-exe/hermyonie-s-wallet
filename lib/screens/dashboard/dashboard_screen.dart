import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../models/debt.dart';
import '../../services/wallet_service.dart';
import '../../services/transaction_service.dart';
import '../../services/debt_service.dart';
import '../../widgets/transaction_tile.dart';
import '../../utils/formatters.dart';
import '../transactions/add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PesowiseColors.background,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Wallet>(HiveBoxes.wallets).listenable(),
          builder: (context, walletBox, _) {
            return ValueListenableBuilder(
              valueListenable: Hive.box<Transaction>(HiveBoxes.transactions).listenable(),
              builder: (context, txBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box<Debt>(HiveBoxes.debts).listenable(),
                  builder: (context, debtBox, _) {
                    final totalBalance = WalletService.getTotalBalance();
                    final totalDebt = DebtService.getTotalDebt();
                    final wallets = WalletService.getAll();

                    if (wallets.isNotEmpty &&
                        (_selectedWalletId == null ||
                            !wallets.any((w) => w.id == _selectedWalletId))) {
                      _selectedWalletId = wallets.first.id;
                    } else if (wallets.isEmpty) {
                      _selectedWalletId = null;
                    }

                    final allTx = TransactionService.getAll();

                    final filteredTx = _selectedWalletId == null
                        ? allTx.take(5).toList()
                        : allTx
                            .where((t) => t.walletId == _selectedWalletId)
                            .take(5)
                            .toList();

                    final selectedWalletName = wallets
                        .where((w) => w.id == _selectedWalletId)
                        .map((w) => w.name)
                        .firstOrNull ?? 'All';

                    final thisMonth = DateTime.now();
                    final monthlyExpenses = allTx
                        .where((t) =>
                            t.isExpense &&
                            t.date.month == thisMonth.month &&
                            t.date.year == thisMonth.year)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final monthlyIncome = allTx
                        .where((t) =>
                            !t.isExpense &&
                            t.date.month == thisMonth.month &&
                            t.date.year == thisMonth.year)
                        .fold(0.0, (sum, t) => sum + t.amount);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Good day! 🌸',
                                                style: TextStyle(
                                                    color: PesowiseColors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 2),
                                            Text(Formatters.monthYear(DateTime.now()),
                                                style: const TextStyle(
                                                    color: PesowiseColors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => const AddTransactionScreen())),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: PesowiseColors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(LucideIcons.plus,
                                                color: PesowiseColors.white, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Total Balance',
                                        style: TextStyle(
                                            color: PesowiseColors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(Formatters.currency(totalBalance),
                                        style: const TextStyle(
                                            color: PesowiseColors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700)),
                                    // After-debts line — only shows if debts exist
                                    if (totalDebt > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'After debts: ${Formatters.currency(totalBalance - totalDebt)}',
                                        style: TextStyle(
                                            color: PesowiseColors.white.withOpacity(0.75),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        _summaryChip(LucideIcons.arrowDownLeft,
                                            'Income', Formatters.currency(monthlyIncome)),
                                        const SizedBox(width: 10),
                                        _summaryChip(LucideIcons.arrowUpRight,
                                            'Expenses', Formatters.currency(monthlyExpenses)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Wallets row
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('My Wallets',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: PesowiseColors.strong)),
                                    Text('${wallets.length} wallet${wallets.length == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: PesowiseColors.muted,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (wallets.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text('No wallets yet — add one in the Wallets tab.',
                                      style: TextStyle(color: PesowiseColors.muted, fontSize: 13)),
                                )
                              else
                                SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: wallets.length,
                                    itemBuilder: (context, i) {
                                      final isSelected = wallets[i].id == _selectedWalletId;
                                      return GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedWalletId = wallets[i].id),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 150,
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? PesowiseColors.strong
                                                : PesowiseColors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                                color: isSelected
                                                    ? PesowiseColors.strong
                                                    : PesowiseColors.blushBorder),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(wallets[i].name,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected
                                                          ? PesowiseColors.white
                                                          : PesowiseColors.muted)),
                                              Text(Formatters.currency(wallets[i].balance),
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: isSelected
                                                          ? PesowiseColors.white
                                                          : PesowiseColors.strong)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              const SizedBox(height: 24),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text('Recent · $selectedWalletName',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: PesowiseColors.strong)),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        if (filteredTx.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text('No transactions for this wallet.',
                                  style: TextStyle(
                                      color: PesowiseColors.muted, fontSize: 13)),
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
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PesowiseColors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PesowiseColors.white),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: PesowiseColors.white,
                      fontWeight: FontWeight.w500)),
              Text(amount,
                  style: const TextStyle(
                      fontSize: 12,
                      color: PesowiseColors.white,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}