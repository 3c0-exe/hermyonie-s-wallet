import 'package:flutter/material.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../services/jam_service.dart';

class AddJamPersonScreen extends StatefulWidget {
  final String sessionId;
  final String? existingPersonId;
  final String? existingPersonName;
  final bool isOwner;

  const AddJamPersonScreen({
    super.key,
    required this.sessionId,
    this.existingPersonId,
    this.existingPersonName,
    this.isOwner = false,
  });

  @override
  State<AddJamPersonScreen> createState() => _AddJamPersonScreenState();
}

class _AddJamPersonScreenState extends State<AddJamPersonScreen> {
  final _nameController = TextEditingController();
  final List<_ExpenseRow> _rows = [];

  bool get _isEditing => widget.existingPersonId != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingPersonName != null) {
      _nameController.text = widget.existingPersonName!;
    }
    _rows.add(_ExpenseRow());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final r in _rows) {
      r.desc.dispose();
      r.amount.dispose();
    }
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (!_isEditing && name.isEmpty) return;

    final valid = _rows.where((r) {
      final d = r.desc.text.trim();
      final a = double.tryParse(r.amount.text.trim());
      return d.isNotEmpty && a != null && a > 0;
    }).toList();

    if (valid.isEmpty) return;

    String personId = widget.existingPersonId ?? '';
    if (!_isEditing) {
      personId = await JamService.addPerson(widget.sessionId, name);
    }

    for (final r in valid) {
      await JamService.addExpense(
        personId,
        widget.sessionId,
        r.desc.text.trim(),
        double.parse(r.amount.text.trim()),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? 'Add Expenses${widget.isOwner ? ' for Me' : ' for ${widget.existingPersonName}'}'
        : 'New Person';

    return Scaffold(
      backgroundColor: PesowiseColors.background,
      appBar: AppBar(
        backgroundColor: PesowiseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(WalletIcons.arrowLeft, color: PesowiseColors.strong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
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
            // Name field (only for new person)
            if (!_isEditing) ...[
              _label('Name'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: PesowiseColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PesowiseColors.blushBorder),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: PesowiseColors.strong,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Anna, Bea, Carlo',
                    hintStyle: TextStyle(color: PesowiseColors.muted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _label('Expenses'),
            const SizedBox(height: 10),

            // Expense rows
            ...List.generate(_rows.length, (i) {
              final row = _rows[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PesowiseColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PesowiseColors.blushBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: row.desc,
                        style: const TextStyle(
                          color: PesowiseColors.strong,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Description',
                          hintStyle: TextStyle(
                            color: PesowiseColors.muted,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: PesowiseColors.blushBorder,
                    ),
                    const Text(
                      '₱',
                      style: TextStyle(
                        color: PesowiseColors.strong,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: row.amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: PesowiseColors.strong,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: PesowiseColors.muted,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_rows.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _rows.removeAt(i)),
                        child: const Icon(
                          WalletIcons.x,
                          size: 15,
                          color: PesowiseColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Add another expense
            GestureDetector(
              onTap: () => setState(() => _rows.add(_ExpenseRow())),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: PesowiseColors.chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PesowiseColors.blushBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      WalletIcons.plusCircle,
                      size: 14,
                      color: PesowiseColors.accent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add another expense',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PesowiseColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                child: Text(
                  _isEditing ? 'Save Expenses' : 'Add Person',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: PesowiseColors.muted,
    ),
  );
}

class _ExpenseRow {
  final desc = TextEditingController();
  final amount = TextEditingController();
}
