import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import '../services/customer_service.dart';
import '../services/google_auth_service.dart';
import '../services/local_storage_service.dart';

import 'auth_screen.dart';
import 'about_dtr_screen.dart';
import 'contact_support_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _loading = true;

  String name = "User";
  String email = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final customer =
    await CustomerService.getProfile();

    if (!mounted) return;

    if (customer != null) {
      setState(() {
        name = customer["name"] ?? "User";
        email = customer["email"] ?? "";
        phone = customer["phone"] ?? "";
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> logout() async {
    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Logout",
          ),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                "Logout",
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await GoogleAuthService.logout();
    await LocalStorageService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AuthScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        title: const Text(
          "More",
        ),
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : ListView(
        padding:
        const EdgeInsets.all(20),

        children: [
          Container(
            padding:
            const EdgeInsets.all(18),

            decoration:
            BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius
                  .circular(20),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(
                      0.05),
                  blurRadius: 14,
                  offset:
                  const Offset(
                      0, 5),
                ),
              ],
            ),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,

                  backgroundColor:
                  AppColors
                      .primaryLight,

                  child: Text(
                    name.isNotEmpty
                        ? name[0]
                        .toUpperCase()
                        : "U",

                    style:
                    const TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight
                          .w700,
                      color:
                      AppColors
                          .primary,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [
                      Text(
                        name,

                        style:
                        const TextStyle(
                          fontSize:
                          18,
                          fontWeight:
                          FontWeight
                              .w700,
                          color:
                          AppColors
                              .textDark,
                        ),
                      ),

                      const SizedBox(
                          height:
                          3),

                      Text(
                        email,

                        style:
                        const TextStyle(
                          fontSize:
                          13,
                          color:
                          AppColors
                              .textLight,
                        ),
                      ),

                      const SizedBox(
                          height:
                          2),

                      Text(
                        phone
                            .isEmpty
                            ? "Phone not added"
                            : phone,

                        style:
                        const TextStyle(
                          fontSize:
                          13,
                          color:
                          AppColors
                              .textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          _MenuTile(
            icon:
            Icons.info_rounded,
            title:
            "About D Tax Rail",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AboutDtrScreen(),
                ),
              );
            },
          ),

          _MenuTile(
            icon: Icons
                .support_agent_rounded,
            title:
            "Contact Support",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ContactSupportScreen(),
                ),
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _MenuTile(
            icon:
            Icons.logout_rounded,
            title: "Logout",
            danger: true,
            onTap: logout,
          ),

          const SizedBox(
            height: 30,
          ),

          const Center(
            child: Text(
              "D Tax Rail v1.0.0",
              style: TextStyle(
                fontSize: 11,
                color: AppColors
                    .textLight,
              ),
            ),
          ),
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
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
            14),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.03),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),

      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,

          decoration:
          BoxDecoration(
            color: danger
                ? Colors.red
                .withOpacity(
                0.08)
                : AppColors
                .primaryLight,

            borderRadius:
            BorderRadius
                .circular(10),
          ),

          child: Icon(
            icon,
            color: danger
                ? Colors.red
                : AppColors.primary,
            size: 18,
          ),
        ),

        title: Text(
          title,

          style: TextStyle(
            fontWeight:
            FontWeight.w600,
            fontSize: 14,
            color: danger
                ? Colors.red
                : AppColors
                .textDark,
          ),
        ),

        trailing: const Icon(
          Icons
              .arrow_forward_ios_rounded,
          size: 14,
          color:
          AppColors.textLight,
        ),

        onTap: onTap,
      ),
    );
  }
}