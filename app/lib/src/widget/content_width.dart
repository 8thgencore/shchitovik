import 'package:flutter/widgets.dart';

/// Maximum width of the page content (the «wide» viewport token); chrome stays full width.
const contentMaxWidth = 1280.0;

/// Caps [child] at [contentMaxWidth] and centers it horizontally.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, super.key});

  /// Page content.
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: contentMaxWidth),
      child: child,
    ),
  );
}
