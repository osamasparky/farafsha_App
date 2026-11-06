import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lammah/main.dart';

void main() {
  testWidgets('Lammah smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LammahApp(),
      ),
    );
    expect(find.text('لمّة'), findsOneWidget);
  });
}
