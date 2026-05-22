import 'package:flutter/material.dart';

class AppPadding {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

class AppDuration {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);
}

/// Brand color palette — modern indigo/violet feel.
class AppColors {
  static const primary = Color(0xFF6366F1);          // indigo-500
  static const primaryDark = Color(0xFF4F46E5);      // indigo-600
  static const secondary = Color(0xFF8B5CF6);        // violet-500
  static const accent = Color(0xFFEC4899);           // pink-500
  static const success = Color(0xFF10B981);          // emerald-500
  static const warning = Color(0xFFF59E0B);          // amber-500
  static const danger = Color(0xFFEF4444);           // red-500
  static const info = Color(0xFF06B6D4);             // cyan-500

  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Colors.white;
  static const darkBg = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF141A2E);
}

class MotivationalQuotes {
  static const List<String> all = [
    'Small steps every day lead to big results.',
    'Discipline is choosing what you want most over what you want now.',
    'Success is the sum of small efforts repeated daily.',
    'The expert in anything was once a beginner.',
    'Don\'t watch the clock; do what it does — keep going.',
    'You don\'t have to be great to start, but you have to start to be great.',
    'Push yourself, because no one else is going to do it for you.',
    'Your only limit is your mind.',
    'Dream it. Plan it. Do it.',
    'Hard work beats talent when talent doesn\'t work hard.',
  ];
}
