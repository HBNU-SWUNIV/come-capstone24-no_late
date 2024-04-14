import 'package:flutter/material.dart';
import 'package:hanbat_capstone/screen/root_screen.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        )
      ),
      home: RootScreen()
    )
  );
}