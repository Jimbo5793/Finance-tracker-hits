import 'package:finance_tracker/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows the title and the API status', (tester) async {
    final client = MockClient(
      (request) async => http.Response('{"status":"ok"}', 200),
    );

    await tester.pumpWidget(FinanceTrackerApp(client: client));
    await tester.pumpAndSettle();

    expect(find.text('Personal Finance Tracker'), findsOneWidget);
    expect(find.text('API status: ok'), findsOneWidget);
  });
}
