import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamdo/app.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GamdoApp(),
      ),
    );
    // Verify splash screen renders
    expect(find.text('감도'), findsOneWidget);
  });
}
