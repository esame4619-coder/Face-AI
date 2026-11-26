import 'package:flutter_test/flutter_test.dart';
import 'package:face_ai/main.dart';

void main() {
  testWidgets('Arabic home screen starts successfully', (tester) async {
    await tester.pumpWidget(const MohtarifAI());
    await tester.pump();

    expect(find.text('المحترف في AI'), findsOneWidget);
    expect(find.text('عالمك الإبداعي بين إيديك'), findsOneWidget);
    expect(find.text('أدواتك الإبداعية'), findsOneWidget);
  });
}
