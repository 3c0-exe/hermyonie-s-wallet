import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/debt.dart';
import '../../services/debt_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/formatters.dart';
import 'add_debt_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PesowiseColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debts & To Pay',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: PesowiseColors.strong,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDebtScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PesowiseColors.strong,
                        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 4),
              ValueListenableBuilder(
                valueListenable: Hive.box<Debt>(HiveBoxes.debts).listenable(),
                builder: (context, box, _) {
                  final total = DebtService.getTotalDebt();
                  return Text(
                    'Total owed: ${Formatters.currency(total)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: PesowiseColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Debt>(HiveBoxes.debts).listenable(),
                  builder: (context, box, _) {
                    final debts = DebtService.getAll();
                    if (debts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              WalletIcons.checkCircle2,
                              size: 48,
                              color: PesowiseColors.accent,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "You're all clear!",
                              style: TextStyle(
                                color: PesowiseColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'No unpaid debts',
                              style: TextStyle(
                                color: PesowiseColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: debts.length,
                      itemBuilder: (context, i) =>
                          _DebtTile(debt: debts[i], context: context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final BuildContext context;

  const _DebtTile({required this.debt, required this.context});

  bool get _isOverdue {
    if (debt.dueDate == null) return false;
    return debt.dueDate!.isBefore(DateTime.now());
  }

  String get _walletName {
    final wallets = WalletService.getAll();
    return wallets
            .where((w) => w.id == debt.walletId)
            .map((w) => w.name)
            .firstOrNull ??
        '—';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOverdue
              ? PesowiseColors.strong
              : PesowiseColors.blushBorder,
          width: _isOverdue ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: PesowiseColors.chipBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    debt.isRecurring
                        ? WalletIcons.repeat
                        : WalletIcons.alertCircle,
                    color: PesowiseColors.strong,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              debt.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: PesowiseColors.strong,
                              ),
                            ),
                          ),
                          if (debt.isRecurring)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: PesowiseColors.chipBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: PesowiseColors.strong,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        debt.creditor,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PesowiseColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.currency(debt.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: PesowiseColors.strong,
                  ),
                ),
              ],
            ),

            // Meta row
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  WalletIcons.wallet,
                  size: 12,
                  color: PesowiseColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  _walletName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: PesowiseColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (debt.dueDate != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    WalletIcons.calendar,
                    size: 12,
                    color: _isOverdue
                        ? PesowiseColors.strong
                        : PesowiseColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isOverdue
                        ? 'Overdue · ${Formatters.date(debt.dueDate!)}'
                        : 'Due ${Formatters.date(debt.dueDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isOverdue
                          ? PesowiseColors.strong
                          : PesowiseColors.muted,
                    ),
                  ),
                ],
              ],
            ),

            if (debt.note != null && debt.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                debt.note!,
                style: const TextStyle(
                  fontSize: 11,
                  color: PesowiseColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: PesowiseColors.blushBorder, height: 1),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: PesowiseColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Mark as paid?',
                            style: TextStyle(
                              color: PesowiseColors.strong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Text(
                            '${Formatters.currency(debt.amount)} will be logged as an expense from $_walletName.',
                            style: const TextStyle(color: PesowiseColors.muted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: PesowiseColors.muted),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Mark Paid',
                                style: TextStyle(color: PesowiseColors.strong),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DebtService.markAsPaid(debt.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: PesowiseColors.strong,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            WalletIcons.checkCircle2,
                            size: 14,
                            color: PesowiseColors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Mark as Paid',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: PesowiseColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: PesowiseColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Delete debt?',
                          style: TextStyle(
                            color: PesowiseColors.strong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: const Text(
                          'This removes the debt without logging a transaction.',
                          style: TextStyle(color: PesowiseColors.muted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: PesowiseColors.muted),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: PesowiseColors.strong),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await DebtService.delete(debt.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: PesowiseColors.chipBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      WalletIcons.trash2,
                      size: 15,
                      color: PesowiseColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
