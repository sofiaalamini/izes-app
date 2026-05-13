import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/app/izes_app.dart';

void main() {
  testWidgets('renders IZES home shell', (tester) async {
    await tester.pumpWidget(const IzesApp());

    expect(find.text('IZES'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
  });
}
