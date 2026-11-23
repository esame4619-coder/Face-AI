import 'package:flutter_test/flutter_test.dart';
import 'package:face_ai/main.dart';

void main() {
  testWidgets('Mohtarif AI app starts and shows its title', (tester) async {
    await tester.pumpWidget(const MohtarifAI());
    expect(find.text('المحترف في AI'), findsWidgets);
  });
}
