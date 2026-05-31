import 'package:flutter/material.dart';

import '../core/theme/izes_theme.dart';
import '../core/services/auth_service.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/home/presentation/pages/izes_home_page.dart';

class IzesApp extends StatelessWidget {
  const IzesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return AnimatedBuilder(
      animation: authService,
      builder: (context, _) => MaterialApp(
        title: 'IZES',
        debugShowCheckedModeBanner: false,
        theme: IzesTheme.light(),
        home: authService.isAuthenticated
            ? const IzesHomePage()
            : const LoginPage(),
      ),
    );
  }
}
