//Auth service which will handle the auth with fingerprint of facial recognition
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

final _logger = Logger();
class BiometricService {
  static const _storage = FlutterSecureStorage();
  //keys for secure storage 
  static const _keyEmail='biometric_email';
  static const _keyPassword='biometric_password';
  static const _keyEnabled='biometric_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();
  //check if device support the biometric auth
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      _logger.e("Error checkin for biometric support: $e");
      return false;
    }
    //check if the biometric hardware is available and enrolled in it or not?
    
  }
  Future<bool> canAuthenticate() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final isSuporrted = await isDeviceSupported();
      if(!isSuporrted) return false;
      //check if biometric is enrolled or not 
      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) return true;
      return false;
    } on PlatformException catch(e){
       _logger.e('Platform exception checking biometrics: $e');
       return false;

    }catch (e) {
      _logger.e('Error checking biometrics: $e');
      return false;

    } }
    Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) {
      return [];
    }

    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('Error getting biometric types: $e');
      return [];
    }
  }
  ///authenticate user with biometrics
  ///returns true if authentication is successful, false otherwise
  ////// Shows the system biometric prompt (fingerprint scanner / Face ID).
  /// Returns true if authentication succeeded
  Future<bool> authenticate({
    String reason = 'Authenticate to access your account',
    bool stickyAuth = false,
  }) async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true, // Don't allow device PIN as fallback
        ),
      );
    } on PlatformException catch (e) {
      _logger.e('Biometric auth exception: ${e.message}');
      // User cancelled, or biometric not enrolled, etc.
      return false;
    } catch (e) {
      _logger.e('Error during biometric auth: $e');
      return false;
    }
  }
  /// Save credentials securely after successful login
  ///
  /// Call this after a successful email/password login when user opts in.
 Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
      await _storage.write(key: _keyEnabled, value: 'true');
      _logger.i('Biometric credentials saved');
    } catch (e) {
      _logger.e('Error saving credentials: $e');
    }
  }
  
  ///retrieve saved creds
  ///
  ///return null if biometric login is not enabled or creds ot found
  Future<Map<String , String>?> getCredentials()async{
    try {
      final isEnabled = await _storage.read(key: _keyEnabled);
      if(isEnabled !='true') return null;
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if(email==null || password == null ){return null;}
      return {'email': email, 'password': password};
    } catch (e) {
      _logger.e('Error retrieving credentials: $e');
    }
  }
  Future<bool> isEnabled() async{
    try {
      final value = await _storage.read(key: _keyEnabled);
      return value =='true';
    } catch (e) {
      return false;
    }
  } 
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyEnabled);
      _logger.i('Biometric credentials cleared');
    } catch (e) {
      _logger.e('Error clearing credentials: $e');
    }
  }
}
