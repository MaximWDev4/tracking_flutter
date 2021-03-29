import 'package:flutter/material.dart';

import '../pages/map.dart';



Drawer buildDrawer(BuildContext context, List currentMarkers, void callback(a)) {
  return Drawer(
    child: ListView(
      children: <Widget>[
        const DrawerHeader(
          child: const Center(
            child: const Text('Flutter Map Examples'),
          ),
        ),
        ListTile(
          title: const Text('Парковки за период'),
          selected: currentMarkers.indexOf(markers_enum.park) > -1,
          onTap: () async {
            callback(markers_enum.park);
          },
        ),
        ListTile(
          title: const Text('Маршрут за период'),
          selected:  currentMarkers.indexOf(markers_enum.track) > 1,
          onTap: () {
            callback(markers_enum.track);
          },
        ),
      ],
    ),
  );
}
