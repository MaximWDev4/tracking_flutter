import 'package:flutter/material.dart';

import 'src/pages/home-page.dart';
import 'src/pages/animated_map_controller.dart';
import 'src/pages/esri.dart';
import 'src/pages/map.dart';
import 'src/pages/map_controller.dart';
import 'src/pages/offline_map.dart';
import 'src/pages/overlay_image.dart';
import 'src/pages/plugin_api.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Example',
      theme: ThemeData(
        primarySwatch: ColorMap,
      ),
      home: MapPage(),
      routes: <String, WidgetBuilder>{
        EsriPage.route: (context) => EsriPage(),
        MapControllerPage.route: (context) => MapControllerPage(),
        AnimatedMapControllerPage.route: (context) =>
            AnimatedMapControllerPage(),
        PluginPage.route: (context) => PluginPage(),
        OfflineMapPage.route: (context) => OfflineMapPage(),
        MyHomePage.route: (context) => MyHomePage(),
        OverlayImagePage.route: (context) => OverlayImagePage(),
      },
    );
  }
}

// Generated using Material Design Palette/Theme Generator
// http://mcg.mbitson.com/
// https://github.com/mbitson/mcg
const int _bluePrimary = 0xFF395afa;
const MaterialColor mapBoxBlue = const MaterialColor(
  _bluePrimary,
  const <int, Color>{
    50: const Color(0xFFE7EBFE),
    100: const Color(0xFFC4CEFE),
    200: const Color(0xFF9CADFD),
    300: const Color(0xFF748CFC),
    400: const Color(0xFF5773FB),
    500: const Color(_bluePrimary),
    600: const Color(0xFF3352F9),
    700: const Color(0xFF2C48F9),
    800: const Color(0xFF243FF8),
    900: const Color(0xFF172EF6),
  },
);
const int _PurplePrimary = 0xFF351C75;
const MaterialColor mapBoxPurple = MaterialColor(
    _PurplePrimary,
    <int, Color>{
      50: Color(0xFFE7E4EE),
      100: Color(0xFFC2BBD6),
      200: Color(0xFF9A8EBA),
      300: Color(0xFF72609E),
      400: Color(0xFF533E8A),
      500: Color(_PurplePrimary),
      600: Color(0xFF30196D),
      700: Color(0xFF281462),
      800: Color(0xFF221158),
      900: Color(0xFF160945),
    }
);

const ColorMap = mapBoxPurple;
