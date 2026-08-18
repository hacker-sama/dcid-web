/// Build-time configuration.
///
/// Dev  (default): http://localhost:8080
/// Prod (CI/CD):   flutter run --dart-define=API_BASE_URL=https://dcid.tech
///                 flutter build apk --dart-define=API_BASE_URL=https://dcid.tech
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dcid.tech',
  );

  static String get wsBaseUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return 'wss://${apiBaseUrl.substring(8)}/ws';
    } else if (apiBaseUrl.startsWith('http://')) {
      return 'ws://${apiBaseUrl.substring(7)}/ws';
    }
    return 'wss://dcid.tech/ws';
  }
}
