import 'package:flutter/material.dart';

// This file has helper functions to manage the app better

// This extends the string type to add a method named capitalize
//   that returns the string with the first letter capitalized
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

extension Colory on Color {
  MaterialColor createMaterialColor() {
    List strengths = <double>[.05];
    Map swatch = <int, Color>{};
    final int r = this.red, g = this.green, b = this.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    strengths.forEach((strength) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    });
    return MaterialColor(this.value, swatch);
  }
}
