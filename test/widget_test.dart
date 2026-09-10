import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/app.dart';

void main() {
  testWidgets('PerfinaxApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PerfinaxApp());
    expect(find.text('PERFINAX'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('PERFINAX'), findsWidgets);
  });
}
