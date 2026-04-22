import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PesowiseColors.blushBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PesowiseColors.chipBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_getCategoryIcon(transaction.category),
                color: PesowiseColors.strong, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: PesowiseColors.strong)),
                const SizedBox(height: 2),
Text('${transaction.category} · ${Formatters.date(transaction.date)}',
    style: const TextStyle(
        fontSize: 12,
        color: PesowiseColors.muted,
        fontWeight: FontWeight.w500)),
if (transaction.note != null && transaction.note!.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(transaction.note!,
        style: const TextStyle(
            fontSize: 11,
            color: PesowiseColors.muted,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic)),
  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isExpense ? '-' : '+'}${Formatters.currency(transaction.amount)}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: transaction.isExpense
                        ? PesowiseColors.strong
                        : const Color(0xFF7EBD8B)),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(LucideIcons.trash2,
                        size: 13, color: PesowiseColors.muted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Drink': return LucideIcons.coffee;
      case 'Transport': return LucideIcons.car;
      case 'Shopping': return LucideIcons.shoppingBag;
      case 'Bills & Utilities': return LucideIcons.zap;
      case 'Health': return LucideIcons.heart;
      case 'Entertainment': return LucideIcons.music;
      case 'Education': return LucideIcons.book;
      case 'Personal Care': return LucideIcons.smile;
      case 'Salary': return LucideIcons.briefcase;
      case 'Freelance': return LucideIcons.monitor;
      case 'Gift': return LucideIcons.gift;
      case 'Savings': return LucideIcons.piggyBank;
      default: return LucideIcons.circle;
    }
  }
}