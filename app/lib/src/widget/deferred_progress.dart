import 'dart:async';

import 'package:flutter/material.dart';

/// Centered progress indicator that appears only if loading lasts longer than [delay].
///
/// Local loads usually finish in a few milliseconds; showing a spinner for them only flickers.
class DeferredProgress extends StatefulWidget {
  const DeferredProgress({this.delay = const Duration(milliseconds: 100), super.key});

  /// How long to show nothing.
  final Duration delay;

  @override
  State<DeferredProgress> createState() => _DeferredProgressState();
}

class _DeferredProgressState extends State<DeferredProgress> {
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
      _visible ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink();
}
