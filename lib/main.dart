import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/pages/map.dart';
import 'package:get/get.dart';
import 'src/pages/login_screen.dart';
import 'src/transition_route_observer.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  String theme = '1';
  getUserTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    theme = prefs.getString('theme');
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
      home: LoginScreen(),
      navigatorObservers: [TransitionRouteObserver()],
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(),
        MapPage.route: (context) => MapPage(),
      },
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
