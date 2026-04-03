abstract class AppConfig {
  // Android
  static const String firebaseAndroidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String firebaseAndroidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');

  // iOS
  static const String firebaseIosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const String firebaseIosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String firebaseIosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  // Web
  static const String firebaseWebApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String firebaseWebAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String firebaseWebAuthDomain =
      String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const String firebaseWebMeasurementId =
      String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

  // Common
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static const String formspreeId = String.fromEnvironment(
    'FORMSPREE_ID',
    defaultValue: '',
  );

  static const String formspreeApiEndpoint = String.fromEnvironment(
    'FORMSPREE_API_ENDPOINT',
    defaultValue: 'https://formspree.io/f/',
  );

  static const String jamendoClientId = String.fromEnvironment(
    'JAMENDO_CLIENT_ID',
    defaultValue: '',
  );

  static const String jamendoApiBaseUrl = String.fromEnvironment(
    'JAMENDO_API_BASE_URL',
    defaultValue: 'https://api.jamendo.com/v3.0',
  );

  static const String geniusAccessToken = String.fromEnvironment(
    'GENIUS_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String geniusClientId = String.fromEnvironment(
    'GENIUS_CLIENT_ID',
    defaultValue: '',
  );

  static const String lastFmApiKey = String.fromEnvironment(
    'LASTFM_API_KEY',
    defaultValue: '',
  );

  static const String lastFmApiBaseUrl = String.fromEnvironment(
    'LASTFM_API_BASE_URL',
    defaultValue: 'https://ws.audioscrobbler.com/2.0/',
  );
}
