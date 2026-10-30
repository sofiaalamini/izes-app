import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/izes_app.dart';
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    debugPrint('Falha ao carregar .env: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  await restoreSessionSafely(AuthService().restoreSession);

  runApp(const IzesApp());
}
