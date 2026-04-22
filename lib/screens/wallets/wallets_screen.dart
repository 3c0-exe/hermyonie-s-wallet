import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/wallet.dart';
import '../../services/wallet_service.dart';
import '../../widgets/wallet_card.dart';
import '../../utils/formatters.dart';
import 'add_wallet_screen.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

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
                  const Text('My Wallets',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: PesowiseColors.strong)),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AddWalletScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PesowiseColors.strong,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.plus,
                          color: PesowiseColors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Total balance pill
              ValueListenableBuilder(
                valueListenable: Hive.box<Wallet>(HiveBoxes.wallets).listenable(),
                builder: (context, box, _) {
                  final total = WalletService.getTotalBalance();
                  return Text('Total: ${Formatters.currency(total)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: PesowiseColors.muted,
                          fontWeight: FontWeight.w600));
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<Wallet>(HiveBoxes.wallets).listenable(),
                  builder: (context, box, _) {
                    final wallets = WalletService.getAll();
                    if (wallets.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.wallet,
                                size: 48, color: PesowiseColors.accent),
                            const SizedBox(height: 12),
                            const Text('No wallets yet',
                                style: TextStyle(
                                    color: PesowiseColors.muted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('Tap + to add your first wallet',
                                style: TextStyle(
                                    color: PesowiseColors.muted,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }
return ListView.builder(
  itemCount: wallets.length,
  itemBuilder: (context, i) => WalletCard(
    wallet: wallets[i],
    onEdit: () async {
      final controller = TextEditingController(
          text: wallets[i].balance.toStringAsFixed(2));
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: PesowiseColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Balance',
              style: TextStyle(
                  color: PesowiseColors.strong,
                  fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(
                color: PesowiseColors.strong,
                fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: const TextStyle(
                  color: PesowiseColors.strong,
                  fontWeight: FontWeight.w600),
              hintStyle:
                  const TextStyle(color: PesowiseColors.muted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: PesowiseColors.blushBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: PesowiseColors.strong),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style:
                        TextStyle(color: PesowiseColors.muted))),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save',
                    style: TextStyle(
                        color: PesowiseColors.strong,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      );
      if (confirmed == true) {
        final newBalance =
            double.tryParse(controller.text.trim());
        if (newBalance != null) {
          await WalletService.updateBalance(
              wallets[i].id, newBalance);
        }
      }
    },
    onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: PesowiseColors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Delete wallet?',
                                  style: TextStyle(
                                      color: PesowiseColors.strong,
                                      fontWeight: FontWeight.w700)),
                              content: Text(
                                  'This will delete "${wallets[i].name}" and all its data.',
                                  style: const TextStyle(color: PesowiseColors.muted)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel',
                                        style: TextStyle(color: PesowiseColors.muted))),
                                TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: PesowiseColors.strong))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await WalletService.delete(wallets[i].id);
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