/// Simple Authentication Provider
///
/// Simplified auth provider without code generation for quick development.
/// Falls back to local SharedPreferences storage when Supabase is not configured.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../services/biometric_service.dart';

const String _demoEmailKey = 'demo_auth_email';
const String _demoPasswordKey = 'demo_auth_password';
const String _demoNameKey = 'demo_auth_name';
const String _demoSessionKey = 'demo_auth_session';

// ============================================================================
// REACTIVE AUTH STATE
// ============================================================================

/// Reactive current user provider — updates automatically on sign in/out.
final currentUserProvider = StreamProvider<User?>((ref) {
  try {
    final config = EnvConfig.fromEnv();
    if (!config.isValid) {
      return Stream.value(null);
    }

    return Supabase.instance.client.auth.onAuthStateChange.map((data) {
      return data.session?.user;
    });
  } catch (_) {
    return Stream.value(null);
  }
});

/// Convenience provider: true if user is currently logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// ============================================================================
// AUTH NOTIFIER — handles sign-up, sign-in, sign-out operations
// ============================================================================

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  bool get _isBackendConfigured => EnvConfig.fromEnv().isValid;

  /// Sign up with email and password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (!_isBackendConfigured) {
        final prefs = await SharedPreferences.getInstance();
        final normalizedEmail = email.trim().toLowerCase();
        final name = fullName.trim();

        final existingEmail = prefs.getString(_demoEmailKey);
        if (existingEmail != null && existingEmail.toLowerCase() == normalizedEmail) {
          throw Exception('An account with this email already exists. Please sign in.');
        }

        await prefs.setString(_demoEmailKey, normalizedEmail);
        await prefs.setString(_demoPasswordKey, password);
        await prefs.setString(_demoNameKey, name);
        await prefs.setString(_demoSessionKey, normalizedEmail);
        return;
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phone_number': phoneNumber,
        },
      );

      if (response.user == null) {
        throw Exception('Sign up failed. Please try again.');
      }
    });
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (!_isBackendConfigured) {
        final prefs = await SharedPreferences.getInstance();
        final normalizedEmail = email.trim().toLowerCase();
        final storedEmail = prefs.getString(_demoEmailKey)?.trim().toLowerCase();
        final storedPassword = prefs.getString(_demoPasswordKey);
        final storedSession = prefs.getString(_demoSessionKey)?.trim().toLowerCase();

        final hasExistingDemoSession =
            storedSession != null && storedSession.isNotEmpty;

        if (hasExistingDemoSession && storedEmail == normalizedEmail) {
          await prefs.setString(_demoSessionKey, normalizedEmail);
          return;
        }

        if (storedEmail == null ||
            storedPassword == null ||
            storedEmail != normalizedEmail ||
            storedPassword != password) {
          throw Exception('Demo sign in failed. Please sign up first.');
        }

        await prefs.setString(_demoSessionKey, storedEmail);
        return;
      }

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw Exception('Sign in failed. Please check your credentials.');
      }
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (!_isBackendConfigured) {
        throw Exception(
          'Password reset is only available when Supabase credentials are configured.',
        );
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    });
  }

  /// Sign in with phone OTP
  Future<void> signInWithPhone(String phoneNumber) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (!_isBackendConfigured) {
        throw Exception(
          'Phone OTP is only available when Supabase credentials are configured.',
        );
      }

      await Supabase.instance.client.auth.signInWithOtp(phone: phoneNumber);
    });
  }

  /// Verify phone OTP
  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (!_isBackendConfigured) {
        throw Exception(
          'Phone OTP verification is only available when Supabase credentials are configured.',
        );
      }

      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user == null) {
        throw Exception('OTP verification failed. Please try again.');
      }
    });
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      if (!_isBackendConfigured) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_demoSessionKey);
        return;
      }

      await Supabase.instance.client.auth.signOut();
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ============================================================================
// BIOMETRIC AUTH
// ============================================================================

/// Biometric service provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Biometric Auth Notifier
///
/// Handles biometric login flow: authenticate → retrieve credentials → sign in
class BiometricAuthNotifier extends StateNotifier<AsyncValue<void>> {
  final BiometricService _bioService;
  final AuthNotifier _authNotifier;

  BiometricAuthNotifier(this._bioService, this._authNotifier)
      : super(const AsyncValue.data(null));

  /// Check if biometric login is available and enabled
  Future<bool> isBiometricAvailable() async {
    final canAuth = await _bioService.canAuthenticate();
    final isEnabled = await _bioService.isEnabled();
    return canAuth && isEnabled;
  }

  /// Perform biometric login
  Future<void> authenticateWithBiometrics() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final authenticated = await _bioService.authenticate(
        reason: 'Scan your fingerprint to login',
      );
      if (!authenticated) {
        throw Exception('Biometric authentication cancelled');
      }

      final creds = await _bioService.getCredentials();
      if (creds == null) {
        throw Exception(
          'No saved credentials found. Please login with email/password.',
        );
      }

      await _authNotifier.signInWithEmail(
        email: creds['email']!,
        password: creds['password']!,
      );
    });
  }

  /// Save credentials after successful email login (user opted in)
  Future<void> enableBiometric({
    required String email,
    required String password,
  }) async {
    await _bioService.saveCredentials(email: email, password: password);
  }

  /// Disable biometric login (clears stored credentials)
  Future<void> disableBiometric() async {
    await _bioService.clearCredentials();
  }

  /// Check if biometric hardware is available
  Future<bool> canUseBiometric() async {
    return await _bioService.canAuthenticate();
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Biometric auth provider
final biometricAuthProvider =
    StateNotifierProvider<BiometricAuthNotifier, AsyncValue<void>>((ref) {
  final bioService = ref.watch(biometricServiceProvider);
  final authNotifier = ref.watch(authStateProvider.notifier);
  return BiometricAuthNotifier(bioService, authNotifier);
});

/// Alias for compatibility
final authProvider = authStateProvider;
