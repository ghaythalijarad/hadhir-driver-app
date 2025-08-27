import 'package:flutter/material.dart';

import 'new_login_screen.dart';

/// Wrapper class to maintain backward compatibility with old routes/imports.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const NewLoginScreen();
}
