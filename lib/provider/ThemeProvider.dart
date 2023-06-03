import 'package:flutter/material.dart';
import 'package:taskwarrior/widgets/pallete.dart';

class ThemeProvider extends ChangeNotifier {
  static ThemeMode themeMode = ThemeMode.dark;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  static ThemeData get theme =>
      themeMode == ThemeMode.dark ? MyThemes.darkTheme : MyThemes.lightTheme;

  void toggleTheme() {
    if (themeMode == ThemeMode.dark) {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    primaryColorDark: Colors.black,
    primaryColorLight: Colors.black,
    scaffoldBackgroundColor: const Color(0xff305067),
    textTheme: const TextTheme().apply(
      displayColor: Colors.black,
      bodyColor: Colors.black,
    ),
    canvasColor: Colors.transparent,
    dialogBackgroundColor: const Color(0xff2A3342),
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(
        color: Palette.kToDark.shade200,
      ),
    ),
    // Add the following lines to customize text color and list tile background
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Colors.black, // Customize text selection color
      cursorColor: Colors.black, // Customize cursor color
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.black, // Customize list tile background color
    ),
  );

  static final lightTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    primaryColorDark: Colors.black,
    primaryColorLight: Colors.black,
    scaffoldBackgroundColor: const Color(0xff305067),
    textTheme: const TextTheme().apply(
      displayColor: Colors.black,
      bodyColor: Colors.black,
    ),
    canvasColor: Colors.transparent,
    dialogBackgroundColor: const Color(0xff2A3342),
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(
        color: Palette.kToDark.shade200,
      ),
    ),
    // Add the following lines to customize text color and list tile background
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: Colors.black, // Customize text selection color
      cursorColor: Colors.black, // Customize cursor color
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.black, // Customize list tile background color
    ),
  );
}
