import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lammah/main.dart';

void main() {
  testWidgets('Farfasha app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LammahApp(),
      ),
    );
    expect(find.byType(LammahApp), findsOneWidget);
  });
}
