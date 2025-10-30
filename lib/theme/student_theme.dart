import 'package:flutter/material.dart';

const kStudentBg = Color(0xFFF6E9D9); // Almond Cream
const kStudentDeep = Color(0xFF043222); // Evergreen Shadow

final studentTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: kStudentDeep,
    onPrimary: Colors.white,
    secondary: kStudentDeep,
    onSecondary: Colors.white,
    error: Colors.red.shade700,
    onError: Colors.white,
    surface: kStudentBg,
    onSurface: kStudentDeep,
  ),
  scaffoldBackgroundColor: kStudentBg,
  appBarTheme: AppBarTheme(
    backgroundColor: kStudentBg,
    foregroundColor: kStudentDeep,
    elevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kStudentDeep,
      foregroundColor: Colors.white,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kStudentDeep,
      side: BorderSide(color: kStudentDeep),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: kStudentDeep.withValues(alpha: 0.1),
    labelStyle: const TextStyle(color: kStudentDeep),
    side: const BorderSide(color: kStudentDeep),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: kStudentDeep,
    unselectedItemColor: kStudentDeep.withValues(alpha: 0.4),
  ),
);
