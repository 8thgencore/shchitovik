import 'dart:async';

import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:flutter/material.dart';

/// Small circular spinner for buttons and inline waits.
class UiSpinner extends StatelessWidget {
  const UiSpinner({this.size = 20, this.color, super.key});

  /// Diameter.
  final double size;

  /// Colour; defaults to the accent.
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: size <= 16 ? 1.5 : 2,
      color: color ?? context.uiColors.accent,
    ),
  );
}

/// Centered spinner that appears only if loading lasts longer than [delay].
///
/// Local loads usually finish in a few milliseconds; a spinner for them only flickers.
class UiDeferredProgress extends StatefulWidget {
  const UiDeferredProgress({this.delay = const Duration(milliseconds: 100), super.key});

  /// How long to show nothing.
  final Duration delay;

  @override
  State<UiDeferredProgress> createState() => _UiDeferredProgressState();
}

class _UiDeferredProgressState extends State<UiDeferredProgress> {
  late final Timer _timer;
  var _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _visible ? const Center(child: UiSpinner(size: 28)) : const SizedBox.shrink();
}
