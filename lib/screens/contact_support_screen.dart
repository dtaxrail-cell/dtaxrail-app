import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  Future<void> _openUrl(String url) async {
    try {
      print("OPENING: $url");

      final uri = Uri.parse(url);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      print("LAUNCHED: $launched");
    } catch (e) {
      print("URL ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Contact Support"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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

              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    "We're Here To Help",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Reach out to us through any of the channels below and our team will assist you.",
                    style: TextStyle(
                      color: AppColors.textMid,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// EMAIL
            _clickableTile(
              icon: Icons.email_rounded,
              title: "Email",
              value: "support@dtaxrail.in",
              onTap: () => _openUrl(
                "mailto:support@dtaxrail.in",
              ),
            ),

// WHATSAPP
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "WhatsApp Support",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Chat with our support team directly on WhatsApp.",
                    style: TextStyle(
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ElevatedButton.icon(
                    onPressed: () => _openUrl(
                      "https://wa.me/918187882772",
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text(
                      "Open WhatsApp",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

// PHONE
            _clickableTile(
              icon: Icons.phone_rounded,
              title: "Phone",
              value: "8187882772",
              onTap: () => _openUrl(
                "tel:8187882772",
              ),
            ),

// INSTAGRAM
            _clickableTile(
              icon: Icons.camera_alt_rounded,
              title: "Instagram",
              value: "@dtaxrail",
              onTap: () => _openUrl(
                "https://www.instagram.com/dtr_dtaxrail",
              ),
            ),

// WEBSITE
            _clickableTile(
              icon: Icons.language_rounded,
              title: "Website",
              value: "www.dtaxrail.com",
              onTap: () => _openUrl(
                "https://www.dtaxrail.com",
              ),
            ),

// OFFICE ADDRESS
            _infoTile(
              Icons.location_on_rounded,
              "Office Address",
              "49-107, Manda Street, Bobbili\nVizianagaram, AP - 535558",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _clickableTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Icon(
              icon,
              color: AppColors.primary,
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
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: AppColors.divider,
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: AppColors.primary,
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
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textMid,
                    height: 1.5,
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