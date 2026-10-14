import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:flutter/material.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';

/// Whether the expert interface mode is on.
bool isExpertMode(BuildContext context) =>
    SettingsScope.of(context).general.interfaceMode == InterfaceModeVO.expert;

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
    this.numeric = false,
    this.validator,
    super.key,
  });

  /// Current value from the model.
  final String value;

  /// Label.
  final String label;

  /// Helper text.
  final String? hint;

  /// Mono digits and a decimal keyboard.
  final bool numeric;

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
  Widget build(BuildContext context) => UiTextField(
    controller: _controller,
    focusNode: _focus,
    label: widget.label,
    help: widget.hint,
    error: _error,
    numeric: widget.numeric,
    onChanged: (_) {
      if (_error != null) setState(() => _error = null);
    },
    onSubmitted: (_) => _commit(),
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
    numeric: true,
    validator: (text) {
      final parsed = parseDecimal(text);
      if (text.trim().isNotEmpty && parsed == null) return context.translations.fieldNumber;
      return validator?.call(parsed);
    },
    onCommitted: (text) => onChanged(parseDecimal(text)),
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

/// Scrollable page body: content capped at [maxWidth] with the screen gutter.
class PageBody extends StatelessWidget {
  const PageBody({required this.children, this.maxWidth, this.bottomInset = 0, super.key});

  /// Blocks of the page, separated by the section gap.
  final List<Widget> children;

  /// Content width cap; defaults to the full content width.
  final double? maxWidth;

  /// Extra space at the bottom (above a floating action).
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final gutter = context.isExpandedLayout ? UiSpace.xl : UiSpace.l;
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, UiSpace.xxl + bottomInset),
      children: [
        UiContentWidth(
          maxWidth: maxWidth ?? UiBreakpoints.contentMax,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: UiSpace.l),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
