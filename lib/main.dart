import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/pages/map.dart';
import 'package:get/get.dart';
import 'src/pages/login_screen.dart';
import 'src/transition_route_observer.dart';
void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  String theme = '1';
  SharedPreferences prefs;

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
      home: MapPage(),
      navigatorObservers: [TransitionRouteObserver()],
      initialRoute: MapPage.route,
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
