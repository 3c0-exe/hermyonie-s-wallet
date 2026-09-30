import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../core/hive_boxes.dart';
import '../../models/jam_session.dart';
import '../../services/jam_service.dart';
import '../../utils/formatters.dart';
import 'jam_session_detail_screen.dart';

class JamSessionsScreen extends StatelessWidget {
  const JamSessionsScreen({super.key});

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
          'Jam Sessions',
          style: TextStyle(
            color: PesowiseColors.strong,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _createSession(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PesowiseColors.strong,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  WalletIcons.plus,
                  color: PesowiseColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<JamSession>(
          HiveBoxes.jamSessions,
        ).listenable(),
        builder: (context, box, _) {
          final sessions = JamService.getAllSessions();
          final active = sessions.where((s) => !s.isSettled).toList();
          final settled = sessions.where((s) => s.isSettled).toList();

          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    WalletIcons.users,
                    size: 48,
                    color: PesowiseColors.accent,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No jam sessions yet',
                    style: TextStyle(
                      color: PesowiseColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap + to start splitting bills',
                    style: TextStyle(color: PesowiseColors.muted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (active.isNotEmpty) ...[
                const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PesowiseColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                ...active.map((s) => _SessionTile(session: s)),
                const SizedBox(height: 20),
              ],
              if (settled.isNotEmpty) ...[
                const Text(
                  'Settled',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PesowiseColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                ...settled.map((s) => _SessionTile(session: s)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _createSession(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PesowiseColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'New Session',
          style: TextStyle(
            color: PesowiseColors.strong,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: PesowiseColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PesowiseColors.blushBorder),
          ),
          child: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(
              color: PesowiseColors.strong,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. SM North hangout',
              hintStyle: TextStyle(color: PesowiseColors.muted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: PesowiseColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final id = await JamService.createSession(name);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JamSessionDetailScreen(sessionId: id),
                  ),
                );
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(color: PesowiseColors.strong),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final JamSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final total = JamService.getSessionTotal(session.id);
    final personCount = JamService.getPersons(session.id).length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JamSessionDetailScreen(sessionId: session.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PesowiseColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PesowiseColors.blushBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: session.isSettled
                    ? PesowiseColors.blushCard
                    : PesowiseColors.chipBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                session.isSettled
                    ? WalletIcons.checkCircle2
                    : WalletIcons.users,
                color: PesowiseColors.strong,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: PesowiseColors.strong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.date(session.createdAt)} · $personCount ${personCount == 1 ? 'person' : 'people'}',
                    style: const TextStyle(
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
                  Formatters.currency(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: PesowiseColors.strong,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: session.isSettled
                        ? PesowiseColors.blushCard
                        : PesowiseColors.chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.isSettled ? 'Settled' : 'Active',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PesowiseColors.strong,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
