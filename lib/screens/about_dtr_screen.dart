import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutDtrScreen extends StatelessWidget {
  const AboutDtrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("About D Tax Rail"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "D Tax Rail",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Simple • Smart • Secure Tax Solutions",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Making tax filing simple and stress-free with expert support and secure technology.",
              style: TextStyle(
                height: 1.5,
                color: AppColors.textMid,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            _FeatureCard(
              icon: Icons.description_rounded,
              title: "Easy Tax Filing",
              subtitle:
              "Simplified filing process for individuals and businesses.",
            ),

            _FeatureCard(
              icon: Icons.account_balance_rounded,
              title: "CA Assistance",
              subtitle:
              "Expert Chartered Accountant support whenever needed.",
            ),

            _FeatureCard(
              icon: Icons.cloud_upload_rounded,
              title: "Secure Documents",
              subtitle:
              "Upload and manage tax documents safely.",
            ),

            _FeatureCard(
              icon: Icons.track_changes_rounded,
              title: "Real-Time Tracking",
              subtitle:
              "Track filing progress and status updates instantly.",
            ),

            _FeatureCard(
              icon: Icons.flash_on_rounded,
              title: "Fast Processing",
              subtitle:
              "Designed to make filing quick and hassle-free.",
            ),

            _FeatureCard(
              icon: Icons.lock_rounded,
              title: "Privacy First",
              subtitle:
              "Your data is protected with secure handling practices.",
            ),

            _FeatureCard(
              icon: Icons.support_agent_rounded,
              title: "Dedicated Support",
              subtitle:
              "Quick assistance whenever you need help.",
            ),

            _FeatureCard(
              icon: Icons.verified_rounded,
              title: "Trusted Platform",
              subtitle:
              "Built to make tax filing easier and more accessible.",
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Column(
                children: [

                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Our Goal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "To help every taxpayer file confidently with the support of technology and qualified tax professionals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.6,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.divider,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMid,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}