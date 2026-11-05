import 'package:finance_tracker/data/wallet_repository.dart';
import 'package:finance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

FinanceTrackerApp _appWith(MockClient client) => FinanceTrackerApp(
  repository: WalletRepository(
    baseUrl: 'http://test',
    tokenProvider: () async => null,
    client: client,
  ),
);

/// The design is a desktop layout, so test on a desktop-sized screen.
void _useDesktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('shows one card per wallet, each in its own currency', (
    tester,
  ) async {
    _useDesktopSize(tester);
    final client = MockClient((request) async {
      expect(request.url.path, '/wallets');
      return http.Response(
        '[{"id":1,"name":"Cash #1","type":"cash","currency":"EUR","balance":100},'
        '{"id":2,"name":"Travel","type":"bank card","currency":"RUB","balance":5000}]',
        200,
      );
    });

    await tester.pumpWidget(_appWith(client));
    await tester.pumpAndSettle();

    expect(find.text('Cash #1'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('100.00'), findsOneWidget);
    expect(find.text('5,000.00'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('RUB'), findsOneWidget);
    expect(find.text('Add wallet'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no wallets', (
    tester,
  ) async {
    _useDesktopSize(tester);
    final client = MockClient((request) async => http.Response('[]', 200));

    await tester.pumpWidget(_appWith(client));
    await tester.pumpAndSettle();

    expect(find.text('No wallets yet.'), findsOneWidget);
    // One button in the header, one in the empty state.
    expect(find.text('Add wallet'), findsNWidgets(2));
  });

  testWidgets('shows a loading state before the data arrives', (tester) async {
    _useDesktopSize(tester);
    final client = MockClient((request) async => http.Response('[]', 200));

    await tester.pumpWidget(_appWith(client));
    // No settle yet: the request has not finished.

    expect(find.text('Loading your wallets...'), findsOneWidget);
    expect(find.text('No wallets yet.'), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('shows the error state and can retry', (tester) async {
    _useDesktopSize(tester);
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) return http.Response('boom', 500);
      return http.Response(
        '[{"id":1,"name":"Cash #1","type":"cash","currency":"USD","balance":10}]',
        200,
      );
    });

    await tester.pumpWidget(_appWith(client));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your wallets.'), findsOneWidget);
    expect(find.text('Add wallet'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your wallets.'), findsNothing);
    expect(find.text('Cash #1'), findsOneWidget);
  });
}
