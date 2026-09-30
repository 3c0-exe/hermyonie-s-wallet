import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

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
                    'Transactions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: PesowiseColors.strong,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen(),
                      ),
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
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Transaction>(
                    HiveBoxes.transactions,
                  ).listenable(),
                  builder: (context, box, _) {
                    final transactions = TransactionService.getAll();
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              WalletIcons.receipt,
                              size: 48,
                              color: PesowiseColors.accent,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: PesowiseColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap + to log your first transaction',
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
                      itemCount: transactions.length,
                      itemBuilder: (context, i) => TransactionTile(
                        transaction: transactions[i],
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: PesowiseColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Delete transaction?',
                                style: TextStyle(
                                  color: PesowiseColors.strong,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: const Text(
                                'This will also reverse the wallet balance.',
                                style: TextStyle(color: PesowiseColors.muted),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: PesowiseColors.muted,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: PesowiseColors.strong,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await TransactionService.delete(transactions[i].id);
                          }
                        },
                      ),
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
