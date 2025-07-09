abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
}

enum WindowClass { compact, medium, expanded }

WindowClass windowClassForWidth(double width) {
  if (width < AppBreakpoints.compact) return WindowClass.compact;
  if (width < AppBreakpoints.medium) return WindowClass.medium;
  return WindowClass.expanded;
}
