import 'package:flutter_test/flutter_test.dart';
import 'package:sms_gateway_app/main.dart';

void main() {
  testWidgets('SMS Gateway app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmsGatewayApp());
    expect(find.byType(SmsGatewayApp), findsOneWidget);
  });
}
