import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:map_controller/map_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong/latlong.dart';

import '../../backend-helper/func.dart';

class PointsNotifier extends ValueNotifier<List<LatLng>> {
  PointsNotifier(List<LatLng> value) : super(value);

    void changePoints(List<LatLng> list){
      value = list;
      notifyListeners();
    }
}

class StringNotifier extends ValueNotifier<String> {
  StringNotifier(String value) : super(value);

  void changePoints(String val){
    value = val;
    notifyListeners();
  }
}

const MapA = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
const MapB =  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png?access_token={accessToken}';
const Token = 'pk.eyJ1IjoianVzdC1tYXgiLCJhIjoiY2ttMWo5Mm13NGRzejJubjFvazl5eWNqOSJ9.aSEaOcgSJ3aqaFgVAPKoHA';

class MapPage extends StatefulWidget {
  static const String route = '/';
  final anchorsPosition = AnchorPos.align(AnchorAlign.center);
  MapPage({Key key}) : super(key: key);
  @override
  State<MapPage> createState() => _HomeScreen();
}

class _HomeScreen extends State<MapPage> {
  static const String route = '/';
  List<LatLng> _points = [];
  List<Marker> parkingMarks = [];
  List<Marker> markers = <Marker>[];
  int selected = 0;
  String urlMapTiles = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  DateTime fromDate = DateTime.now().subtract(Duration(hours: 4, minutes: 10));
  DateTime toDate = DateTime.now();
  List<Widget> carListWidgets = [];
  List cars = [];
  List<dynamic> dots = [];


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
      });
    });
    // intialize the controllers
    mapController = MapController();
    statefulMapController = StatefulMapController(mapController: mapController);

    // wait for the controller to be ready before using it
    statefulMapController.onReady.then((_) =>
        print("The map controller is ready"));

    // statefulMapController.changeFeed.transform(streamTransformer);
    /// [Important] listen to the changefeed to rebuild the map on changes:
    /// this will rebuild the map when for example addMarker or any method
    /// that mutates the map assets is called
    statefulMapController.changeFeed.listen((event) {
      print(statefulMapController.zoom.toString());
    });
    sub = statefulMapController.changeFeed.listen((change) {
      setState(() {});
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
        minTime: dateVar == 'from' ? DateTime(2020, 8) : fromDate,
        maxTime: dateVar == 'from' ? toDate : DateTime.now());
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


  formatTime(DateTime time) {
    return "${('0' + time.hour.toString()).substring(
        ('0' + time.hour.toString()).length - 2)}:${('0' +
        time.minute.toString()).substring(
        ('0' + time.minute.toString()).length - 2)}";
  }


  Widget getCarNom() {
    var carIdName = '';
    var name = '';
    var id = '';
    if (cars.isNotEmpty && selected != 0) {
      carIdName = (cars[cars.indexWhere((element) =>
      element['id'] == selected)]['nomer']);
      name = carIdName.substring(carIdName.indexOf(' '));
      id = carIdName.substring(0, carIdName.indexOf(' '));
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(id, style: Get.theme.textTheme.headline6),
            Text(name, style: Get.theme.textTheme.headline6)
          ],
        ),
      );
    } else {
      carIdName = 'Выбрать технику';
      return Text(
          carIdName, style: Get.theme.textTheme.headline6);
    }
  }


  createCarListWidgets(cars) {
    List<Widget> temp = <Widget>[];
    for (var i = 0; i < cars.length - 1; i++) {
      var car = cars[i];
      temp.add(
          ListTile(
            key: Key(car['id'].toString()),
            selected: selected == car['id'],
            selectedTileColor: Get.theme.primaryColor,
            title: Row(children: [
              Text(
                car['nomer'],
                style: selected == car['id'] ?
                Get.theme.textTheme.headline5.copyWith(
                    color: Colors.white
                ) :
                Get.theme.textTheme.headline5.copyWith(
                    color: Get.theme.primaryColor
                ),
              ),
              // Text((selected == e['nomer']).toString()),
            ]),
            onTap: () {
              setState(() {
                selected = car['id'];
              });
              setPoints(car['id'], dots);
            },
          )
      );
    }
    setState(() {
      carListWidgets = temp;
    });
  }


  void setPoints(int carName, List dots) async {
    _points = [];
    markers = [];
    var _element;
    var _lat;
    var _lon;
    Func.fetchParking(cars: cars, car: carName, dateFrom: fromDate, dateTo: toDate).then((value) {
      value.forEach((element) {
        double lat = element['Lat'];
        double lon = element['Lon'];
        print(value);
        markers.add(Marker(
          width: 20.0,
          height: 20.0,
          point: LatLng(lat, lon),
          builder: (ctx) =>
              Container(
                  child: Image(
                    image: AssetImage('assets/parked.png'),
                    // color: Colors.green,
                    width: 10,
                    height: 10,
                  ),
                ),
          anchorPos: widget.anchorsPosition,
        ));
      });
    });
    Func.fetchPath(cars: cars, car: carName, dateFrom: fromDate, dateTo: toDate).then((List value) {
      var prevElement = 0;
      value.forEach((element) {
        _element = element;
        var lat = element['Lat'];
        var lon = element['Lon'];
        _points.add(LatLng(lat, lon));
        if ((element['angle'] - prevElement).abs() > 30) {
          markers.add(Marker(
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
          prevElement = element['angle'];
        }
      });
      return value;
    }).then((v) {
      if (v.length > 0) {
        _lat = _element['Lat'];
        _lon = _element['Lon'];
        markers[markers.length - 1] = Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(_lat, _lon),
          builder: (ctx) =>
              Container(
                child: Transform.rotate(
                  angle: 0.0 * pi / 180,
                  child: Image(
                    image: AssetImage('assets/car.png'),
                    width: 40,
                    height: 40,),
                ),
              ),
          anchorPos: AnchorPos.align(AnchorAlign.top),
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    Func.fetchCars().then((value) => createCarListWidgets(value));


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
      // drawer: buildDrawer(context, route),
      body: SlidingUpPanel(
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
                  Func.fetchCars().then((value) => createCarListWidgets(value));
                },
                child: getCarNom(),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                      getColor,)),
                onPressed: () =>
                    _selectDate(context, 'from').then((value) {
                      if (selected != 0) setPoints(selected, dots);
                    }),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("${fromDate.toLocal()}".split(' ')[0],
                        style: Get.theme.textTheme.button,),
                      Text(formatTime(fromDate),
                        style: Get.theme.textTheme.button,),
                    ]
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith(
                      getColor,)),
                onPressed: () =>
                    _selectDate(context, 'to').then((value) {
                      if (selected != 0) setPoints(selected, dots);
                    }),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("${toDate.toLocal()}".split(' ')[0],
                        style: Get.theme.textTheme.button,),
                      Text(
                        formatTime(toDate), style: Get.theme.textTheme.button,),
                    ]
                ),
              ),
            ],
          ),
        ),
        panel:
        Padding(
            padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
            child:
            ListView(
                children: carListWidgets
            )
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
                      // plugins: [
                      //   ScaleLayerPlugin(),
                      // ],
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
                      MarkerLayerOptions(markers: [...markers, ...parkingMarks]),
                    ],
                  ),
                ),
              ],
            ),
            // Positioned(
            //     top: 15.0,
            //     right: 15.0,
            //     child: TileLayersBar(controller: statefulMapController)),
            Positioned(
              right: 5,
              top: 5,
              child: Container(
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
            ),
          ], // children
        ),
      ),
    );
  }
}
