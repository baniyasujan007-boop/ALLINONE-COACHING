// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:coaching_app/main.dart';
import 'package:coaching_app/providers/app_state.dart';

void main() {
  testWidgets('app renders splash', (WidgetTester tester) async {
    await tester.pumpWidget(AllInOneCoachingApp(appState: AppState()));

    expect(find.text('All in One'), findsOneWidget);
    expect(
      find.text('Learn smarter with one modern coaching platform'),
      findsOneWidget,
    );
  });
}
