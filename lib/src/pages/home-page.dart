import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes.dart';
import 'package:flutter/material.dart';
import 'package:tracking_flutter/src/Widgets/drawer.dart';
const Token = 'pk.eyJ1IjoianVzdC1tYXgiLCJhIjoiY2ttMWo5Mm13NGRzejJubjFvazl5eWNqOSJ9.aSEaOcgSJ3aqaFgVAPKoHA';

class MyHomePage extends StatefulWidget {
  static const String route = '/home_page';
  MyHomePage({Key key, this.title = 'Home'}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _theme = '0';
  static const String route = '/home_page';
  void _setTheme(String v) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', v);
    String theme = (prefs.getString('theme') ?? 0);
    print('Current theme is $theme');
    Get.changeThemeMode(ThemeMode.dark);
    setState(() {
      _theme = v;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: buildDrawer(context, route),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: [
                Text(
                  'You have the button this many times:',
                ),
                Text(
                  '$_theme',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
            Material(
                child: Center(
                  child: new DropdownButton<String>(
                    value: _theme,
                    items: themes.map((ThemesListItem item) {
                      return new DropdownMenuItem<String>(
                        value: item.id(),
                        child: new ColoredBox(
                          color: item.colors().shade500,
                          child: Text(
                            item.name(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String v) {
                      _setTheme(v);
                    },
                  ),
                ),
            )
          ],
        ),
    );
  }
}
