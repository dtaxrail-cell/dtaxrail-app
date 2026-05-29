import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

import 'members_screen.dart';
import 'my_returns_screen.dart';
import 'need_help_screen.dart';
import 'members_screen.dart';
import 'filing_results_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String userName = "User";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {

      setState(() {

        userName =
            user.displayName ??
                user.email?.split("@").first ??
                "User";

      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      AppColors.background,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              // ── TOP BAR ─────────────────────────────────────────────
              Padding(

                padding:
                const EdgeInsets.fromLTRB(
                  22,
                  20,
                  22,
                  0,
                ),

                child: Row(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Expanded(

                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          const Text(

                            'Hello,',

                            style: TextStyle(

                              fontSize: 24,

                              fontWeight:
                              FontWeight.w800,

                              color:
                              AppColors.textDark,

                              fontFamily:
                              'Poppins',
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(

                            userName,

                            maxLines: 2,

                            overflow:
                            TextOverflow.ellipsis,

                            style: const TextStyle(

                              fontSize: 24,

                              fontWeight:
                              FontWeight.w800,

                              color:
                              AppColors.textDark,

                              fontFamily:
                              'Poppins',
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(

                            'Welcome to DTR',

                            style: TextStyle(

                              fontSize: 13,

                              color:
                              AppColors.textLight,

                              fontFamily:
                              'Poppins',

                              fontWeight:
                              FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    CircleAvatar(

                      radius: 22,

                      backgroundColor:
                      AppColors.primaryLight,

                      child: Text(

                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'U',

                        style: const TextStyle(

                          color:
                          AppColors.primary,

                          fontWeight:
                          FontWeight.w700,

                          fontFamily:
                          'Poppins',

                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── TAX FILING BANNER ─────────────────────────────────
              Padding(

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 22,
                ),

                child: ClipRRect(

                  borderRadius:
                  BorderRadius.circular(20),

                  child: Container(

                    width: double.infinity,
                    height: 180,

                    decoration: BoxDecoration(

                      borderRadius:
                      BorderRadius.circular(20),

                      boxShadow: [

                        BoxShadow(

                          color:
                          AppColors.primary.withOpacity(0.10),

                          blurRadius: 16,

                          offset:
                          const Offset(0, 6),
                        ),
                      ],

                      gradient:
                      const LinearGradient(

                        colors: [

                          Color(0xFFE8EFFF),
                          Color(0xFFD0DCFF),

                        ],

                        begin:
                        Alignment.topLeft,

                        end:
                        Alignment.bottomRight,
                      ),
                    ),

                    child: Image.asset(

                      'assets/images/tax_filing_banner.png',

                      fit: BoxFit.cover,

                      errorBuilder:
                          (_, __, ___) =>
                          _BannerFallback(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── SECTION TITLE ─────────────────────────────────────
              const Padding(

                padding:
                EdgeInsets.symmetric(
                  horizontal: 22,
                ),

                child: SectionTitle(
                  'What would you like to do?',
                ),
              ),

              const SizedBox(height: 16),

              // ── ACTION CARDS ──────────────────────────────────────
              Padding(

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 22,
                ),

                child: Column(

                  children: [

                    // START FILING CARD
                    _WideCard(

                      icon:
                      Icons.edit_document,

                      title:
                      'Start Filing',

                      subtitle:
                      'File your income tax return with expert CA assistance',

                      iconBg:
                      AppColors.primaryLight,

                      iconColor:
                      AppColors.primary,

                      onTap: () => Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) =>
                          const MembersScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SECOND ROW
                    Row(

                      children: [

                        Expanded(

                          child: _HalfCard(

                            icon:
                            Icons.receipt_long_rounded,

                            title:
                            'My Returns',

                            subtitle:
                            'Track your filed returns',

                            iconBg:
                            AppColors.accentLight,

                            iconColor:
                            AppColors.accent,

                            onTap: () => Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>
                                const MyReturnsScreen(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(

                          child: _HalfCard(

                            icon:
                            Icons.headset_mic_rounded,

                            title:
                            'Need Help?',

                            subtitle:
                            'FAQs & expert support',

                            iconBg:
                            const Color(0xFFFFF3E8),

                            iconColor:
                            const Color(0xFFF97316),

                            onTap: () => Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>
                                const NeedHelpScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _WideCard(

                      icon:
                      Icons.file_present_rounded,

                      title:
                      'Filing Results',

                      subtitle:
                      'View completed filing reports and uploaded result documents',

                      iconBg:
                      const Color(0xFFE8F0FF),

                      iconColor:
                      AppColors.primary,

                      onTap: () => Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) =>
                          const FilingResultsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FULL WIDTH CARD ───────────────────────────────────────────────────────
class _WideCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;

  final Color iconBg;
  final Color iconColor;

  final VoidCallback onTap;

  const _WideCard({

    required this.icon,
    required this.title,
    required this.subtitle,

    required this.iconBg,
    required this.iconColor,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(

          color:
          AppColors.cardBg,

          borderRadius:
          BorderRadius.circular(16),

          border: Border.all(
            color: AppColors.divider,
          ),

          boxShadow: [

            BoxShadow(

              color:
              AppColors.primary.withOpacity(0.07),

              blurRadius: 14,

              offset:
              const Offset(0, 4),
            ),
          ],
        ),

        child: Row(

          children: [

            Container(

              padding:
              const EdgeInsets.all(12),

              decoration: BoxDecoration(

                color: iconBg,

                borderRadius:
                BorderRadius.circular(12),
              ),

              child: Icon(

                icon,

                color: iconColor,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: const TextStyle(

                      fontSize: 15,

                      fontWeight:
                      FontWeight.w700,

                      color:
                      AppColors.textDark,

                      fontFamily:
                      'Poppins',
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(

                    subtitle,

                    style: const TextStyle(

                      fontSize: 12,

                      color:
                      AppColors.textLight,

                      fontFamily:
                      'Poppins',

                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(

              Icons.arrow_forward_ios_rounded,

              size: 14,

              color:
              AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ── HALF WIDTH CARD ───────────────────────────────────────────────────────
class _HalfCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;

  final Color iconBg;
  final Color iconColor;

  final VoidCallback onTap;

  const _HalfCard({

    required this.icon,
    required this.title,
    required this.subtitle,

    required this.iconBg,
    required this.iconColor,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          color:
          AppColors.cardBg,

          borderRadius:
          BorderRadius.circular(16),

          border: Border.all(
            color: AppColors.divider,
          ),

          boxShadow: [

            BoxShadow(

              color:
              Colors.black.withOpacity(0.04),

              blurRadius: 10,

              offset:
              const Offset(0, 4),
            ),
          ],
        ),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Container(

              padding:
              const EdgeInsets.all(10),

              decoration: BoxDecoration(

                color: iconBg,

                borderRadius:
                BorderRadius.circular(10),
              ),

              child: Icon(

                icon,

                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(height: 12),

            Text(

              title,

              style: const TextStyle(

                fontSize: 14,

                fontWeight:
                FontWeight.w700,

                color:
                AppColors.textDark,

                fontFamily:
                'Poppins',
              ),
            ),

            const SizedBox(height: 3),

            Text(

              subtitle,

              style: const TextStyle(

                fontSize: 11,

                color:
                AppColors.textLight,

                fontFamily:
                'Poppins',

                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BANNER FALLBACK ───────────────────────────────────────────────────────
class _BannerFallback extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,
      height: 180,

      decoration: BoxDecoration(

        borderRadius:
        BorderRadius.circular(20),

        gradient:
        const LinearGradient(

          colors: [

            AppColors.primaryLight,
            Color(0xFFD0DCFF),

          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(

            Icons.account_balance_wallet_rounded,

            size: 52,

            color:
            AppColors.primary.withOpacity(0.5),
          ),

          const SizedBox(height: 8),

          Text(

            'Add assets/images/tax_filing_banner.png',

            style: TextStyle(

              fontSize: 11,

              color:
              AppColors.primary.withOpacity(0.5),

              fontFamily:
              'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}