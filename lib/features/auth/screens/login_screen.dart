/// Login Screen
///
/// User authentication screen with email/password and phone login options

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/simple_auth_provider.dart';
import 'register_screen.dart';
import '../../../services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final bioService = BiometricService();
    final available = await bioService.canAuthenticate();
    final enabled = await bioService.isEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available && enabled;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final authState = ref.read(authProvider);
      if (authState.hasError) {
        throw authState.error!;
      }

      if (mounted) {
        // Check if biometric is available on device but not yet enabled
        final bioService = BiometricService();
        final canAuth = await bioService.canAuthenticate();
        final isAlreadyEnabled = await bioService.isEnabled();

        if (canAuth && !isAlreadyEnabled && mounted) {
          // Offer to enable biometrics — both paths navigate home
          _showEnableBiometricDialog(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } else if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                _loginErrorMessage(e),
              ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _loginErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'configuration-not-found':
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled for this Firebase project. Enable it in Firebase Console under Authentication > Sign-in method.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'The email or password is incorrect.';
        case 'network-request-failed':
          return 'Could not reach Firebase. Check your internet connection and try again.';
      }
      return error.message ?? 'Sign-in failed. Please try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  // Add the biometric login method and enable dialog
  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(biometricAuthProvider.notifier)
          .authenticateWithBiometrics();

      final bioState = ref.read(biometricAuthProvider);
      if (bioState.hasError) {
        throw bioState.error!;
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEnableBiometricDialog(String email, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 40, color: Colors.green),
        title: const Text('Enable Biometric Login?'),
        content: const Text(
          'You can use your fingerprint or face recognition to login '
          'quickly next time without typing your password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacementNamed(Routes.home);
            },
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(biometricAuthProvider.notifier).enableBiometric(
                    email: email,
                    password: password,
                  );
              if (mounted) {
                setState(() => _isBiometricAvailable = true);
              }
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(Routes.home);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordResetDialog() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !email.contains('@') || !mounted)
      return;
    try {
      await ref.read(authProvider.notifier).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset link sent. Check your email.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send reset link: $error')),
        );
      }
    }
  }

  Future<void> _showPhoneLoginDialog() async {
    final phoneController = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Phone login'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+91 9876543210',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, phoneController.text.trim()),
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
    phoneController.dispose();
    if (phone == null || phone.isEmpty || !mounted) return;
    try {
      await ref.read(authProvider.notifier).signInWithPhone(phone);
      if (mounted) _showOtpDialog(phone);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send OTP: $error')),
        );
      }
    }
  }

  Future<void> _showOtpDialog(String phone) async {
    final otpController = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '6-digit code'),
        ),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, otpController.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    otpController.dispose();
    if (otp == null || otp.isEmpty || !mounted) return;
    try {
      await ref
          .read(authProvider.notifier)
          .verifyPhoneOtp(phoneNumber: phone, otp: otp);
      if (mounted) Navigator.of(context).pushReplacementNamed(Routes.home);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP verification failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.paddingXL * 2),

                // App Logo
                // Icon(
                //   Icons.agriculture,
                //   size: 80,
                //   color: AppColors.primary,
                // ),
                Image.asset(
                  'assets/images/LOgo_transperent.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: AppDimensions.paddingLG),

                // Title
                Text(
                  'Welcome Back',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingSM),

                Text(
                  'Sign in to continue ${AppConstants.appName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMD),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.paddingSM),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showPasswordResetDialog();
                    },
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLG),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textLight,
                            ),
                          ),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: AppDimensions.paddingLG),

                // Divider
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMD,
                      ),
                      child: Text(
                        'OR',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLG),

                // Biometric login button (only shown if available & enabled)
                if (_isBiometricAvailable)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.paddingLG,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Login with Biometrics'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                    ),
                  ),

                // Phone login button

                // Phone login button
                OutlinedButton.icon(
                  onPressed: () {
                    _showPhoneLoginDialog();
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Sign in with Phone'),
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
