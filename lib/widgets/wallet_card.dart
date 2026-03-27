import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/wallet.dart';
import '../utils/formatters.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PesowiseColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PesowiseColors.blushBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PesowiseColors.chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(wallet.icon), color: PesowiseColors.strong, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: PesowiseColors.strong)),
                  const SizedBox(height: 2),
                  Text('Balance',
                      style: const TextStyle(
                          fontSize: 12,
                          color: PesowiseColors.muted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.currency(wallet.balance),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: PesowiseColors.strong)),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(LucideIcons.trash2,
                          size: 14, color: PesowiseColors.muted),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'wallet': return LucideIcons.wallet;
      case 'smartphone': return LucideIcons.smartphone;
      case 'building': return LucideIcons.building2;
      case 'piggy-bank': return LucideIcons.piggyBank;
      case 'credit-card': return LucideIcons.creditCard;
      default: return LucideIcons.wallet;
    }
  }
}