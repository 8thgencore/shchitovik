import 'package:flutter/widgets.dart';

/// Width from which the app uses the expanded layout (Material 3 «expanded» window class).
const expandedLayoutMinWidth = 840.0;

/// Window size helpers.
extension WindowSizeContext on BuildContext {
  /// Whether the window is wide enough for the expanded layout (desktop, tablet landscape).
  bool get isExpandedLayout => MediaQuery.sizeOf(this).width >= expandedLayoutMinWidth;
}
