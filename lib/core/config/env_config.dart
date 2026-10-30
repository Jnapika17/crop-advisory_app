/// Environment Configuration
///
/// This file manages all environment variables and app configuration.
/// It uses flutter_dotenv to load environment variables from .env file.
/// All sensitive data like API keys should be stored in .env and never committed to git.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_config.g.dart';

/// Optional API configuration used by weather and market-data services.
class EnvConfig {
  /// Weather API key for weather data (optional)
  final String? weatherApiKey;

  /// Market price API key (optional)
  final String? marketApiKey;

  //api key for hugging face for model calling for pest detection

  final String? hfApiKey;

  const EnvConfig({
    this.weatherApiKey,
    this.marketApiKey,
    this.hfApiKey,
  });

  /// Factory constructor to create EnvConfig from environment variables
  factory EnvConfig.fromEnv() {
    return EnvConfig(
      weatherApiKey: dotenv.maybeGet('WEATHER_API_KEY')?.trim(),
      marketApiKey: dotenv.maybeGet('MARKET_API_KEY')?.trim(),
      hfApiKey: dotenv.env['HF_API_KEY']?.trim(),
    );
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
