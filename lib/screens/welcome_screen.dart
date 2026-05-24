import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'biometric_screen.dart';
class WelcomeScreen extends StatefulWidget {

  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() =>
      _WelcomeScreenState();
}

class _WelcomeScreenState
    extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;

  late Animation<double> _fadeIn;

  late Animation<Offset> _slideUp;

  @override
  void initState() {

    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOutCubic,
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {

    _ctrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      body: Stack(
        children: [

          Positioned(
            top: -100,
            right: -80,

            child: Container(
              width: 300,
              height: 300,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(
                  0.06,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -60,

            child: Container(
              width: 260,
              height: 260,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(
                  0.07,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const SizedBox(height: 48),

                  FadeTransition(
                    opacity: _fadeIn,

                    child: SlideTransition(
                      position: _slideUp,

                      child: Row(
                        children: [

                          Container(
                            width: 56,
                            height: 56,

                            decoration: BoxDecoration(
                              gradient:
                              const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                                begin:
                                Alignment.topLeft,
                                end:
                                Alignment.bottomRight,
                              ),

                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),

                              boxShadow: [

                                BoxShadow(
                                  color: AppColors
                                      .primary
                                      .withOpacity(
                                    0.30,
                                  ),

                                  blurRadius: 16,

                                  offset:
                                  const Offset(
                                    0,
                                    6,
                                  ),
                                ),
                              ],
                            ),

                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              const Text(
                                'DTR',

                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight:
                                  FontWeight.w800,
                                  color:
                                  AppColors.primary,
                                  fontFamily:
                                  'Poppins',
                                  letterSpacing: 1.2,
                                ),
                              ),

                              Text(
                                'Direct Tax Rail',

                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  AppColors.accent,
                                  fontFamily:
                                  'Poppins',
                                  fontWeight:
                                  FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 52),

                  FadeTransition(
                    opacity: _fadeIn,

                    child: SlideTransition(
                      position: _slideUp,

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          const Text(
                            'Tax Filing,\nMade Simple.',

                            style: TextStyle(
                              fontSize: 36,
                              fontWeight:
                              FontWeight.w800,
                              color:
                              AppColors.textDark,
                              fontFamily:
                              'Poppins',
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Expert-assisted ITR filing,\nreal-time tracking,\nand smart tax tools — all in one place.',

                            style: TextStyle(
                              fontSize: 14,
                              color:
                              AppColors.textMid,
                              fontFamily:
                              'Poppins',
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  FadeTransition(
                    opacity: _fadeIn,

                    child: Column(
                      children: const [

                        _FeatureRow(
                          icon:
                          Icons.verified_user_rounded,
                          color: AppColors.primary,
                          text:
                          'CA-verified filing for every return',
                        ),

                        SizedBox(height: 14),

                        _FeatureRow(
                          icon:
                          Icons.track_changes_rounded,
                          color: AppColors.accent,
                          text:
                          'Real-time status tracking & notifications',
                        ),

                        SizedBox(height: 14),

                        _FeatureRow(
                          icon: Icons.lock_rounded,
                          color: AppColors.primary,
                          text:
                          '256-bit encrypted & fully secure',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  FadeTransition(
                    opacity: _fadeIn,

                    child: Column(
                      children: [

                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: ElevatedButton(
                            onPressed: () {

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                  const AuthScreen(),
                                ),
                              );
                            },

                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              AppColors.primary,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(14),
                              ),
                            ),

                            child: const Text(
                              'Get Started',

                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w700,
                                fontFamily:
                                'Poppins',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: OutlinedButton(
                            onPressed: () {

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                  const BiometricScreen(),
                                ),
                              );
                            },

                            style: OutlinedButton
                                .styleFrom(
                              side: const BorderSide(
                                color:
                                AppColors.primary,
                                width: 1.5,
                              ),

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(14),
                              ),
                            ),

                            child: const Text(
                              'Already have an account? Sign In',

                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w600,
                                fontFamily:
                                'Poppins',
                                color:
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {

  final IconData icon;

  final Color color;

  final String text;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: color.withOpacity(0.10),

            borderRadius:
            BorderRadius.circular(10),
          ),

          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            text,

            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMid,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}