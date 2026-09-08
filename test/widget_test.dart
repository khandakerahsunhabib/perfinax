import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/app.dart';

void main() {
  testWidgets('PerfinaxApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PerfinaxApp());
    expect(find.text('PERFINAX'), findsWidgets);
  });
}
