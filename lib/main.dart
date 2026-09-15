/// Crop Advisory - Main Application Entry Point
///
/// This file initializes all core services and starts the Flutter application.
/// It handles:
/// - Environment configuration loading
/// - Supabase initialization
/// - Riverpod provider scope setup
/// - App theme and navigation configuration

import 'package:crop_advisory/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/biometric_service.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/language_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/language_selection_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/chatbot/screens/chatbot_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/language_chnage.dart';
import 'features/crop_advisory/screens/crop_advisory_screen.dart';
import 'features/soil_health/screens/soil_health_screen.dart';
import 'features/weather/screens/weather_screen.dart';
import 'features/pest_detection/screens/pest_detection_screen.dart';
import 'features/market_prices/screens/market_prices_screen.dart';
import 'features/fertilizer/screens/fertilizer_calculator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global logger instance for debugging throughout the app
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
  ),
);

/// Main function - Entry point of the application
///
/// This function:
/// 1. Ensures Flutter binding is initialized
/// 2. Loads environment variables from .env file
/// 3. Initializes Supabase with credentials
/// 4. Sets system UI overlays (status bar, navigation bar)
/// 5. Launches the app with Riverpod provider scope
void main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    logger.i('Starting Crop Advisory App...');

    // Load environment variables from .env file
    logger.i('Loading environment configuration...');
    await dotenv.load(fileName: '.env', isOptional: true);
    logger.i('Environment configuration loaded');

    // Validate environment configuration
    final config = EnvConfig.fromEnv();
    if (!config.isValid) {
      logger.w(
        'Supabase environment variables are missing. Running in demo mode. '
        'Set SUPABASE_URL and SUPABASE_ANON_KEY in .env to enable full backend features.',
      );
    } else {
      logger.i('Environment configuration validated');

      // Initialize Supabase
      logger.i('Initializing Supabase...');
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      // Listen for auth state changes to ensure tokens are refreshed
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;

        // The Supabase SDK automatically handles token refresh when this listener is active.
        // You can add routing logic here if you want to force users to the login screen
        // if their session expires while using the app.
        if (event == AuthChangeEvent.signedOut) {
          logger.i('User signed out');
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          logger.i('Auth token refreshed successfully');
        }
      });
      logger.i('Supabase initialized successfully');
    }

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Set preferred orientations (portrait only for now)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    logger.i('Launching app...');

    // Run the app wrapped in ProviderScope for Riverpod state management
    runApp(const ProviderScope(child: CropAdvisoryApp()));
  } catch (e, stackTrace) {
    logger.e('Error initializing app', error: e, stackTrace: stackTrace);

    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Restart app
                      SystemNavigator.pop();
                    },
                    child: const Text('Close App'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root widget of the application
///
/// This widget sets up:
/// - Material app configuration
/// - Theme data (light and dark modes)
/// - Initial route
/// - Navigation routes
class CropAdvisoryApp extends ConsumerWidget {
  const CropAdvisoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeMode$Provider);
    final locale = ref.watch(localeNotifierProvider);
    return MaterialApp(
      // App metadata
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration with dynamic switching
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Initial route
      initialRoute: Routes.splash,
      //Language configurations
      locale: locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Route configuration
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.onboarding: (context) => const LanguageSelectionScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.home: (context) => const HomeScreen(),
        Routes.chatbot: (context) => const ChatbotScreen(),
        Routes.profile: (context) => const ProfileScreen(),
        Routes.cropAdvisory: (context) => const CropAdvisoryScreen(),
        Routes.soilHealth: (context) => const SoilHealthScreen(),
        Routes.weather: (context) => const WeatherScreen(),
        Routes.pestDetection: (context) => const PestDetectionScreen(),
        Routes.marketPrices: (context) => const MarketPricesScreen(),
        Routes.fertilizerCalculator: (context) =>
            const FertilizerCalculatorScreen(),
        Routes.languageSelection: (context) => const LanguageChangeScreen(),
        // Add more routes as features are implemented
      },

      // 404 route handler
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('The requested page does not exist.'),
            ),
          ),
        );
      },
    );
  }
}

/// Splash Screen - Shown while app initializes
///
/// This screen:
/// - Displays app logo and branding
/// - Checks authentication status
/// - Navigates to appropriate screen (login or home)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasSupabaseClient() {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasActiveSession() async {
    try {
      if (Supabase.instance.client.auth.currentSession != null) {
        return true;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final demoSession = prefs.getString('demo_auth_session');
      return demoSession != null && demoSession.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app and navigate to appropriate screen
  Future<void> _initializeApp() async {
    try {
      logger.i('Initializing app on splash screen...');

      // Simulate initialization delay
      await Future.delayed(const Duration(seconds: 2));

      // Check onboarding status
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
      final hasActiveSession = await _hasActiveSession();

      logger.i('App initialization completed');

      // Navigate to appropriate screen
      if (mounted) {
        if (!onboardingCompleted) {
          // Show onboarding for first-time users
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
        } else if (hasActiveSession) {
          // Restore the last signed-in user session
          Navigator.of(context).pushReplacementNamed(Routes.home);
        } else {
          // No active session — try biometric quick-login
          final bioService = BiometricService();
          final canAuth = await bioService.canAuthenticate();
          final isEnabled = await bioService.isEnabled();

          if (canAuth && isEnabled) {
            // Show biometric prompt
            final authenticated = await bioService.authenticate(
              reason: 'Scan your fingerprint to login',
            );

            if (authenticated && mounted) {
              final creds = await bioService.getCredentials();
              if (creds != null) {
                try {
                  // Sign in silently with stored credentials only if Supabase is initialized
                  if (_hasSupabaseClient()) {
                    await Supabase.instance.client.auth.signInWithPassword(
                      email: creds['email']!,
                      password: creds['password']!,
                    );
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed(Routes.home);
                    }
                    return;
                  }
                } catch (e) {
                  logger.e('Biometric auto-login failed: $e');
                  // Fall through to login screen
                }
              }
            }
          }

          // Fall back to normal login
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(Routes.login);
          }
        }
      }
    } catch (e) {
      logger.e('Error during app initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo (placeholder - replace with actual logo)
            Icon(Icons.agriculture, size: 100, color: AppColors.textLight),
            const SizedBox(height: 24),

            // App name
            Text(
              AppConstants.appName,
              style: AppTextStyles.h2.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 8),

            // App tagline
            Text(
              'Smart Farming Assistant',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textLight.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
