import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../services/wallet_service.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedIcon = 'wallet';

  final _icons = const [
    ('wallet', LucideIcons.wallet),
    ('smartphone', LucideIcons.smartphone),
    ('building', LucideIcons.building2),
    ('piggy-bank', LucideIcons.piggyBank),
    ('credit-card', LucideIcons.creditCard),
  ];

  void _save() async {
    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();

    if (name.isEmpty) return;

    final balance = double.tryParse(balanceText) ?? 0.0;
    await WalletService.add(name, _selectedIcon, balance);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PesowiseColors.background,
      appBar: AppBar(
        backgroundColor: PesowiseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: PesowiseColors.strong),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Wallet',
            style: TextStyle(
                color: PesowiseColors.strong,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Wallet Name'),
            const SizedBox(height: 8),
            _input(_nameController, 'e.g. GCash, BPI, Cash'),
            const SizedBox(height: 20),
            _label('Starting Balance'),
            const SizedBox(height: 8),
            _input(_balanceController, '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: '₱ '),
            const SizedBox(height: 20),
            _label('Icon'),
            const SizedBox(height: 12),
            Row(
              children: _icons.map((entry) {
                final isSelected = _selectedIcon == entry.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = entry.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 12),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? PesowiseColors.strong : PesowiseColors.chipBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? PesowiseColors.strong : PesowiseColors.blushBorder,
                      ),
                    ),
                    child: Icon(entry.$2,
                        color: isSelected ? PesowiseColors.white : PesowiseColors.strong,
                        size: 22),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PesowiseColors.strong,
                  foregroundColor: PesowiseColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Add Wallet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: PesowiseColors.muted));

  Widget _input(TextEditingController controller, String hint,
      {TextInputType? keyboardType, String? prefix}) {
    return Container(
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PesowiseColors.blushBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
            color: PesowiseColors.strong, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          prefixStyle: const TextStyle(
              color: PesowiseColors.strong, fontWeight: FontWeight.w600),
          hintStyle: const TextStyle(color: PesowiseColors.muted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}