import 'package:flutter/material.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../services/assistant_service.dart';
import 'components.dart';
import 'settings_screen.dart';
import 'forms.dart';

class AssistantSheet extends StatefulWidget {
  const AssistantSheet({super.key});
  @override
  State<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<AssistantSheet> {
  final _text = TextEditingController();
  Map<String, dynamic>? _plan;
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _plan = null;
    });
    try {
      final plan = await AssistantService.prepare(_text.text);
      if (mounted) setState(() => _plan = plan);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Could not prepare that action.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    if (_busy || _plan == null) return;
    setState(() => _busy = true);
    try {
      await AssistantService.apply(_plan!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved. You can undo transactions in Activity.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Could not save that action.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionable =
        _plan != null &&
        !['show_summary', 'clarify'].contains(_plan!['action']);
    return FormSheet(
      title: 'A little help with money.',
      subtitle:
          'Tell me what to track. You’ll review changes before they’re saved.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Panel(
            color: PesowiseColors.chipBg,
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(WalletIcons.sparkles, color: PesowiseColors.strong),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Try: “Create an Atome card with a ₱5,000 personal cap. I currently owe ₱1,800.”',
                    style: TextStyle(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in [
                'Create an Atome card',
                'Log an expense',
                'Show my balances',
              ])
                ActionChip(
                  label: Text(example),
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _text.text = switch (example) {
                            'Create an Atome card' =>
                              'Create an Atome credit account with a 5000 personal cap and 1800 currently owed.',
                            'Log an expense' =>
                              'Record a 150 peso lunch expense from GCash.',
                            _ => 'Show my balances.',
                          };
                          _plan = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _text,
            maxLines: 4,
            maxLength: 2000,
            enabled: !_busy,
            onChanged: (_) => setState(() => _plan = null),
            decoration: const InputDecoration(
              labelText: 'What would you like to do?',
              hintText: 'Use your account’s exact name.',
            ),
          ),
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB14128), height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: _busy ? null : _prepare,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(WalletIcons.sparkles, size: 18),
            label: Text(_busy ? 'Working…' : 'Prepare preview'),
          ),
          if (_plan != null) ...[
            const SectionTitle('Review your request'),
            Panel(
              child: Text(
                AssistantService.describe(_plan!),
                style: const TextStyle(height: 1.8),
              ),
            ),
            if (actionable) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _busy ? null : _apply,
                child: const Text('Confirm & save'),
              ),
            ],
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy
                ? null
                : () => openSheet(context, const AssistantAccessSheet()),
            child: const Text('Assistant connection settings'),
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'No assistant connection yet?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manual entries work without an API key.',
            style: TextStyle(color: PesowiseColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              final parent = Navigator.of(context).context;
              Navigator.pop(context);
              openSheet(parent, const ActionSheet());
            },
            child: const Text('Add an entry manually'),
          ),
        ],
      ),
    );
  }
}
