import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../models/wallet.dart';
import '../../services/transaction_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/categories.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isExpense = true;
  String? _selectedWalletId;
  String _selectedCategory = 'Food & Drink';
  DateTime _selectedDate = DateTime.now();

  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _wallets = WalletService.getAll();
    if (_wallets.isNotEmpty) _selectedWalletId = _wallets.first.id;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: PesowiseColors.strong,
            onPrimary: PesowiseColors.white,
            surface: PesowiseColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    final label = _labelController.text.trim();
    final amountText = _amountController.text.trim();

    if (label.isEmpty || amountText.isEmpty || _selectedWalletId == null) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    await TransactionService.add(
      walletId: _selectedWalletId!,
      label: label,
      amount: amount,
      isExpense: _isExpense,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _isExpense ? Categories.expense : Categories.income;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      backgroundColor: PesowiseColors.background,
      appBar: AppBar(
        backgroundColor: PesowiseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: PesowiseColors.strong),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Transaction',
            style: TextStyle(
                color: PesowiseColors.strong,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expense / Income toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: PesowiseColors.blushCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _toggleBtn('Expense', true),
                  _toggleBtn('Income', false),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _label('Amount'),
            const SizedBox(height: 8),
            _input(_amountController, '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: '₱ '),
            const SizedBox(height: 16),

            _label('Description'),
            const SizedBox(height: 8),
            _input(_labelController, 'e.g. Grab ride, Salary'),
            const SizedBox(height: 16),

            _label('Wallet'),
            const SizedBox(height: 8),
            _dropdown(),
            const SizedBox(height: 16),

            _label('Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? PesowiseColors.strong : PesowiseColors.chipBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? PesowiseColors.strong : PesowiseColors.blushBorder,
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? PesowiseColors.white : PesowiseColors.strong)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _label('Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: PesowiseColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PesowiseColors.blushBorder),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar,
                        size: 16, color: PesowiseColors.muted),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                          color: PesowiseColors.strong, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label('Note (optional)'),
            const SizedBox(height: 8),
            _input(_noteController, 'Add a note...', maxLines: 2),
            const SizedBox(height: 28),

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
                child: const Text('Save Transaction',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isExpense) {
    final isActive = _isExpense == isExpense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = isExpense),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? PesowiseColors.strong : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isActive ? PesowiseColors.white : PesowiseColors.muted)),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PesowiseColors.blushBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWalletId,
          isExpanded: true,
          dropdownColor: PesowiseColors.white,
          style: const TextStyle(
              color: PesowiseColors.strong, fontWeight: FontWeight.w600),
          items: _wallets.map((w) => DropdownMenuItem(
            value: w.id,
            child: Text(w.name),
          )).toList(),
          onChanged: (val) => setState(() => _selectedWalletId = val),
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
      {TextInputType? keyboardType, String? prefix, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PesowiseColors.blushBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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