import 'dart:math';
import 'dart:async';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:map_controller/map_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong/latlong.dart';

import '../../backend-helper/func.dart';
import './parking_popup.dart';

const MapA = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
const MapB =  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png?access_token={accessToken}';
const Token = 'pk.eyJ1IjoianVzdC1tYXgiLCJhIjoiY2ttMWo5Mm13NGRzejJubjFvazl5eWNqOSJ9.aSEaOcgSJ3aqaFgVAPKoHA';

enum markers_enum {
  none,
  park,
  track,
  heading,
}

class MapPage extends StatefulWidget {
  static const String route = '/map';
  final anchorsPosition = AnchorPos.align(AnchorAlign.center);
  MapPage({Key key}) : super(key: key);
  @override
  State<MapPage> createState() => _MapScreen();
}

class _MapScreen extends State<MapPage> {
  final PopupController _popupLayerController = PopupController();
  List<LatLng> _points = [];
  List<Marker> markers = <Marker>[];
  List<Marker> parkingMarkers = [];
  List<markers_enum> currentMarkers = [markers_enum.park, markers_enum.track, markers_enum.heading];
  ValueNotifier<int> selected = ValueNotifier(0);
  String urlMapTiles = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  DateTime fromDate = DateTime.now().subtract(Duration(hours: 4)).toLocal();
  DateTime toDate = DateTime.now().toLocal();
  List<Widget> carListWidgets = [];
  List cars = [];
  List<dynamic> dots = [];

  PanelController panelController;
  MapController mapController;
  StatefulMapController statefulMapController;
  StreamSubscription<StatefulMapControllerStateChange> sub;

  var isSwitched = false;

  void initState() {
    SharedPreferences prefs;
    f() async {
      prefs = await SharedPreferences.getInstance();
    }
    f().then((_) {
      setState(() {
        isSwitched = prefs.getString('theme') == '0' ? false : true;
        // currentMarkers = prefs.getString('drawable_markers').split(',');
        if (!prefs.getBool('drawable_markers_park',)){
          currentMarkers.remove(markers_enum.park);
        }
        if (!prefs.getBool('drawable_markers_track',)){
          currentMarkers.remove(markers_enum.track);
        }
        if (!prefs.getBool('drawable_markers_heading',)){
          currentMarkers.remove(markers_enum.heading);
        }
      });
    });
    // intialize the controllers
    panelController = new PanelController();
    mapController = MapController();
    statefulMapController = StatefulMapController(mapController: mapController);

    sub = statefulMapController.changeFeed.listen((change) {
      setState(() {});
    });
    Func.fetchCars().then((value) {
      createCarListWidgets(value);
      cars = value;
    });
    super.initState();
  }

  Future<Null> _selectDate(BuildContext context, String dateVar) async {
    final DateTime picked = await DatePicker.showDateTimePicker(context,
        showTitleActions: true,
        locale: LocaleType.ru,
        theme: DatePickerTheme(
            headerColor: Get.theme.appBarTheme.color,
            backgroundColor: Get.theme.backgroundColor,
            itemStyle: Get.textTheme.headline5,
            doneStyle: Get.textTheme.headline5,
            cancelStyle: Get.textTheme.headline5),
        currentTime: dateVar == 'from' ? fromDate : toDate,
        minTime: dateVar == 'from' ? DateTime(2020, 8).toLocal() : fromDate,
        maxTime: dateVar == 'from' ? toDate : DateTime.now().toLocal());
    if (picked != null && picked != (dateVar == 'from' ? fromDate : toDate) &&
        (dateVar == 'from' ? picked.millisecondsSinceEpoch <=
            toDate.millisecondsSinceEpoch : picked.millisecondsSinceEpoch >=
            fromDate.millisecondsSinceEpoch))
      if (dateVar == 'from') {
        setState(() {
          fromDate = picked;
        });
      } else {
        setState(() {
          toDate = picked;
        });
      }
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Get.theme.primaryColor;
    }
    return Get.theme.primaryColor;
  }

  toggleSwitch(bool v) async {
    String value = v ? '1' : '0';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value);
    if (value == '0') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.light);
    }
    setState(() {
      isSwitched = v;
    });
  }

  createCarListWidgets(cars) {
    List<Widget> temp = <Widget>[];
    for (var i = 0; i < cars.length - 1; i++) {
      var car = cars[i];
      temp.add(
          ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (context, value, _) {
                context.theme;
                return ListTile(
                  key: Key(car['id'].toString()),
                  selected: value == car['id'],
                  selectedTileColor: Get.theme.primaryColor,
                  title: Row(children: [
                    Text(
                      car['nomer'],
                      style: value == car['id'] ?
                      Get.theme.textTheme.headline5.copyWith(
                          color: Colors.white
                      ) :
                      Get.theme.textTheme.headline5.copyWith(
                          color: Get.theme.primaryColor
                      ),
                    ),
                  ]),
                  onTap: () {
                    setState(() {
                      selected.value = car['id'];
                    });
                    setPoints(carName: car['id']);
                  },
                );
              }
          ),
      );
    }
    setState(() {
      carListWidgets = temp;
    });
  }

  void setPoints({ int carName, markers_enum a: markers_enum.none}) async {
    if (a != markers_enum.none) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (currentMarkers.contains(a)) {
        currentMarkers.remove(a);
        setState(() {
          currentMarkers = currentMarkers;
        });
      } else {
        currentMarkers.add(a);
        setState(() {
          currentMarkers = currentMarkers;
        });
      }
      await prefs.setBool('drawable_markers_park', currentMarkers.contains(markers_enum.park));
      await prefs.setBool('drawable_markers_track', currentMarkers.contains(markers_enum.track));
      await prefs.setBool('drawable_markers_heading', currentMarkers.contains(markers_enum.heading));
    }
    parkingMarkers = [];
    _points = [];
    markers = [];
    if (carName != 0 && !currentMarkers.isBlank) {
      var _element;
      var _lat;
      var _lon;
      if (currentMarkers.contains(markers_enum.park)) {
        Func.fetchParking(
            cars: cars, car: carName, dateFrom: fromDate, dateTo: toDate).then((
            value) {
          List<Marker> temp = [];
          value.forEach((element) {
            double lat = element['Lat'];
            double lon = element['Lon'];

            temp.add(
                ParkingMarker(
                    monument: Parking(
                      dt: element['dt'],
                      park: element['park'],
                      lat: lat,
                      long: lon,
                    )
                )
            );
          });
          setState(() {
            parkingMarkers = temp;
          });
        });
      }
      if (currentMarkers.contains(markers_enum.track) ||
          currentMarkers.contains(markers_enum.heading)) {
        Func.fetchPath(
            cars: cars, car: carName, dateFrom: fromDate, dateTo: toDate)
            .then((List value) {
          List<LatLng> temp = [];
          List<Marker> temp2 = [];
          var prevElementAngle = 0;
          value.forEach((element) {
            _element = element;
            var lat = element['Lat'];
            var lon = element['Lon'];
            if (currentMarkers.contains(markers_enum.track)) {
              temp.add(LatLng(lat, lon));
            }
            if ((element['angle'] - prevElementAngle).abs() > 30 &&
                currentMarkers.contains(markers_enum.heading)) {
              temp2.add(Marker(
                width: 20.0,
                height: 20.0,
                point: LatLng(lat, lon),
                builder: (ctx) =>
                    Container(
                      child: Transform.rotate(
                        angle: element['angle'] * pi / 180,
                        child: Image(
                          image: AssetImage('assets/arrow.png'),
                          // color: Colors.green,
                          width: 10,
                          height: 10,
                        ),
                      ),
                    ),
                anchorPos: widget.anchorsPosition,
              ));
              prevElementAngle = element['angle'];
            }
          });
          setState(() {
            markers = temp2;
            _points = temp;
          });
          return value;
        }).then((v) {
          if (v.length > 0) {
            _lat = _element['Lat'];
            _lon = _element['Lon'];
            markers.add(Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(_lat, _lon),
              builder: (ctx) {
                context.theme;
                return Container(
                  child: Transform.rotate(
                    angle: 0.0 * pi / 180,
                    child: Image(
                      image: AssetImage('assets/car.png'),
                      width: 40,
                      height: 40,),
                  ),
                );
              },
              anchorPos: AnchorPos.align(AnchorAlign.top),
            ));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.theme;
    return Scaffold(
      appBar: AppBar(title: Text('Карта'), actions: <Widget>[
        Switch(
          onChanged: (v) => toggleSwitch(v),
          value: isSwitched,
          activeColor: Get.theme.buttonTheme.colorScheme.primaryVariant,
          activeTrackColor: Get.theme.backgroundColor,
          inactiveThumbColor: Get.theme.buttonTheme.colorScheme.primaryVariant,
          inactiveTrackColor: Get.theme.backgroundColor,
        ),
      ]
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: const Center(
                child: const Text('Выбор отображаемых меток'),
              ),
            ),
            ListTile(
              title: const Text('Парковки за период'),
              selected: currentMarkers.indexOf(markers_enum.park) > -1,
              onTap: () {
                setPoints(carName: selected.value, a: markers_enum.park);
              },
            ),
            ListTile(
              title: const Text('Маршрут за период'),
              selected: currentMarkers.indexOf(markers_enum.track) > -1,
              onTap: () {
                setPoints(carName: selected.value, a: markers_enum.track);
              },
            ),
            ListTile(
              title: const Text('Показывать направление движения'),
              selected: currentMarkers.indexOf(markers_enum.heading) > -1,
              onTap: () {
                setPoints(carName: selected.value, a: markers_enum.heading);
              },
            ),
          ],
        ),
      ),
      // drawer: buildDrawer(context, route),
      body: SlidingUpPanel(
        controller: panelController,
        backdropTapClosesPanel: true,
        backdropEnabled: true,
        header: Container(
          color: Get.theme.backgroundColor,
          width: MediaQuery
              .of(context)
              .size
              .width,
          height: 100.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  if (panelController.isPanelOpen) {
                    panelController.close();
                  } else {
                    panelController.open();
                  }
                },
                child: Func.getCarNom(cars, selected.value),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                      getColor,)),
                onPressed: () =>
                    _selectDate(context, 'from').then((value) {
                      if (selected.value != 0) setPoints(
                          carName: selected.value);
                    }),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('От'),
                      Text(fromDate.toLocal().toString().split(' ')[0],),
                      Text(Func.formatTime(fromDate),),
                    ]
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                      getColor,)),
                onPressed: () =>
                    _selectDate(context, 'to').then((value) {
                      if (selected.value != 0) setPoints(
                          carName: selected.value);
                    }),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('До'),
                      Text(toDate.toLocal().toString().split(' ')[0],),
                      Text(Func.formatTime(toDate),),
                    ]
                ),
              ),
            ],
          ),
        ),
        panel:
        Padding(
            padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
            child:  carListWidgets.isEmpty ?
            Container(
                child:
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.black, size: 80,),
                      Text('Проверьте интернет соединение',
                        style: Get.textTheme.headline4.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      ElevatedButton(onPressed: () =>
                          Func.fetchCars().then((value) {
                            createCarListWidgets(value);
                            cars = value;
                          }),
                          child: Text(
                              'Повторить попытку',
                              style: Get.textTheme.bodyText1.copyWith(fontSize: 20, color: Colors.white))),
                    ]),
                )
            ) : ListView(
                  children: carListWidgets,
            ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Flexible(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      center: LatLng(43.26, 76.94),
                      zoom: 12.0,
                      maxZoom: 18,
                      minZoom: 10,
                      rotation: 0,
                      plugins: [PopupMarkerPlugin()],
                      onTap: (_) =>
                          _popupLayerController
                              .hidePopup(),
                    ),
                    layers: [
                      TileLayerOptions(
                        urlTemplate: urlMapTiles,
                        subdomains: ['a', 'b', 'c'],
                        additionalOptions: {
                          'accessToken': Token,
                          'id': 'mapbox.streets',
                        },
                      ),
                      PolylineLayerOptions(
                        polylines: [
                          Polyline(
                              points: _points,
                              strokeWidth: 10,
                              color: Colors.white
                          ),
                          Polyline(
                            points: _points,
                            strokeWidth: 4.0,
                            color: Color.fromRGBO(59, 255, 00, 1),
                          ),
                        ],
                      ),
                      MarkerLayerOptions(markers: markers, key: Key('1')),
                      PopupMarkerLayerOptions(
                        markers: parkingMarkers,
                        popupSnap: PopupSnap.markerTop,
                        popupController: _popupLayerController,
                        popupBuilder: (_, Marker marker) {
                          if (marker is ParkingMarker) {
                            return ParkingMarkerPopup(
                                monument: marker.monument);
                          }
                          return Card(child: const Text('Not a monument'));
                        },
                      ),
                      // MarkerLayerOptions(markers: parkingMarkers, key: Key('2')),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 5,
              top: 5,
              child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: Icon(Icons.layers),
                          color: Colors.black,
                          onPressed: () {
                            if (urlMapTiles !=
                                MapA)
                              setState(() {
                                urlMapTiles =
                                    MapA;
                              });
                            else
                              setState(() {
                                urlMapTiles =
                                    MapB;
                              }
                              );
                          }
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 150, 0, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: Icon(Icons.add),
                          color: Colors.black,
                          onPressed: () {
                            statefulMapController.zoomIn();
                          }
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: Icon(Icons.remove),
                          color: Colors.black,
                          onPressed: () {
                            statefulMapController.zoomOut();
                          }
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: Icon(Icons.compass_calibration_rounded),
                          color: Colors.black,
                          onPressed: () {
                            mapController.rotate(0);
                          }
                      ),
                    ),
                  ]
              ),
            ),
          ], // children
        ),
      ),
    );
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}
