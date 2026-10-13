import 'package:common_translations/common_translations.dart';
import 'package:flutter/material.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';

/// Whether the expert interface mode is on.
bool isExpertMode(BuildContext context) =>
    SettingsScope.of(context).general.interfaceMode == InterfaceModeVO.expert;

/// Section title inside a form.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  /// Title.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

/// Text field that reports its value when editing is finished (enter or focus loss),
/// so that every keystroke does not trigger a recalculation.
///
/// [validator] runs on that same moment: invalid text is not reported and shows the error,
/// which disappears with the first corrective keystroke.
class CommitTextField extends StatefulWidget {
  const CommitTextField({
    required this.value,
    required this.label,
    required this.onCommitted,
    this.hint,
    this.keyboardType,
    this.validator,
    super.key,
  });

  /// Current value from the model.
  final String value;

  /// Label.
  final String label;

  /// Helper text.
  final String? hint;

  /// Keyboard.
  final TextInputType? keyboardType;

  /// Called with the edited text when it differs from [value] and passes [validator].
  final ValueChanged<String> onCommitted;

  /// Error message for the edited text, `null` when it is valid.
  final String? Function(String text)? validator;

  @override
  State<CommitTextField> createState() => _CommitTextFieldState();
}

class _CommitTextFieldState extends State<CommitTextField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(CommitTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && _error == null && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  void _commit() {
    final error = widget.validator?.call(_controller.text);
    if (error != _error) setState(() => _error = error);
    if (error == null && _controller.text != widget.value) widget.onCommitted(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: TextField(
      controller: _controller,
      focusNode: _focus,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.hint,
        helperMaxLines: 3,
        errorText: _error,
        errorMaxLines: 3,
      ),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: (_) => _commit(),
    ),
  );
}

/// Decimal field; empty input means `null`, text that is not a number shows an error.
class DecimalField extends StatelessWidget {
  const DecimalField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.hint,
    this.digits = 2,
    this.validator,
    super.key,
  });

  /// Current value.
  final double? value;

  /// Label.
  final String label;

  /// Helper text.
  final String? hint;

  /// Decimals shown.
  final int digits;

  /// Called with the parsed value (`null` when cleared) once it passes [validator].
  final ValueChanged<double?> onChanged;

  /// Error message for the parsed value, `null` when it is acceptable.
  final String? Function(double? value)? validator;

  @override
  Widget build(BuildContext context) => CommitTextField(
    value: value == null ? '' : formatNumber(value, digits),
    label: label,
    hint: hint,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (text) {
      final parsed = parseDecimal(text);
      if (text.trim().isNotEmpty && parsed == null) return context.translations.fieldNumber;
      return validator?.call(parsed);
    },
    onCommitted: (text) => onChanged(parseDecimal(text)),
  );
}

/// Dropdown bound to a value.
class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  /// Label.
  final String label;

  /// Selected value.
  final T value;

  /// Options with labels.
  final List<(T, String)> options;

  /// Selection callback.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      key: ValueKey(value),
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final (v, text) in options)
          DropdownMenuItem(
            value: v,
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null || null is T) onChanged(v as T);
      },
    ),
  );
}

/// Validators of [DecimalField] values with the messages of the form.
extension FieldValidators on BuildContext {
  /// The value is required and at least [min].
  String? Function(double?) atLeast(num min) =>
      (v) => v == null
      ? translations.fieldRequired
      : v < min
      ? translations.fieldMin(formatNumber(min.toDouble()))
      : null;

  /// The value is required and greater than [min].
  String? Function(double?) above(num min) =>
      (v) => v == null
      ? translations.fieldRequired
      : v <= min
      ? translations.fieldAbove(formatNumber(min.toDouble()))
      : null;

  /// The value is required and within [min]…[max].
  String? Function(double?) between(num min, num max) =>
      (v) => v == null
      ? translations.fieldRequired
      : v < min || v > max
      ? translations.fieldRange(formatNumber(min.toDouble()), formatNumber(max.toDouble()))
      : null;

  /// The text is not blank.
  String? notBlank(String text) => text.trim().isEmpty ? translations.fieldRequired : null;
}
