import 'package:flutter/material.dart';

class ThemesListItem{
  String _id;
  String _name;
  MaterialColor _colors;
  ThemesListItem(String id, String name, MaterialColor colors){
    _id = id;
    _name = name;
    _colors = colors;
  }
  String name(){
    return _name;
  }
  MaterialColor colors() {
    return _colors;
  }
  String id() {
    return _id;
  }
}

// Generated using Material Design Palette/Theme Generator
// http://mcg.mbitson.com/
// https://github.com/mbitson/mcg

List<ThemesListItem> themes = [
  new ThemesListItem(
    '0',
    'Purple',
    MaterialColor
      (0xFF351C75,
        const <int,Color>{
          50: Color(0xFFE7E4EE),
          100: Color(0xFFC2BBD6),
          200: Color(0xFF9A8EBA),
          300: Color(0xFF72609E),
          400: Color(0xFF533E8A),
          500: Color(0xFF351C75),
          600: Color(0xFF30196D),
          700: Color(0xFF281462),
          800: Color(0xFF221158),
          900: Color(0xFF160945),
        }
    ),
  ),
  new ThemesListItem(
    '1',
    'Blue',
    MaterialColor(
      0xFF395afa,
      const <int, Color>{
        50: const Color(0xFFE7EBFE),
        100: const Color(0xFFC4CEFE),
        200: const Color(0xFF9CADFD),
        300: const Color(0xFF748CFC),
        400: const Color(0xFF5773FB),
        500: const Color(0xFF395afa),
        600: const Color(0xFF3352F9),
        700: const Color(0xFF2C48F9),
        800: const Color(0xFF243FF8),
        900: const Color(0xFF172EF6),
      },
    ),
  ),
  new ThemesListItem(
    '2',
    'Green',
    const MaterialColor(0xFF26A69A, <int, Color>{
      50: Color(0xFFE5F4F3),
      100: Color(0xFFBEE4E1),
      200: Color(0xFF93D3CD),
      300: Color(0xFF67C1B8),
      400: Color(0xFF47B3A9),
      500: Color(0xFF26A69A),
      600: Color(0xFF229E92),
      700: Color(0xFF1C9588),
      800: Color(0xFF178B7E),
      900: Color(0xFF0D7B6C),
    })
  )
];
