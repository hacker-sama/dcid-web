import 'dart:io' show Platform;

/// Configures fullscreen kiosk mode on Windows (Industrial PC).
///
/// M4: add the `window_manager` dependency and enable fullscreen, e.g.:
/// ```
/// await windowManager.ensureInitialized();
/// await windowManager.waitUntilReadyToShow(const WindowOptions(fullScreen: true), () async {
///   await windowManager.setFullScreen(true);
///   await windowManager.show();
/// });
/// ```
Future<void> configureKioskIfDesktop() async {
  if (!Platform.isWindows) return;
  // TODO(M4): wire window_manager for fullscreen kiosk.
}
