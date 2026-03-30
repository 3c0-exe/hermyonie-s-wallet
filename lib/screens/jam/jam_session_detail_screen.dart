import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/jam_session.dart';
import '../../models/jam_person.dart';
import '../../models/jam_expense.dart';
import '../../services/jam_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/formatters.dart';
import 'add_jam_person_screen.dart';

class JamSessionDetailScreen extends StatelessWidget {
  final String sessionId;
  const JamSessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<JamSession>(HiveBoxes.jamSessions).listenable(),
      builder: (context, _, __) => ValueListenableBuilder(
        valueListenable: Hive.box<JamPerson>(HiveBoxes.jamPersons).listenable(),
        builder: (context, _, __) => ValueListenableBuilder(
          valueListenable: Hive.box<JamExpense>(HiveBoxes.jamExpenses).listenable(),
          builder: (context, _, __) {
            final session =
                Hive.box<JamSession>(HiveBoxes.jamSessions).get(sessionId);
            if (session == null) {
              return const Scaffold(
                  body: Center(child: Text('Session not found')));
            }

            final persons   = JamService.getPersons(sessionId);
            final total     = JamService.getSessionTotal(sessionId);
            final fairShare = persons.isNotEmpty ? total / persons.length : 0.0;

            return Scaffold(
              backgroundColor: PesowiseColors.background,
              appBar: AppBar(
                backgroundColor: PesowiseColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft,
                      color: PesowiseColors.strong),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.name,
                        style: const TextStyle(
                            color: PesowiseColors.strong,
                            fontWeight: FontWeight.w700,
                            fontSize: 17)),
                    Text(Formatters.date(session.createdAt),
                        style: const TextStyle(
                            color: PesowiseColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                actions: [
                  if (!session.isSettled)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2,
                          color: PesowiseColors.muted, size: 18),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: PesowiseColors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete session?',
                                style: TextStyle(
                                    color: PesowiseColors.strong,
                                    fontWeight: FontWeight.w700)),
                            content: const Text(
                                'This will permanently delete all data for this session.',
                                style: TextStyle(color: PesowiseColors.muted)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel',
                                      style:
                                          TextStyle(color: PesowiseColors.muted))),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(
                                          color: PesowiseColors.strong))),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await JamService.deleteSession(sessionId);
                          Navigator.pop(context);
                        }
                      },
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Summary strip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: session.isSettled
                          ? PesowiseColors.blushCard
                          : PesowiseColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _Stat(label: 'Total',      value: Formatters.currency(total))),
                        Expanded(child: _Stat(label: 'Per Person', value: Formatters.currency(fairShare))),
                        Expanded(child: _Stat(label: 'People',     value: '${persons.length}')),
                      ],
                    ),
                  ),

                  if (session.isSettled) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: PesowiseColors.chipBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.checkCircle2,
                              size: 14, color: PesowiseColors.strong),
                          SizedBox(width: 8),
                          Text('This session has been settled',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: PesowiseColors.strong)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // People header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${persons.length} ${persons.length == 1 ? 'Person' : 'People'}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PesowiseColors.strong)),
                      if (!session.isSettled)
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddJamPersonScreen(
                                      sessionId: sessionId))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: PesowiseColors.strong,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.userPlus,
                                    size: 13, color: PesowiseColors.white),
                                SizedBox(width: 6),
                                Text('Add Person',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: PesowiseColors.white)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Person cards
                  ...persons.map((p) => _PersonCard(
                        person: p,
                        sessionId: sessionId,
                        isSettled: session.isSettled,
                      )),

                  const SizedBox(height: 8),

                  // Settle button
                  if (!session.isSettled && persons.length >= 2 && total > 0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _SettleSheet(
                            sessionId: sessionId,
                            fairShare: fairShare,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PesowiseColors.strong,
                          foregroundColor: PesowiseColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Settle Up 🌸',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Person Card ──────────────────────────────────────────────────────────────
class _PersonCard extends StatelessWidget {
  final JamPerson person;
  final String sessionId;
  final bool isSettled;
  const _PersonCard({required this.person, required this.sessionId, required this.isSettled});

  @override
  Widget build(BuildContext context) {
    final expenses = JamService.getExpensesForPerson(person.id);
    final total    = JamService.getTotalPaidByPerson(person.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PesowiseColors.blushBorder),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: person.isOwner
                        ? PesowiseColors.strong
                        : PesowiseColors.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      person.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: person.isOwner
                              ? PesowiseColors.white
                              : PesowiseColors.strong),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.isOwner ? '${person.name} (you)' : person.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: PesowiseColors.strong)),
                      Text(
                          '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: PesowiseColors.muted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Text(Formatters.currency(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: PesowiseColors.strong)),
                if (!isSettled && !person.isOwner) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: PesowiseColors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Remove person?',
                              style: TextStyle(
                                  color: PesowiseColors.strong,
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                              'Remove ${person.name} and all their expenses.',
                              style:
                                  const TextStyle(color: PesowiseColors.muted)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        color: PesowiseColors.muted))),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove',
                                    style: TextStyle(
                                        color: PesowiseColors.strong))),
                          ],
                        ),
                      );
                      if (ok == true) await JamService.deletePerson(person.id);
                    },
                    child: const Icon(LucideIcons.userMinus,
                        size: 15, color: PesowiseColors.muted),
                  ),
                ],
              ],
            ),
          ),

          // Expense rows
          if (expenses.isNotEmpty) ...[
            const Divider(height: 1, color: PesowiseColors.blushBorder),
            ...expenses.map((e) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.receipt,
                          size: 13, color: PesowiseColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e.description,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: PesowiseColors.strong,
                                  fontWeight: FontWeight.w500))),
                      Text(Formatters.currency(e.amount),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PesowiseColors.strong)),
                      if (!isSettled) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => JamService.deleteExpense(e.id),
                          child: const Icon(LucideIcons.x,
                              size: 13, color: PesowiseColors.muted),
                        ),
                      ],
                    ],
                  ),
                )),
          ],

          // Add expenses button
          if (!isSettled) ...[
            const Divider(height: 1, color: PesowiseColors.blushBorder),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddJamPersonScreen(
                            sessionId: sessionId,
                            existingPersonId:   person.id,
                            existingPersonName: person.name,
                            isOwner: person.isOwner,
                          ))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.plusCircle,
                        size: 13, color: PesowiseColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      expenses.isEmpty
                          ? 'Add expenses'
                          : 'Add more expenses',
                      style: const TextStyle(
                          fontSize: 12,
                          color: PesowiseColors.accent,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stat widget ───────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: PesowiseColors.white.withOpacity(0.8))),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: PesowiseColors.white)),
      ],
    );
  }
}

// ── Settle bottom sheet ───────────────────────────────────────────────────────
class _SettleSheet extends StatefulWidget {
  final String sessionId;
  final double fairShare;
  const _SettleSheet({required this.sessionId, required this.fairShare});

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  bool _showBreakdown = false;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    final wallets = WalletService.getAll();
    if (wallets.isNotEmpty) _selectedWalletId = wallets.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final transfers = JamService.calculateSettlement(widget.sessionId);
    final summaries = JamService.getPersonSummaries(widget.sessionId);
    final wallets   = WalletService.getAll();

    return Container(
      decoration: const BoxDecoration(
        color: PesowiseColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: PesowiseColors.blushBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Settle Up 🌸',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PesowiseColors.strong)),
            const SizedBox(height: 4),
            Text('${Formatters.currency(widget.fairShare)} per person',
                style: const TextStyle(
                    fontSize: 13,
                    color: PesowiseColors.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            // Simplified transfers
            const Text('Who pays who:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PesowiseColors.muted)),
            const SizedBox(height: 10),

            if (transfers.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: PesowiseColors.chipBg,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(LucideIcons.checkCircle2,
                        size: 14, color: PesowiseColors.strong),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Everyone paid equally — no transfers needed!',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PesowiseColors.strong)),
                    ),
                  ],
                ),
              )
            else
              ...transfers.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: PesowiseColors.chipBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(t.from,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: PesowiseColors.strong)),
                        ),
                        const Icon(LucideIcons.arrowRight,
                            size: 14, color: PesowiseColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t.to,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: PesowiseColors.strong)),
                        ),
                        Text(Formatters.currency(t.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: PesowiseColors.strong)),
                      ],
                    ),
                  )),

            const SizedBox(height: 12),

            // Full breakdown toggle
            GestureDetector(
              onTap: () => setState(() => _showBreakdown = !_showBreakdown),
              child: Row(
                children: [
                  Text(
                    _showBreakdown ? 'Hide breakdown' : 'View full breakdown',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PesowiseColors.accent),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showBreakdown
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14, color: PesowiseColors.accent,
                  ),
                ],
              ),
            ),

            if (_showBreakdown) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: PesowiseColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PesowiseColors.blushBorder),
                ),
                child: Column(
                  children: [
                    // Table header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: const [
                          Expanded(flex: 2, child: Text('Name',    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PesowiseColors.muted))),
                          Expanded(         child: Text('Paid',    textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PesowiseColors.muted))),
                          Expanded(         child: Text('Share',   textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PesowiseColors.muted))),
                          Expanded(         child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PesowiseColors.muted))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: PesowiseColors.blushBorder),
                    ...summaries.map((s) {
                      final balStr = s.balance >= 0
                          ? '+${Formatters.currency(s.balance)}'
                          : '-${Formatters.currency(s.balance.abs())}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                  s.person.isOwner
                                      ? '${s.person.name} (you)'
                                      : s.person.name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: PesowiseColors.strong)),
                            ),
                            Expanded(
                              child: Text(Formatters.currency(s.totalPaid),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: PesowiseColors.strong)),
                            ),
                            Expanded(
                              child: Text(Formatters.currency(s.fairShare),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: PesowiseColors.strong)),
                            ),
                            Expanded(
                              child: Text(balStr,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: s.balance >= 0
                                          ? const Color(0xFF7EBD8B)
                                          : PesowiseColors.strong)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Wallet selector
            const Text('Log my share to:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PesowiseColors.muted)),
            const SizedBox(height: 8),
            if (wallets.isEmpty)
              const Text('Please add a wallet first.',
                  style: TextStyle(color: PesowiseColors.muted, fontSize: 13))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: PesowiseColors.background,
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
                        fontWeight: FontWeight.w600),
                    items: wallets
                        .map((w) => DropdownMenuItem(
                            value: w.id, child: Text(w.name)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedWalletId = val),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedWalletId == null
                    ? null
                    : () async {
                        await JamService.settleSession(
                            widget.sessionId, _selectedWalletId!);
                        if (context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PesowiseColors.strong,
                  foregroundColor: PesowiseColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Confirm & Settle',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}