import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../services/customer_service.dart';
import '../services/google_auth_service.dart';
import '../services/local_storage_service.dart';

import 'auth_screen.dart';
import 'about_dtr_screen.dart';
import 'contact_support_screen.dart';
import 'government_deadlines_screen.dart';
import 'instagram_updates_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _loading = true;

  String name  = "User";
  String email = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final customer = await CustomerService.getProfile();
    if (!mounted) return;
    if (customer != null) {
      setState(() {
        name  = customer["name"]  ?? "User";
        email = customer["email"] ?? "";
        phone = customer["phone"] ?? "";
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await GoogleAuthService.logout();
    await LocalStorageService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
    );
  }

  // ── Delete Account ────────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {

    // Step 1: First confirmation
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text(
              "Delete Account",
              style: TextStyle(
                color:      Colors.red,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        content: const Text(
          "This will permanently delete your account, all your members, filings, and uploaded documents.\n\nThis action cannot be undone.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    // Step 2: Second confirmation — type to confirm
    final TextEditingController confirmCtrl = TextEditingController();
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Are you absolutely sure?",
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type "DELETE" below to confirm:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                autofocus:  true,
                decoration: InputDecoration(
                  hintText:    "DELETE",
                  border:      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   const BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmCtrl.text.trim() == "DELETE"
                    ? Colors.red
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: confirmCtrl.text.trim() == "DELETE"
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text("Permanently Delete"),
            ),
          ],
        ),
      ),
    );

    if (confirm2 != true) return;

    // Step 3: Show loading and call API
    if (!mounted) return;
    showDialog(
      context:     context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    try {

      final user  = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final token = await user.getIdToken();

      // Call backend — deletes all DB data
      final response = await Dio().delete(
        '${ApiConfig.baseUrl}/auth/delete-account',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data['success'] == true) {

        // Delete Firebase Auth account
        await user.delete();

        // Clear local storage
        await LocalStorageService.logout();

        if (!mounted) return;

        // Dismiss loading dialog
        Navigator.pop(context);

        // Navigate to auth screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully"),
            backgroundColor: Colors.red,
          ),
        );

      } else {
        if (!mounted) return;
        Navigator.pop(context); // dismiss loading
        _showError("Failed to delete account. Please try again.");
      }

    } on FirebaseAuthException catch (e) {

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      // Firebase requires recent login for account deletion
      if (e.code == 'requires-recent-login') {
        _showError(
          "For security, please log out and log back in before deleting your account.",
        );
      } else {
        _showError("Firebase error: ${e.message}");
      }

    } catch (e) {

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      _showError("Something went wrong. Please try again.");
      debugPrint("DELETE ACCOUNT ERROR: $e");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("More")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Profile card ───────────────────────────────────────────
          Container(
            padding:    const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset:     const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius:          34,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "U",
                    style: const TextStyle(
                      fontSize:   24,
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone.isEmpty ? "Phone not added" : phone,
                        style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Menu items ─────────────────────────────────────────────
          _MenuTile(
            icon:  Icons.info_rounded,
            title: "About D Tax Rail",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutDtrScreen()),
            ),
          ),
          _MenuTile(
            icon:  Icons.payments_rounded,
            title: "Pricing and Processes",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PricingScreen()),
            ),
          ),
          _MenuTile(
            icon:  Icons.support_agent_rounded,
            title: "Contact Support",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
            ),
          ),
          _MenuTile(
            icon:  Icons.calendar_month_rounded,
            title: "Government Deadlines",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GovernmentDeadlinesScreen()),
            ),
          ),
          _MenuTile(
            icon:  Icons.campaign_rounded,
            title: "Latest Income Tax Updates",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstagramUpdatesScreen()),
            ),
          ),

          const SizedBox(height: 8),

          _MenuTile(
            icon:   Icons.logout_rounded,
            title:  "Logout",
            danger: true,
            onTap:  logout,
          ),

          // ── Delete Account — below logout ──────────────────────────
          _MenuTile(
            icon:   Icons.delete_forever_rounded,
            title:  "Delete Account",
            danger: true,
            onTap:  _deleteAccount,
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              "D Tax Rail v1.0.0",
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MENU TILE
// ─────────────────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData   icon;
  final String     title;
  final bool       danger;
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
      margin:     const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color:        danger
                ? Colors.red.withOpacity(0.08)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: danger ? Colors.red : AppColors.primary,
            size:  18,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   14,
            color:      danger ? Colors.red : AppColors.textDark,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size:  14,
          color: AppColors.textLight,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRICING SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _PricingScreen extends StatelessWidget {
  const _PricingScreen();

  static const _rows = [
    _ItrRow('ITR-1', 'From ₹700',
        'For salaried individuals and pensioners with a total annual income under ₹50 Lakhs.'),
    _ItrRow('ITR-2', 'From ₹1,500',
        'For individuals with income over ₹50 Lakhs, capital gains (stocks/mutual funds), foreign assets, or multiple house properties.'),
    _ItrRow('ITR-3', 'From ₹3,000',
        'For individuals having income from a business, profession, or trading activities like F&O and Crypto.'),
    _ItrRow('ITR-4', 'From ₹1,000',
        'For individuals, HUFs, and firms opting for Presumptive Tax Schemes (Sec 44AD/44ADA) to declare income on a turnover basis.'),
    _ItrRow('ITR-5', 'From ₹5,000',
        'For registered business entities including Partnerships, LLPs, AOPs, and BOIs.'),
    _ItrRow('ITR-6', 'From ₹10,000',
        'For incorporated Corporates and Companies (excluding entities claiming exemption under Section 11).'),
    _ItrRow('ITR-7', 'From ₹7,000',
        'For specialized entities like Charitable Trusts, Political Parties, Religious Institutions, and Educational Societies.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pricing and Processes'),
        leading: const BackButton(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header note ──────────────────────────────────────────
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '💡 Prices shown are starting rates. Final fee depends on complexity and additional services.',
                style: TextStyle(
                  fontSize:   12,
                  color:      AppColors.primary,
                  fontFamily: 'Poppins',
                  height:     1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Table ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset:     const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [

                    // Header row
                    Container(
                      color:   AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Type',
                              style: TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize:   13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: Text(
                              'Fees',
                              style: TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize:   13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Details',
                              style: TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize:   13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Data rows
                    ..._rows.asMap().entries.map((entry) {
                      final i   = entry.key;
                      final row = entry.value;
                      final isEven = i % 2 == 0;

                      return Container(
                        color:   isEven ? Colors.white : const Color(0xFFF8FAFF),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ITR type badge
                            SizedBox(
                              width: 60,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:        AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border:       Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  row.type,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize:   12,
                                    color:      AppColors.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Fee
                            SizedBox(
                              width: 90,
                              child: Text(
                                row.fee,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize:   13,
                                  color:      Color(0xFF16A34A),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Text(
                                row.details,
                                style: const TextStyle(
                                  fontSize:   12,
                                  color:      AppColors.textMid,
                                  fontFamily: 'Poppins',
                                  height:     1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Footer note ──────────────────────────────────────────
            const Center(
              child: Text(
                '* All prices are inclusive of GST where applicable.\nContact support for bulk or business pricing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   11,
                  color:      AppColors.textLight,
                  fontFamily: 'Poppins',
                  height:     1.6,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ItrRow {
  final String type;
  final String fee;
  final String details;
  const _ItrRow(this.type, this.fee, this.details);
}