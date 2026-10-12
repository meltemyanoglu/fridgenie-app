/// Build-time configuration passed with `--dart-define-from-file`.
/// No real secret lives here: the Gemini key stays on the Worker.
class AppConfig {
  AppConfig._();

  /// Base URL of the deployed Worker (`https://fridgenie-api.<account>...`).
  static const String backendUrl = String.fromEnvironment('FRIDGENIE_BACKEND');

  /// Shared token the Worker expects in the `X-Fridgenie-Token` header.
  static const String appToken = String.fromEnvironment('FRIDGENIE_APP_TOKEN');

  /// True when both values are set; otherwise the app runs in demo mode.
  static bool get isBackendConfigured =>
      backendUrl.isNotEmpty && appToken.isNotEmpty;

  /// Parsed backend URL; only meaningful when [isBackendConfigured] is true.
  static Uri get backendUri => Uri.parse(backendUrl);
}
