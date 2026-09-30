import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hermyonies_girl_math/core/icons.dart';
import '../../core/theme.dart';
import '../../services/csv_service.dart';
import '../../services/google_drive_service.dart';
import '../../services/import_service.dart';
import '../../services/wallet_service.dart';
import '../../services/assistant_service.dart';
import '../jam/jam_sessions_screen.dart';
import 'components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings & connections')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const SectionTitle('Bring your money together'),
            const Panel(
              color: PesowiseColors.chipBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your accounts. Your control.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track GCash, Maya, Atome and bank accounts through entries and statement CSV imports. Live bank syncing is not connected.',
                    style: TextStyle(color: PesowiseColors.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              WalletIcons.upload,
              'Import transactions',
              'Preview a statement CSV and skip duplicates.',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              ),
            ),
            const SectionTitle('Your assistant'),
            _tile(
              context,
              WalletIcons.sparkles,
              'Assistant access',
              'Connect your configured Groq assistant.',
              () => openSheet(context, const AssistantAccessSheet()),
            ),
            const SectionTitle('Backups'),
            const Text(
              'Data stays on this browser or device. A backup is not automatic sync; clearing browser data removes local records.',
              style: TextStyle(color: PesowiseColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            _tile(
              context,
              WalletIcons.download,
              'Export backup',
              'Download all accounts, payments and shared expenses.',
              () async {
                try {
                  await CsvService.exportAll();
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
            _tile(
              context,
              WalletIcons.upload,
              'Restore backup',
              'Validate and replace this device’s data.',
              () => CsvService.importAll(context),
            ),
            _tile(
              context,
              WalletIcons.cloud,
              'Back up to Google Drive',
              'Save a copy using your Google account.',
              () => GoogleDriveService.backupToDrive(context),
            ),
            const SectionTitle('Shared expenses'),
            _tile(
              context,
              WalletIcons.users,
              'Jam sessions',
              'Split group expenses and settle your share.',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JamSessionsScreen()),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Hermyonie’s Wallet\nA little clarity, every day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PesowiseColors.muted,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Panel(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: PesowiseColors.strong),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, height: 1.5),
        ),
        trailing: const Icon(WalletIcons.chevronRight, size: 18),
        onTap: action,
      ),
    ),
  );
}

class AssistantAccessSheet extends StatefulWidget {
  const AssistantAccessSheet({super.key});
  @override
  State<AssistantAccessSheet> createState() => _AssistantAccessSheetState();
}

class _AssistantAccessSheetState extends State<AssistantAccessSheet> {
  final _token = TextEditingController(text: AssistantService.accessToken);
  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FormSheet(
    title: 'Assistant access',
    subtitle:
        'Enter the private access passphrase for your deployed assistant. Your Groq API key belongs in Vercel, never in this app.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _token,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Assistant passphrase'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Held in memory for this session. Only your command and a small account summary are sent when you ask the assistant.',
          style: TextStyle(
            color: PesowiseColors.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            AssistantService.accessToken = _token.text.trim();
            Navigator.pop(context);
          },
          child: const Text('Save for this session'),
        ),
      ],
    ),
  );
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _account, _error;
  List<ImportRow> _rows = [];
  bool _busy = false;
  String? _fileName;
  @override
  void initState() {
    super.initState();
    _account = WalletService.getAll().firstOrNull?.id;
  }

  Future<void> _pick() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null || _account == null) return;
      final raw = await file.xFile.readAsString();
      final rows = ImportService.parse(raw, _account!);
      if (mounted) {
        setState(() {
          _rows = rows;
          _fileName = file.name;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Could not read this CSV.',
        );
      }
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await ImportService.save(_rows, _account!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count transactions imported. Duplicates skipped.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Import failed. No changes were saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = WalletService.getAll();
    final duplicates = _rows.where(ImportService.alreadyImported).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Import transactions')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Panel(
                color: PesowiseColors.chipBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview first. Import once.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the CSV template below. Dates use YYYY-MM-DD, amounts are positive, and type is expense or income. Keep stable references to avoid duplicates.',
                      style: TextStyle(
                        color: PesowiseColors.muted,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start with the balance before these transactions. Importing changes the recorded account balance.',
                      style: TextStyle(
                        color: PesowiseColors.strong,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (accounts.isEmpty)
                const EmptyPanel(
                  icon: WalletIcons.wallet,
                  title: 'Add an account first',
                  description:
                      'Return to Accounts and add the account this statement belongs to.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _account,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Import into account',
                  ),
                  items: accounts
                      .map(
                        (w) =>
                            DropdownMenuItem(value: w.id, child: Text(w.name)),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _account = v;
                          _rows = [];
                          _fileName = null;
                        }),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(WalletIcons.upload),
                  label: const Text('Choose CSV file'),
                ),
              ],
              TextButton.icon(
                onPressed: () async {
                  try {
                    await FilePicker.saveFile(
                      fileName: 'wallet-import-template.csv',
                      mimeType: 'text/csv',
                      bytes: Uint8List.fromList(
                        utf8.encode(
                          'date,description,amount,type,category,reference\n${DateTime.now().toIso8601String().substring(0, 10)},Lunch,150,expense,Food & Drink,example-001\n',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
                icon: const Icon(WalletIcons.download, size: 18),
                label: const Text('Download CSV template'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB14128)),
                  ),
                ),
              if (_fileName != null) ...[
                SectionTitle(_fileName!),
                Text(
                  '${_rows.length} rows · $duplicates already imported',
                  style: const TextStyle(color: PesowiseColors.muted),
                ),
                const SizedBox(height: 12),
                ..._rows
                    .take(30)
                    .map(
                      (r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.label),
                        subtitle: Text(
                          '${r.date.toIso8601String().substring(0, 10)} · ${r.isExpense ? 'Expense' : 'Income'}',
                        ),
                        trailing: ImportService.alreadyImported(r)
                            ? const Text(
                                'Skip',
                                style: TextStyle(color: PesowiseColors.muted),
                              )
                            : Text('₱${r.amount.toStringAsFixed(2)}'),
                      ),
                    ),
                if (_rows.length > 30) const Text('Showing the first 30 rows.'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy || _rows.length == duplicates ? null : _save,
                  child: Text(
                    _busy
                        ? 'Importing…'
                        : 'Import ${_rows.length - duplicates} new transactions',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
