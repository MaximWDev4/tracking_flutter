import 'dart:convert';
import 'dart:io';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

import '../../main.dart';
import '../widgets/drawer.dart';

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


const Token = 'pk.eyJ1IjoianVzdC1tYXgiLCJhIjoiY2ttMWo5Mm13NGRzejJubjFvazl5eWNqOSJ9.aSEaOcgSJ3aqaFgVAPKoHA';

class MapPage extends StatefulWidget {
  static const String route = '/';
  final base = '192.168.0.50:8080';
  final headers = {
    HttpHeaders
        .contentTypeHeader: 'application/x-www-form-urlencoded; charset=UTF-8'
  };
  final anchorsPosition = AnchorPos.align(AnchorAlign.center);
  MapPage({Key key}) : super(key: key);
  @override
  State<MapPage> createState() => _HomeScreen();
}

class _HomeScreen extends State<MapPage> {
  static const String route = '/';
  List<LatLng> _points = [];
  List<Marker> markers = <Marker>[];
  int selected = 0;
  String urlMapTiles = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  DateTime fromDate = DateTime.now().subtract(Duration(hours: 4, minutes: 10));
  DateTime toDate = DateTime.now();
  List<Widget> carListWidgets = [];
  List cars = [];
  List<dynamic> dots = [];
  var overlayImages = <OverlayImage>[];
  Future<Null> _selectDate(BuildContext context, String dateVar) async {
    final DateTime picked = await DatePicker.showDateTimePicker( context,
        showTitleActions: true,
        locale: LocaleType.ru,
        theme: DatePickerTheme(
            headerColor: ColorMap.appBarTheme.color,
            backgroundColor: ColorMap.appBarTheme.backgroundColor,
            itemStyle: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            doneStyle: TextStyle(color: Colors.white, fontSize: 16),
            cancelStyle: TextStyle(color: Colors.grey, fontSize: 16)),
        currentTime: dateVar == 'from' ? fromDate : toDate,
        minTime: dateVar == 'from' ? DateTime(2020, 8) : fromDate,
        maxTime: dateVar == 'from' ? toDate : DateTime.now());
    if (picked != null && picked != (dateVar == 'from' ? fromDate : toDate) && (dateVar == 'from' ? picked.millisecondsSinceEpoch <= toDate.millisecondsSinceEpoch : picked.millisecondsSinceEpoch >= fromDate.millisecondsSinceEpoch))
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

  formatTime (DateTime time) {
    return "${('0'+time.hour.toString()).substring(('0'+time.hour.toString()).length-2)}:${('0'+time.minute.toString()).substring(('0'+time.minute.toString()).length-2)}";
  }

  Widget getCarNom() {
    var carIdName = '';
    var name = '';
    var id = '';
    if (cars.isNotEmpty&&selected != 0 ) {
      carIdName = (cars[cars.indexWhere((element) =>
      element['id'] == selected)]['nomer']);
      name = carIdName.substring(carIdName.indexOf(' '));
      id = carIdName.substring(0, carIdName.indexOf(' '));
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(id, style: ColorMap.textTheme.headline6),
            Text(name, style: ColorMap.textTheme.headline6)
          ],
        ),
      );
    } else {
      carIdName = 'Выбрать технику';
      return Text(
          carIdName, style: ColorMap.textTheme.headline6);
    }

  }

  Future fetchCars() async {
    final Uri uri = Uri.http(
        widget.base, '/mishka.pro/bike-gps/', { 'cars': ''});
    return http.post(uri, body: 'Token=123', headers: widget.headers).then((response) {
      cars = jsonDecode(response.body)['groups']['cars'];
      return cars;
    }).catchError((err) {print(err); return [];});
  }

  Future fetchPath(car, DateTime dateFrom, DateTime dateTo) async {
    if (cars.isNotEmpty) {
      int from = (dateFrom.millisecondsSinceEpoch / 1000).floor();
      int to = (dateTo.millisecondsSinceEpoch / 1000).floor();
      final Uri uri = Uri.http(
          widget.base, 'mishka.pro/bike-gps/', { 'track': ''});
      var body = 'Token=123&OT=' + from.toString() + '&DO=' + to.toString() +
          '&ID=' + car.toString();
      print(body);
      return await http.post(uri, body: body, headers: widget.headers).then((
          response) {
        print(response.body);
        dots = jsonDecode(response.body)['data'];
        return dots;
      }).catchError((error) {
        print(error);
        return [];
      });
    } else {

    }
  }

  void fetchParking(value) {
    if (cars.isNotEmpty) {
      final Uri uri = Uri.http(
          widget.base, 'mishka.pro/bike-gps/', { 'parking': ''});
      var body = 'Token=123&OT=1615424400&DO=1615425000&ID=' + value.toString();
      http.post(uri, body: body, headers: widget.headers).then((response) {
        print(jsonDecode(response.body)['data']);
      }).catchError((error) => print(error));
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
            selectedTileColor: ColorMap.primaryColor,
            title: Row(children: [
              Text(car['nomer'], style: TextStyle(
                  color: selected == car['id']
                      ? ColorMap.backgroundColor
                      : ColorMap.primaryColor),),
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
    overlayImages = <OverlayImage>[
      OverlayImage(
          bounds: LatLngBounds(LatLng(43.278717, 76.894859), LatLng(43.2789, 76.895)),
          opacity: 1,
          imageProvider: AssetImage('assets/car.png')
      ),
    ];
    fetchPath(carName, fromDate, toDate).then((value) =>
    {
      value.forEach((element) {
        // overlayImages = <OverlayImage>[
        //   OverlayImage(
        //       bounds: LatLngBounds(LatLng(43.278538, 76.895561), LatLng(43.57, 77.0)),
        //       opacity: 1,
        //       imageProvider: AssetImage('assets/car.png')
        //   ),
        // ];
        var lat = element['Lat'];
        var lon = element['Lon'];
        _points.add(LatLng(lat, lon));
        if (element['id'] % 10 == 0) {
          markers.add(Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(lat, lon),
            builder: (ctx) =>
                Container(
                  child: Transform.rotate(
                    angle: 0.0 + element['angle'],
                    child: Icon(
                      Icons.arrow_drop_up_outlined, color: ColorMap.primaryColor,
                      size: 40,),
                  ),
                ),
            anchorPos: widget.anchorsPosition,
          ));
        }
      })
      // .sublist(tempArr.length>50 ? 50 : 0, tempArr.length>100 ? 100 : 0);
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    fetchCars().then((value) => createCarListWidgets(value));

    return Scaffold(
      appBar: AppBar(title: Text('Карта')),
      drawer: buildDrawer(context, route),
      body: SlidingUpPanel(
        backdropEnabled: true,
        header: Container(
          color: ColorMap.accentColor,
          width: MediaQuery.of(context).size.width,
          height: 100.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  fetchCars().then((value) => createCarListWidgets(value));
                },
                child: getCarNom(),
              ),
              ElevatedButton(
                onPressed: () => _selectDate(context, 'from').then((value) { if (selected != 0) setPoints(selected, dots);}),
                child:Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("${fromDate.toLocal()}".split(' ')[0], style: ColorMap.textTheme.button,),
                    Text(formatTime(fromDate), style: ColorMap.textTheme.button,),
                  ]
                ),
              ),
              ElevatedButton(
                onPressed: () => _selectDate(context, 'to').then((value)  { if (selected != 0) setPoints(selected, dots);}),
                child:Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("${toDate.toLocal()}".split(' ')[0], style: ColorMap.textTheme.button,),
                      Text(formatTime(toDate), style: ColorMap.textTheme.button,),
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
                          color: ColorMap.backgroundColor,
                        ),
                      ],
                    ),
                    MarkerLayerOptions(markers: markers),
                    OverlayImageLayerOptions(overlayImages: overlayImages),
                  ],
                ),
              ),
            ],
          ),
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
                    if (urlMapTiles != 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}')
                      setState(() {
                        urlMapTiles = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
                      });
                    else
                      setState(() {
                        urlMapTiles = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png?access_token={accessToken}';
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
