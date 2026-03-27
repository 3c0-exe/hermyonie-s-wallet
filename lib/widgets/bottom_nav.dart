import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class PesowiseBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PesowiseBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PesowiseColors.white,
        border: Border(top: BorderSide(color: PesowiseColors.blushBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: LucideIcons.wallet, label: 'Wallets', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: LucideIcons.list, label: 'Transactions', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: LucideIcons.barChart2, label: 'Reports', index: 3, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? PesowiseColors.strong : PesowiseColors.muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? PesowiseColors.strong : PesowiseColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: const BoxDecoration(
                color: PesowiseColors.strong,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}