/// Build-time configuration.
///
/// Override per environment, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.0.10:8080
class Env {
  const Env._();

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  static String get wsBaseUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return 'wss://${apiBaseUrl.substring(8)}/ws/websocket';
    } else if (apiBaseUrl.startsWith('http://')) {
      return 'ws://${apiBaseUrl.substring(7)}/ws/websocket';
    }
    return 'ws://localhost:8080/ws/websocket';
  }
}
