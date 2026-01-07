import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kompagni/shared/widgets/widgets.dart';

void main() {
  group('ErrorView', () {
    testWidgets('should display message and retry button', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Test error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Verify message is displayed
      expect(find.text('Test error message'), findsOneWidget);

      // Verify retry button exists
      expect(find.text('Réessayer'), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('should display icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(message: 'Error'),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display details when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Error',
              details: 'Detailed error info',
            ),
          ),
        ),
      );

      expect(find.text('Detailed error info'), findsOneWidget);
    });

    testWidgets('should hide retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(message: 'Error'),
          ),
        ),
      );

      expect(find.text('Réessayer'), findsNothing);
    });
  });

  group('EmptyState', () {
    testWidgets('should display icon, title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.pets,
              title: 'No pets',
              subtitle: 'Add your first pet',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.text('No pets'), findsOneWidget);
      expect(find.text('Add your first pet'), findsOneWidget);
    });

    testWidgets('should display action button when provided', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.pets,
              title: 'No pets',
              actionLabel: 'Add Pet',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Pet'), findsOneWidget);

      await tester.tap(find.text('Add Pet'));
      await tester.pump();

      expect(actionPressed, isTrue);
    });
  });

  group('LoadingView', () {
    testWidgets('should display spinner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(message: 'Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}
