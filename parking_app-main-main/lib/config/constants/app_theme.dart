import 'package:flutter/material.dart';
import 'app_colors.dart'; // Import your colors

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.appBarColor,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextColor,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: AppColors.textColor),
      displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.textColor),
      headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textColor),
      bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal, color: AppColors.textColor),
      bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: AppColors.lightTextColor),
      bodySmall: TextStyle(fontSize: 12.0, color: AppColors.lightTextColor),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.buttonColor,
      textTheme: ButtonTextTheme.primary,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.primaryColor,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryColor,
      selectedItemColor: AppColors.darkTextColor,
      unselectedItemColor: AppColors.lightTextColor,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.darkBackgroundColor,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkAppBarColor,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextColor,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: AppColors.darkTextColor),
      displayMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.darkTextColor),
      headlineLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.darkTextColor),
      bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal, color: AppColors.darkTextColor),
      bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: AppColors.darkTextColor),
      bodySmall: TextStyle(fontSize: 12.0, color: AppColors.darkTextColor),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.buttonColor,
      textTheme: ButtonTextTheme.primary,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.primaryColor,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkAppBarColor,
      selectedItemColor: AppColors.darkTextColor,
      unselectedItemColor: AppColors.lightTextColor,
    ),
  );
}
