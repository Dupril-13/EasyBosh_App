/*import 'package:easybosh_v2/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Test', () {
    testWidgets('Login scenario and navigation to course page', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const MyApp());
      // Wait for the app to settle (e.g., finish animations)
      await tester.pumpAndSettle();

      // Find the email and password text fields and the login button.
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      final loginButton = find.byType(ElevatedButton);

      // Verify that we are on the login page by checking for the login button.
      expect(loginButton, findsOneWidget);

      // Enter text into the email and password fields.
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap the login button.
      await tester.tap(loginButton);
      // Wait for navigation and animations to complete.
      await tester.pumpAndSettle();

      // After login, we expect to be on the course page.
      // We can verify this by looking for a widget we know is on that page, like the title.
      expect(find.text('Mes Matières'), findsOneWidget);
    });
  });
}*/