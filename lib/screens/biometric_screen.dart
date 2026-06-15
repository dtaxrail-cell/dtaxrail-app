import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../theme/app_theme.dart';
import '../services/google_auth_service.dart';

import 'main_navigation_screen.dart';
import 'auth_screen.dart';
import 'complete_profile_screen.dart';
import '../config/api_config.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 500),
          () {
        authenticate();
      },
    );
  }

  Future<void> authenticate() async {
    try {
      setState(() {
        loading = true;
      });

      // 1. Check hardware capability
      final bool canAuthenticate = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      // 2. Check if fingerprints are actually registered/enrolled
      final List<BiometricType> enrolledBiometrics = await auth.getAvailableBiometrics();

      // 3. Conditional Skip Logic:
      // If hardware is missing, unsupported, OR no fingerprints are registered in device settings...
      if (!canAuthenticate || !isDeviceSupported || enrolledBiometrics.isEmpty) {
        print("Biometric not available or no fingerprints enrolled. Skipping step smoothly...");
        await _proceedToNextScreenWithoutPrompt();
        return;
      }

      // 4. If fingerprints DO exist, trigger scanner prompt
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access D Tax Rail',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        print("BIOMETRIC SUCCESS");
        await _handlePostAuthentication();
      }
    } catch (e) {
      print("Error during authentication: $e");
      // Fallback fallback: If anything unexpected breaks, let them into the app
      await _proceedToNextScreenWithoutPrompt();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Helper method to process API sync and navigate to the home/complete profile screen
  Future<void> _handlePostAuthentication() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("USER NULL AFTER BIOMETRIC");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    final token = await currentUser.getIdToken();

    print("CALLING ENABLE BIOMETRIC API");
    await Dio().post(
      '${ApiConfig.baseUrl}/auth/enable-biometric',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    print("ENABLE BIOMETRIC API SUCCESS");
    print("Biometric enabled in DB");
    print("FETCHING CUSTOMER");

    final response = await Dio().get(
      '${ApiConfig.baseUrl}/customers/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    print("CUSTOMER FETCHED");

    final customer = response.data['customer'];
    final phone = customer['phone'];

    if (!mounted) return;

    print("GOING TO HOME");

    if (phone == null || phone.toString().isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CompleteProfileScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    }
  }

  // Wrapper method used when skipping biometric challenge entirely
  Future<void> _proceedToNextScreenWithoutPrompt() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await _handlePostAuthentication();
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  Future<void> useAnotherAccount() async {
    await GoogleAuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.20),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Center(
                    child: Text(
                      "Welcome Back",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "Verifying your identity securely using biometrics.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textMid,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : const Icon(
                      Icons.fingerprint_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "This device is trusted",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: useAnotherAccount,
                    child: const Text(
                      "Use another account",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



