import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/app/izes_app.dart';
import 'package:izesapp/core/services/auth_service.dart';

void main() {
  testWidgets('sem sessão o app abre na tela de login', (tester) async {
    AuthService().logout();

    await tester.pumpWidget(const IzesApp());

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Dashboard'), findsNothing);
  });
}
