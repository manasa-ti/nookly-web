// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nookly/presentation/widgets/distance_radius_slider.dart';

void main() {
  testWidgets('Distance radius slider widget test', (WidgetTester tester) async {
    double currentValue = 40.0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DistanceRadiusSlider(
            value: currentValue,
            onChanged: (value) {
              currentValue = value;
            },
          ),
        ),
      ),
    );

    // Verify that the slider is displayed
    expect(find.text('Preferred Distance Radius'), findsOneWidget);
    expect(find.text('40 km'), findsOneWidget);
    expect(find.text('1 km'), findsOneWidget);
    expect(find.text('500 km'), findsOneWidget);

    // Verify that the slider widget exists
    expect(find.byType(Slider), findsOneWidget);
  });
}
