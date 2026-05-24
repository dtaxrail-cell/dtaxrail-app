import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'More',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile card ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primaryLight,
                  child: const Text(
                    'P',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priyanka',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'priyanka@gmail.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '+91 9876543210',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ── Menu items ────────────────────────────────────────────────
          _MenuTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.info_rounded,
            title: 'About DTR',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.support_agent_rounded,
            title: 'Contact Support',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            onTap: () {},
          ),

          _MenuTile(
            icon: Icons.security_rounded,
            title: 'Security & Privacy',
            onTap: () {},
          ),

          const SizedBox(height: 8),

          _MenuTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            danger: true,
            onTap: () {},
          ),

          const SizedBox(height: 30),

          // ── App version ───────────────────────────────────────────────
          const Center(
            child: Text(
              'DTR v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: danger
                ? Colors.red.withOpacity(0.08)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: danger ? Colors.red : AppColors.primary,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: danger ? Colors.red : AppColors.textDark,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textLight,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}