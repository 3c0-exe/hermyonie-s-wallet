import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../utils/formatters.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PesowiseColors.background,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable:
              Hive.box<Transaction>(HiveBoxes.transactions).listenable(),
          builder: (context, box, _) {
            final spending = TransactionService.getSpendingByCategory();
            final allTx = TransactionService.getAll();

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

            final sorted = spending.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final total =
                sorted.fold(0.0, (sum, e) => sum + e.value);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reports',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: PesowiseColors.strong)),
                        Text(Formatters.monthYear(DateTime.now()),
                            style: const TextStyle(
                                fontSize: 13,
                                color: PesowiseColors.muted,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),

                        // Summary row
                        Row(
                          children: [
                            Expanded(
                                child: _summaryCard(
                                    'Income', monthlyIncome, LucideIcons.arrowDownLeft)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _summaryCard(
                                    'Expenses', monthlyExpenses, LucideIcons.arrowUpRight)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _summaryCard(
                            'Net', monthlyIncome - monthlyExpenses, LucideIcons.trendingUp,
                            fullWidth: true),
                        const SizedBox(height: 24),

                        const Text('Spending by Category',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: PesowiseColors.strong)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (sorted.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('No expense data yet.',
                          style: TextStyle(
                              color: PesowiseColors.muted, fontSize: 13)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final entry = sorted[i];
                          final percent =
                              total > 0 ? entry.value / total : 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: PesowiseColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: PesowiseColors.blushBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: PesowiseColors.strong)),
                                    Text(Formatters.currency(entry.value),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: PesowiseColors.strong)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    minHeight: 6,
                                    backgroundColor: PesowiseColors.chipBg,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            PesowiseColors.accent),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${(percent * 100).toStringAsFixed(1)}% of total spending',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: PesowiseColors.muted,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        },
                        childCount: sorted.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double amount, IconData icon,
      {bool fullWidth = false}) {
    final isNegative = amount < 0;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PesowiseColors.blushBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: PesowiseColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: PesowiseColors.strong),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: PesowiseColors.muted,
                      fontWeight: FontWeight.w600)),
              Text(Formatters.currency(amount.abs()),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isNegative
                          ? PesowiseColors.strong
                          : PesowiseColors.strong)),
            ],
          ),
        ],
      ),
    );
  }
}