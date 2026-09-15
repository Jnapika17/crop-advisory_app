/// Environment Configuration
///
/// This file manages all environment variables and app configuration.
/// It uses flutter_dotenv to load environment variables from .env file.
/// All sensitive data like API keys should be stored in .env and never committed to git.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_config.g.dart';

/// Environment configuration class that holds all app configuration values
class EnvConfig {
  /// Supabase project URL for backend connection
  final String supabaseUrl;

  /// Supabase anonymous key for public API access
  final String supabaseAnonKey;

  /// Google Gemini API key for AI chatbot functionality
  final String geminiApiKey;

  /// Weather API key for weather data (optional)
  final String? weatherApiKey;

  /// Market price API key (optional)
  final String? marketApiKey;

  //api key for hugging face for model calling for pest detection

  final String? hfApiKey;

  const EnvConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.geminiApiKey,
    this.weatherApiKey,
    this.marketApiKey,
    this.hfApiKey,
  });

  /// Factory constructor to create EnvConfig from environment variables
  factory EnvConfig.fromEnv() {
    final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: '');
    final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
    final geminiApiKey = dotenv.get('GEMINI_API_KEY', fallback: '');

    return EnvConfig(
      supabaseUrl: supabaseUrl.trim(),
      supabaseAnonKey: supabaseAnonKey.trim(),
      geminiApiKey: geminiApiKey.trim(),
      weatherApiKey: dotenv.maybeGet('WEATHER_API_KEY')?.trim(),
      marketApiKey: dotenv.maybeGet('MARKET_API_KEY')?.trim(),
      hfApiKey: dotenv.env['HF_API_KEY']?.trim(),
    );
  }

  static bool _isPlaceholder(String? value) {
    if (value == null) return true;
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized.contains('your_') ||
        normalized.contains('your-') ||
        normalized.contains('your ') ||
        normalized.contains('replace') ||
        normalized.contains('example') ||
        normalized.endsWith('_here');
  }

  /// Validates that all required configuration values are present
  bool get isValid {
    return !_isPlaceholder(supabaseUrl) && !_isPlaceholder(supabaseAnonKey);
  }
}

/// Riverpod provider for EnvConfig
///
/// This provider makes the environment configuration available throughout the app.
/// It's a singleton that loads configuration once and reuses it.
@Riverpod(keepAlive: true)
EnvConfig envConfig(EnvConfigRef ref) {
  return EnvConfig.fromEnv();
}
