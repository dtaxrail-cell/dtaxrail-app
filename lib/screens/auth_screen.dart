import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import '../services/local_storage_service.dart';
import '../services/google_auth_service.dart';

import 'main_navigation_screen.dart';
import 'biometric_Screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userCredential = await GoogleAuthService.signInWithGoogle();

      if (userCredential != null) {
        final idToken = await userCredential.user!.getIdToken();
        await GoogleAuthService.syncCustomerToBackend(idToken!);
      }

      if (userCredential == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await LocalStorageService.setLoggedIn(true);
      await LocalStorageService.setBiometricEnabled(true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BiometricScreen()),
            (route) => false,
      );
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              const Text(
                "Welcome to D Tax Rail",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Securely manage your tax filings, documents, and real-time filing updates.",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMid,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 60),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      "Continue Securely",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Sign in using your Google account to continue securely.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMid,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 34),

                    GestureDetector(
                      onTap: _isLoading ? null : _handleGoogleLogin,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://cdn-icons-png.flaticon.com/512/300/300221.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 14),
                            _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified_user,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Protected with Firebase Authentication",
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const Center(
                child: Text(
                  "By continuing, you agree to our Terms & Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}