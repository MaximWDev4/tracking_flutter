import 'package:flutter/material.dart';

import '../pages/home-page.dart';
import '../pages/map.dart';
import '../pages/map_controller.dart';

Drawer buildDrawer(BuildContext context, String currentRoute) {
  return Drawer(
    child: ListView(
      children: <Widget>[
        const DrawerHeader(
          child: const Center(
            child: const Text('Flutter Map Examples'),
          ),
        ),
        ListTile(
          title: const Text('Карта'),
          selected: currentRoute == MapPage.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, MapPage.route);
          },
        ),
        ListTile(
          title: const Text('MapController'),
          selected: currentRoute == MapControllerPage.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, MapControllerPage.route);
          },
        ),
        ListTile(
          title: const Text('Home Page'),
          selected: currentRoute == MyHomePage.route,
          onTap: () {
            Navigator.pushReplacementNamed(
                context, MyHomePage.route);
          },
        ),
      ],
    ),
  );
}
