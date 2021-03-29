import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:tracking_flutter/src/Widgets/drawer.dart';
const Token = 'pk.eyJ1IjoianVzdC1tYXgiLCJhIjoiY2ttMWo5Mm13NGRzejJubjFvazl5eWNqOSJ9.aSEaOcgSJ3aqaFgVAPKoHA';

class MyHomePage extends StatefulWidget {
  static const String route = '/home_page';
  MyHomePage({Key key, this.title = 'Home'}) : super(key: key);

  static toggleSwitch(bool v) async {
    String value = v ? '1' : '0';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value);
    if (value == '0') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.light);
    }
    return v;
  }

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String route = '/home_page';
  bool isSwitched = false;
  void initState()  {
    SharedPreferences prefs;
    f() async {
      prefs = await SharedPreferences.getInstance();
    }
    f().then((_) {
      setState(() {
        isSwitched = prefs.getString('theme') == '0' ? false : true;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      // drawer: buildDrawer(context, route),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child:
            Text(
              'Тема',
              style: Get.textTheme.headline4,
            ),
          ),
          Center(
            child:
            Switch(
              onChanged: (v) {
                setState(() {
                  isSwitched = MyHomePage.toggleSwitch(v);
                });
              },
              value: isSwitched,
              activeColor: Get.theme.primaryColor,
              activeTrackColor: Get.theme.backgroundColor,
              inactiveThumbColor: Get.theme.primaryColor,
              inactiveTrackColor: Get.theme.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
