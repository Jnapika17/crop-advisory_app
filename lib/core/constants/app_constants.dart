/// Application Constants
///
/// This file contains all constant values used throughout the app.
/// Including API endpoints, UI constants, strings, and configuration values.

/// API related constants
class ApiConstants {
  // Prevent instantiation
  ApiConstants._();

  /// API request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// API connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// Maximum number of retry attempts for failed requests
  static const int maxRetryAttempts = 3;
}

/// App UI constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// App name displayed to users
  static const String appName = 'Crop Advisory';

  /// App version
  static const String appVersion = '1.0.0';

  /// Default app locale
  static const String defaultLocale = 'en';

  /// Supported locales for the app
  static const List<String> supportedLocales = [
    'en', // English
    'hi', // Hindi
    'bn', // Bengali
    'te', // Telugu
    'mr', // Marathi
    'ta', // Tamil
    'gu', // Gujarati
    'kn', // Kannada
    'ml', // Malayalam
    'pa', // Punjabi
  ];
}

/// UI Spacing and Dimensions
class AppDimensions {
  // Prevent instantiation
  AppDimensions._();

  /// Extra small padding/margin (4.0)
  static const double paddingXS = 4.0;

  /// Small padding/margin (8.0)
  static const double paddingSM = 8.0;

  /// Medium padding/margin (16.0)
  static const double paddingMD = 16.0;

  /// Large padding/margin (24.0)
  static const double paddingLG = 24.0;

  /// Extra large padding/margin (32.0)
  static const double paddingXL = 32.0;

  /// Small border radius (4.0)
  static const double radiusSM = 4.0;

  /// Medium border radius (8.0)
  static const double radiusMD = 8.0;

  /// Large border radius (12.0)
  static const double radiusLG = 12.0;

  /// Extra large border radius (16.0)
  static const double radiusXL = 16.0;

  /// Small icon size (16.0)
  static const double iconSM = 16.0;

  /// Medium icon size (24.0)
  static const double iconMD = 24.0;

  /// Large icon size (32.0)
  static const double iconLG = 32.0;

  /// Extra large icon size (48.0)
  static const double iconXL = 48.0;
}

/// Database table and column names
class DatabaseConstants {
  // Prevent instantiation
  DatabaseConstants._();

  // Table names
  static const String usersTable = 'users';
  static const String cropsTable = 'crops';
  static const String advisoriesTable = 'advisories';
  static const String chatHistoryTable = 'chat_history';
  static const String soilDataTable = 'soil_data';
  static const String weatherDataTable = 'weather_data';
  static const String pestDetectionTable = 'pest_detection';
  static const String marketPricesTable = 'market_prices';
  static const String farmerProfilesTable = 'farmer_profiles';

  // Common column names
  static const String idColumn = 'id';
  static const String createdAtColumn = 'created_at';
  static const String updatedAtColumn = 'updated_at';
  static const String userIdColumn = 'user_id';
}

/// Storage keys for local data persistence
class StorageKeys {
  // Prevent instantiation
  StorageKeys._();

  /// Key for storing user authentication token
  static const String authToken = 'auth_token';

  /// Key for storing user profile data
  static const String userProfile = 'user_profile';

  /// Key for storing selected language preference
  static const String languagePreference = 'language_preference';

  /// Key for storing theme preference (light/dark)
  static const String themePreference = 'theme_preference';

  /// Key for storing onboarding completion status
  static const String onboardingCompleted = 'onboarding_completed';

  /// Key for storing offline chat history
  static const String offlineChatHistory = 'offline_chat_history';

  /// Key for storing cached crop data
  static const String cachedCropData = 'cached_crop_data';
}

/// Asset paths for images and icons
class AssetPaths {
  // Prevent instantiation
  AssetPaths._();

  // Images
  static const String imagesPath = 'assets/images/';
  static const String logoImage = '${imagesPath}logo.png';
  static const String splashImage = '${imagesPath}splash.png';
  static const String onboardingImage1 = '${imagesPath}onboarding1.png';
  static const String onboardingImage2 = '${imagesPath}onboarding2.png';
  static const String onboardingImage3 = '${imagesPath}onboarding3.png';
  static const String placeholderImage = '${imagesPath}placeholder.png';

  // Icons
  static const String iconsPath = 'assets/icons/';
  static const String chatIcon = '${iconsPath}chat.png';
  static const String cropIcon = '${iconsPath}crop.png';
  static const String weatherIcon = '${iconsPath}weather.png';
  static const String pestIcon = '${iconsPath}pest.png';
  static const String marketIcon = '${iconsPath}market.png';
  static const String soilIcon = '${iconsPath}soil.png';
}

/// Route names for navigation
class Routes {
  // Prevent instantiation
  Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chatbot = '/chatbot';
  static const String cropAdvisory = '/crop-advisory';
  static const String soilHealth = '/soil-health';
  static const String weather = '/weather';
  static const String pestDetection = '/pest-detection';
  static const String marketPrices = '/market-prices';
  static const String fertilizerCalculator = '/fertilizer-calculator';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String languageSelection = '/language-selection';
}

/// Error messages
class ErrorMessages {
  // Prevent instantiation
  ErrorMessages._();

  static const String networkError =
      'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authenticationError =
      'Authentication failed. Please login again.';
  static const String validationError =
      'Please check your input and try again.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
  static const String noDataError = 'No data available.';
  static const String permissionDenied =
      'Permission denied. Please grant the required permissions.';
}
