import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/pages/home-page.dart';
import 'src/pages/map.dart';
import 'src/pages/map_controller.dart';
import 'package:get/get.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  String theme = '1';
  getUserTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    theme = prefs.getString('theme');
    print(theme);
  }

  @override
  Widget build(BuildContext context) {
    getUserTheme();
    return GetMaterialApp(
      title: 'Flutter Map Example',
      // theme: ThemeData(
      //   primarySwatch: ColorMap,
      // ),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      // NOTE: Optional - use themeMode to specify the startup theme
      themeMode: theme == '0' ? ThemeMode.dark : ThemeMode.light,
      home: MapPage(),
      // routes: <String, WidgetBuilder>{
      //   MapControllerPage.route: (context) => MapControllerPage(),
      //   MyHomePage.route: (context) => MyHomePage(),
      // },
    );
  }
}

// Generated using Material Design Palette/Theme Generator
// http://mcg.mbitson.com/
// https://github.com/mbitson/mcg
