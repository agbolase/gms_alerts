/// GMS Alerts API. Change [apiBaseUrl] before building.
class AppConfig {
  /// Live Granny Murray (physical device / store build).
  static const String apiBaseUrl = 'https://gms.grannymurray.com/api/gms/mobile';

  /// Android emulator → local XAMPP:
  /// static const String apiBaseUrl = 'http://10.0.2.2/schools/api/gms/mobile';

  static const String appName = 'GMS Alerts';
  static const Duration requestTimeout = Duration(seconds: 35);
  static const Duration pollTimeout = Duration(seconds: 28);
}
