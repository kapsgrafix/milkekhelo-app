/// Firebase project "milkekhelo-app" — player accounts and saved games.
/// (Who's That's multiplayer rooms stay on the separate "whosthat-f2c0c"
/// project.) These values come from google-services.json and are safe to
/// ship in the app: access is controlled by Firebase Auth + database rules.
class AuthConfig {
  AuthConfig._();

  static const String projectId = 'milkekhelo-app';
  static const String apiKey = 'AIzaSyDcUlqqY70AnGmV_Lhki9bC4txGDpCEzQM';

  /// OAuth "Web client" (client_type 3) — Google Sign-In must request its
  /// ID token for this audience so Firebase can verify it.
  static const String googleWebClientId =
      '748524739674-o4p01mk5j11raado7un2e2f9a1dhrncl.apps.googleusercontent.com';

  static const String databaseUrl = 'https://milkekhelo-app-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Sent with REST calls so an Android-restricted API key accepts them.
  static const String androidPackage = 'com.kapsgrafix.milkekhelo';
  static const String androidCertSha1 = '64C1B2F8746A6BD0AD6E22132D270F741C40599E';
}
