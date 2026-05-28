import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:dio/dio.dart';

import '../theme/app_theme.dart';

import 'main_navigation_screen.dart';
import '../config/api_config.dart';

class CompleteProfileScreen
    extends StatefulWidget {

  const CompleteProfileScreen({
    super.key,
  });

  @override
  State<CompleteProfileScreen>
  createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {

  final TextEditingController
  phoneController =
  TextEditingController();

  bool loading = false;

  Future<void> savePhone() async {

    try {

      setState(() {
        loading = true;
      });

      final phone =
      phoneController.text.trim();

      if (
      phone.isEmpty ||
          phone.length != 10 ||
          !RegExp(r'^[0-9]+$')
              .hasMatch(phone)
      ) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Enter valid 10-digit phone number",
            ),
          ),
        );

        return;
      }

      final token =
      await FirebaseAuth
          .instance
          .currentUser!
          .getIdToken();

      await Dio().post(

        '${ApiConfig.baseUrl}/customers/update-phone',

        data: {
          "phone": phone,
        },

        options: Options(

          headers: {
            'Authorization':
            'Bearer $token',
          },
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(
          builder: (_) =>
          const MainNavigationScreen(),
        ),

            (route) => false,
      );

    } catch (e) {

      print(e);

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Failed to save phone",
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      AppColors.background,

      body: SafeArea(

        child: Padding(

          padding:
          const EdgeInsets.symmetric(
            horizontal: 28,
          ),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 60),

              Container(

                width: 72,
                height: 72,

                decoration: BoxDecoration(

                  gradient:
                  const LinearGradient(

                    colors: [

                      AppColors.primary,

                      AppColors.primaryDark,
                    ],
                  ),

                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: const Icon(

                  Icons.phone_rounded,

                  color: Colors.white,

                  size: 34,
                ),
              ),

              const SizedBox(height: 36),

              const Text(

                "Complete Your Profile",

                style: TextStyle(

                  fontSize: 32,

                  fontWeight:
                  FontWeight.w700,

                  color:
                  AppColors.textDark,
                ),
              ),

              const SizedBox(height: 14),

              const Text(

                "Add your phone number for filing updates and customer support.",

                style: TextStyle(

                  fontSize: 15,

                  color:
                  AppColors.textMid,

                  height: 1.6,
                ),
              ),

              const SizedBox(height: 42),

              TextField(

                controller:
                phoneController,

                keyboardType:
                TextInputType.phone,

                decoration:
                InputDecoration(

                  hintText:
                  "Enter phone number",

                  prefixIcon:
                  const Icon(
                    Icons.phone,
                  ),

                  border:
                  OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(

                width: double.infinity,

                height: 56,

                child: ElevatedButton(

                  onPressed:
                  loading
                      ? null
                      : savePhone,

                  child: loading

                      ? const SizedBox(

                    width: 22,
                    height: 22,

                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.white,
                    ),
                  )

                      : const Text(

                    "Continue",

                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
