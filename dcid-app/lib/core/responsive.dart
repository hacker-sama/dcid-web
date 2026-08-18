import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double compact = 600;   // phone
  static const double medium = 768;    // tablet dọc (iPad/iPad Air standard)
  static const double expanded = 1200; // desktop/web thường
  static const double large = 1600;    // ultra-wide / kiosk màn lớn
}

/// Breakpoint helper: phones use compact layouts; kiosk/desktop use the wide
/// master-detail / side-by-side layout.
class Responsive {
  const Responsive._();

  static const double wideBreakpoint = 900;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.compact;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= Breakpoints.compact && width < Breakpoints.expanded;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.medium;

  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.large;
}
