import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class InstagramUpdatesScreen extends StatelessWidget {
  const InstagramUpdatesScreen({super.key});

  Future<void> _openInstagram() async {
    await launchUrl(
      Uri.parse(
        "https://www.instagram.com/dtr_dtaxrail",
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          "Latest Tax Updates",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),

                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: const Column(
                children: [

                  Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 54,
                  ),

                  SizedBox(height: 14),

                  Text(
                    "Stay Updated With Income Tax News",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Get tax filing reminders, government notifications, due date alerts and tax-saving tips directly from D Tax Rail.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),

                border: Border.all(
                  color: AppColors.divider,
                ),
              ),

              child: Column(
                children: [

                  Container(
                    width: 80,
                    height: 80,

                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.purple,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Follow D Tax Rail",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "@dtr_dtaxrail",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "For latest Income Tax updates, filing reminders, government notifications and tax saving tips, follow our Instagram page.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMid,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openInstagram,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text(
                        "Open Instagram",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}