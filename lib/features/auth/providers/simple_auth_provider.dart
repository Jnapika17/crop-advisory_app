import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/biometric_service.dart';

/// Reactive current user provider — emits the current Firebase Auth user and
/// updates on sign-in and sign-out.
final currentUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AsyncValue.data(null));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  ConfirmationResult? _webPhoneConfirmation;
  String? _phoneVerificationId;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Sign up failed. Please try again.');
      }

      final name = fullName.trim();
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phoneNumber': phoneNumber.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _auth.sendPasswordResetEmail(email: email.trim()),
    );
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (kIsWeb) {
        _webPhoneConfirmation =
            await _auth.signInWithPhoneNumber(phoneNumber.trim());
        return;
      }

      final codeSent = Completer<void>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
          if (!codeSent.isCompleted) codeSent.complete();
        },
        verificationFailed: (error) {
          if (!codeSent.isCompleted) codeSent.completeError(error);
        },
        codeSent: (verificationId, _) {
          _phoneVerificationId = verificationId;
          if (!codeSent.isCompleted) codeSent.complete();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _phoneVerificationId = verificationId;
        },
      );
      await codeSent.future;
    });
  }

  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final webConfirmation = _webPhoneConfirmation;
      if (kIsWeb && webConfirmation != null) {
        await webConfirmation.confirm(otp.trim());
        _webPhoneConfirmation = null;
        return;
      }

      final verificationId = _phoneVerificationId;
      if (verificationId == null) {
        throw Exception('Request a new verification code and try again.');
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );
      await _auth.signInWithCredential(credential);
      _phoneVerificationId = null;
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _auth.signOut());
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricAuthNotifier extends StateNotifier<AsyncValue<void>> {
  BiometricAuthNotifier(this._bioService, this._authNotifier)
      : super(const AsyncValue.data(null));

  final BiometricService _bioService;
  final AuthNotifier _authNotifier;

  Future<bool> isBiometricAvailable() async {
    final canAuth = await _bioService.canAuthenticate();
    final isEnabled = await _bioService.isEnabled();
    return canAuth && isEnabled;
  }

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

  Future<void> enableBiometric({
    required String email,
    required String password,
  }) {
    return _bioService.saveCredentials(email: email, password: password);
  }

  Future<void> disableBiometric() => _bioService.clearCredentials();

  Future<bool> canUseBiometric() => _bioService.canAuthenticate();

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final biometricAuthProvider =
    StateNotifierProvider<BiometricAuthNotifier, AsyncValue<void>>((ref) {
  return BiometricAuthNotifier(
    ref.watch(biometricServiceProvider),
    ref.watch(authStateProvider.notifier),
  );
});

final authProvider = authStateProvider;
