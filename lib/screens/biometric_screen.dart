import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../theme/app_theme.dart';

import 'main_navigation_screen.dart';
import 'auth_screen.dart';

class BiometricScreen extends StatefulWidget {

  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() =>
      _BiometricScreenState();
}

class _BiometricScreenState
    extends State<BiometricScreen> {

  final LocalAuthentication auth =
  LocalAuthentication();

  bool loading = false;

  Future<void> authenticate() async {

    try {

      setState(() {
        loading = true;
      });

      bool authenticated =
      await auth.authenticate(
        localizedReason:
        'Authenticate to access D Tax Rail',

        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {

        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder: (_) =>
            const MainNavigationScreen(),
          ),
        );
      }

    } catch (e) {

      print(e);

    } finally {

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.center,

            children: [

              const Spacer(),

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

                    borderRadius:
                    BorderRadius.circular(28),

                    boxShadow: [

                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.20),

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
                  "Use biometrics to continue securely",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              Center(
                child: GestureDetector(
                  onTap: loading
                      ? null
                      : authenticate,

                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 250),

                    width: 150,
                    height: 150,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color:
                      AppColors.primaryLight,

                      border: Border.all(
                        color:
                        AppColors.primary,
                        width: 2,
                      ),

                      boxShadow: [

                        BoxShadow(
                          color: AppColors.primary
                              .withOpacity(0.10),

                          blurRadius: 20,

                          offset:
                          const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: loading
                        ? const Center(
                      child:
                      CircularProgressIndicator(),
                    )
                        : const Icon(
                      Icons
                          .fingerprint_rounded,
                      size: 70,
                      color:
                      AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              const Center(
                child: Text(
                  "Tap to authenticate",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),

                  decoration: BoxDecoration(
                    color:
                    AppColors.accentLight,

                    borderRadius:
                    BorderRadius.circular(
                      30,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: const [

                      Icon(
                        Icons
                            .verified_user_rounded,
                        color:
                        AppColors.accent,
                        size: 18,
                      ),

                      SizedBox(width: 8),

                      Text(
                        "This device is trusted",

                        style: TextStyle(
                          color:
                          AppColors.accent,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {

                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                      const AuthScreen(),
                    ),
                  );
                },

                child: const Text(
                  "Use OTP instead",

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
    );
  }
}