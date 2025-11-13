import 'package:flutter/material.dart';

const Color kBg = Color(0xFFFFFDF5);
const Color kPrimary = Color(0xFF364C84);
const Color kAccent = Color(0xFFFFD54A);

final ThemeData tutorTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: kPrimary,
    secondary: kAccent,
    surface: kBg,
  ),
  scaffoldBackgroundColor: kBg,
  appBarTheme: const AppBarTheme(
    backgroundColor: kBg,
    foregroundColor: kPrimary,
    elevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
    ),
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: kBg,
    selectedColor: kAccent,
    labelStyle: TextStyle(color: kPrimary),
    side: BorderSide(color: kPrimary, width: 1),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: kPrimary),
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: kPrimary.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: kPrimary, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
