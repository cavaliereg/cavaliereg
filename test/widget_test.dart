// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tentata_vendita_italiana/main.dart';
import 'package:tentata_vendita_italiana/state/sales_app_state.dart';

void main() {
  testWidgets('shows offline sales dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SalesAppState(),
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Tentata vendita italiana'), findsOneWidget);
    expect(find.text('Catalogo'), findsOneWidget);
    expect(find.text('Sincronizza sede'), findsOneWidget);
  });
}
