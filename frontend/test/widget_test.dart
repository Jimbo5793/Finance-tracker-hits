import 'package:finance_tracker/data/wallet_repository.dart';
import 'package:finance_tracker/data/auth_session.dart';
import 'package:finance_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:async';

FinanceTrackerApp _appWith(MockClient client) => FinanceTrackerApp(
  session: AuthSession(token: 't', expiresAt: DateTime.utc(2999)),
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
  testWidgets('shows a loading state before the data arrives', (tester) async {
    _useDesktopSize(tester);
    final response = Completer<http.Response>();
    final client = MockClient((request) => response.future);

    await tester.pumpWidget(_appWith(client));
    await tester.pump(); // the router opens /wallets

    expect(find.text('Loading your wallets...'), findsOneWidget);
    expect(find.text('No wallets yet.'), findsNothing);

    response.complete(http.Response('[]', 200));
    await tester.pumpAndSettle();
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
