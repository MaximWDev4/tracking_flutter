import 'package:flutter/material.dart';
import 'src/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/pages/home-page.dart';
import 'src/pages/map.dart';
import 'src/pages/map_controller.dart';
import 'package:get/get.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Map Example',
      // theme: ThemeData(
      //   primarySwatch: ColorMap,
      // ),
      theme: ThemeData.light().copyWith(primaryColor: Colors.green),
      darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.purple, backgroundColor: Colors.black38),
      // NOTE: Optional - use themeMode to specify the startup theme
      themeMode: ThemeMode.system,
      home: MapPage(),
      routes: <String, WidgetBuilder>{
        MapControllerPage.route: (context) => MapControllerPage(),
        MyHomePage.route: (context) => MyHomePage(),
      },
    );
  }
}

// Generated using Material Design Palette/Theme Generator
// http://mcg.mbitson.com/
// https://github.com/mbitson/mcg

ThemeData ColorMap = ThemeData.dark().copyWith(primaryColor: Colors.purple);
