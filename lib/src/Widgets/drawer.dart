import 'package:flutter/material.dart';
import 'package:tracking_flutter/src/pages/home-page.dart';

import '../pages/animated_map_controller.dart';
import '../pages/map.dart';
import '../pages/esri.dart';
import '../pages/map_controller.dart';
import '../pages/offline_map.dart';
import '../pages/overlay_image.dart';

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
          title: const Text('Esri'),
          selected: currentRoute == EsriPage.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, EsriPage.route);
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
          title: const Text('Animated MapController'),
          selected: currentRoute == AnimatedMapControllerPage.route,
          onTap: () {
            Navigator.pushReplacementNamed(
                context, AnimatedMapControllerPage.route);
          },
        ),
        ListTile(
          title: const Text('Offline Map'),
          selected: currentRoute == OfflineMapPage.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, OfflineMapPage.route);
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
        ListTile(
          title: const Text('Overlay Image'),
          selected: currentRoute == OverlayImagePage.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, OverlayImagePage.route);
          },
        ),
      ],
    ),
  );
}
