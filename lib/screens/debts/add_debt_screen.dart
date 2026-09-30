import 'package:flutter/material.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../services/debt_service.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  final _creditorController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _dueDate;
  bool _isRecurring = false;
  String? _selectedWalletId;
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _wallets = WalletService.getAll();
    if (_wallets.isNotEmpty) _selectedWalletId = _wallets.first.id;
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
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
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() async {
    final label = _labelController.text.trim();
    final creditor = _creditorController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (label.isEmpty ||
        creditor.isEmpty ||
        amount == null ||
        amount <= 0 ||
        _selectedWalletId == null) {
      return;
    }

    await DebtService.add(
      label: label,
      amount: amount,
      creditor: creditor,
      walletId: _selectedWalletId!,
      dueDate: _dueDate,
      isRecurring: _isRecurring,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

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
          icon: const Icon(WalletIcons.arrowLeft, color: PesowiseColors.strong),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Debt',
          style: TextStyle(
            color: PesowiseColors.strong,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('What is it?'),
            const SizedBox(height: 8),
            _input(
              _labelController,
              'e.g. Electricity bill, SPayLater balance',
            ),
            const SizedBox(height: 16),

            _label('Creditor / Source'),
            const SizedBox(height: 8),
            _input(_creditorController, 'e.g. Meralco, SPayLater, TikTok Shop'),
            const SizedBox(height: 16),

            _label('Amount Owed'),
            const SizedBox(height: 8),
            _input(
              _amountController,
              '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefix: '₱ ',
            ),
            const SizedBox(height: 16),

            _label('Pay from Wallet'),
            const SizedBox(height: 8),
            _dropdown(),
            const SizedBox(height: 16),

            _label('Due Date (optional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: PesowiseColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PesowiseColors.blushBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      WalletIcons.calendar,
                      size: 16,
                      color: PesowiseColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null
                          ? 'Pick a due date'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: TextStyle(
                        color: _dueDate == null
                            ? PesowiseColors.muted
                            : PesowiseColors.strong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(
                          WalletIcons.x,
                          size: 14,
                          color: PesowiseColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: PesowiseColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PesowiseColors.blushBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    WalletIcons.repeat,
                    size: 16,
                    color: PesowiseColors.muted,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recurring monthly',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: PesowiseColors.strong,
                          ),
                        ),
                        Text(
                          'e.g. monthly subscription, utility bill',
                          style: TextStyle(
                            fontSize: 11,
                            color: PesowiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                    activeThumbColor: PesowiseColors.strong,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _label('Notes (optional)'),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Debt',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
            color: PesowiseColors.strong,
            fontWeight: FontWeight.w600,
          ),
          items: _wallets
              .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
              .toList(),
          onChanged: (val) => setState(() => _selectedWalletId = val),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: PesowiseColors.muted,
    ),
  );

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? prefix,
    int maxLines = 1,
  }) {
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
          color: PesowiseColors.strong,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: PesowiseColors.strong,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: const TextStyle(color: PesowiseColors.muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
