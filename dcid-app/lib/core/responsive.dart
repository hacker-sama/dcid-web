import 'package:flutter/widgets.dart';

/// Breakpoint helper: phones use compact layouts; kiosk/desktop use the wide
/// master-detail / side-by-side layout.
class Responsive {
  const Responsive._();

  static const double wideBreakpoint = 900;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;
}
