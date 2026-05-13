import 'package:flutter/material.dart';

import '../core/theme/izes_theme.dart';
import '../features/home/presentation/pages/izes_home_page.dart';

class IzesApp extends StatelessWidget {
  const IzesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IZES',
      debugShowCheckedModeBanner: false,
      theme: IzesTheme.light(),
      home: const IzesHomePage(),
    );
  }
}
