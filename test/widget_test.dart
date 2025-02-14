import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marianmemories/main.dart'; // Ensure main.dart exists and imports are correct

void main() {
  testWidgets('Login Page elements test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MarianMemoriesApp());

    // Verify Login Page elements
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
    expect(find.widgetWithText(MaterialButton, 'Login'), findsOneWidget);
  });
}
