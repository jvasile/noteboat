import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noteboat/main.dart';

void main() {
  testWidgets('App initializes with Noteboat title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteboatApp());
    await tester.pump();

    // Verify that the app title appears
    expect(find.text('Noteboat'), findsOneWidget);
    expect(find.text('Linked Notes'), findsOneWidget);
    expect(find.byIcon(Icons.sailing), findsOneWidget);
  });
}
