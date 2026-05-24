import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';

import 'welcome_screen.dart';
import 'main_navigation_screen.dart';
import 'biometric_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  bool? loggedIn;
  bool? biometricEnabled;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {

    final isLoggedIn =
    await LocalStorageService.isLoggedIn();

    final isBiometricEnabled =
    await LocalStorageService.isBiometricEnabled();

    setState(() {
      loggedIn = isLoggedIn;
      biometricEnabled = isBiometricEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (loggedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!loggedIn!) {
      return const WelcomeScreen();
    }

    if (biometricEnabled!) {
      return const BiometricScreen();
    }

    return const MainNavigationScreen();
  }
}