import 'package:flutter/material.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../core/theme.dart';
import '../models/wallet.dart';
import '../utils/formatters.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
    this.onDelete,
    this.onEdit,
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
              child: Icon(
                _getIcon(wallet.icon),
                color: PesowiseColors.strong,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: PesowiseColors.strong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: PesowiseColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(wallet.balance),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: PesowiseColors.strong,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4, right: 10),
                          child: Icon(
                            WalletIcons.pencil,
                            size: 14,
                            color: PesowiseColors.muted,
                          ),
                        ),
                      ),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            WalletIcons.trash2,
                            size: 14,
                            color: PesowiseColors.muted,
                          ),
                        ),
                      ),
                  ],
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
      case 'wallet':
        return WalletIcons.wallet;
      case 'smartphone':
        return WalletIcons.smartphone;
      case 'building':
        return WalletIcons.building2;
      case 'piggy-bank':
        return WalletIcons.piggyBank;
      case 'credit-card':
        return WalletIcons.creditCard;
      default:
        return WalletIcons.wallet;
    }
  }
}
