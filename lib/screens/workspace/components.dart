import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      border: Border.all(color: PesowiseColors.blushBorder),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionTitle(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title, description;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: PesowiseColors.chipBg,
          child: Icon(icon, color: PesowiseColors.strong),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PesowiseColors.muted, height: 1.5),
        ),
        if (onAction != null) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel ?? 'Get started'),
          ),
        ],
      ],
    ),
  );
}

class FormSheet extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const FormSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: PesowiseColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

Future<T?> openSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PesowiseColors.background,
      builder: (_) => child,
    );
void showError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is FormatException
              ? error.message
              : 'Could not complete this action. Please try again.',
        ),
      ),
    );
