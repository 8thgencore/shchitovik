import 'package:flutter/material.dart';

/// Short form in a modal bottom sheet: title, fields and actions aligned to the end.
///
/// Keeps the fields above the on-screen keyboard and scrolls when they do not fit.
class SheetForm extends StatelessWidget {
  const SheetForm({required this.title, required this.fields, required this.actions, super.key});

  /// Shows [builder] as a bottom sheet that sizes to its content.
  static Future<T?> show<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: builder,
  );

  /// Title.
  final String title;

  /// Fields.
  final List<Widget> fields;

  /// Buttons; the primary one goes last.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...fields,
          const SizedBox(height: 24),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            overflowAlignment: OverflowBarAlignment.end,
            overflowSpacing: 8,
            children: actions,
          ),
        ],
      ),
    ),
  );
}
