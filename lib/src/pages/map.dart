import 'dart:math';
import 'dart:async';
import 'package:flutter/scheduler.dart';
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
import 'package:tracking_flutter/src/pages/login_screen.dart';
import 'dart:collection';

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

const MyColors = [
  Color.fromRGBO(59, 255, 00, 1),
  Color.fromRGBO(255, 0, 51, 1.0),
  Color.fromRGBO(0, 13, 255, 1.0),
  Color.fromRGBO(255, 221, 0, 1.0),
  Color.fromRGBO(98, 0, 255, 1.0),
  Color.fromRGBO(255, 30, 0, 1.0),
  Color.fromRGBO(0, 255, 234, 1.0),
  Color.fromRGBO(217, 0, 255, 1.0),
  Color.fromRGBO(5, 94, 24, 1.0),
  Color.fromRGBO(167, 44, 6, 1.0),
  Color.fromRGBO(94, 5, 26, 1.0),
];

class MapPage extends StatefulWidget {
  static const String route = '/map';
  final anchorsPosition = AnchorPos.align(AnchorAlign.center);
  MapPage({Key key}) : super(key: key);
  @override
  State<MapPage> createState() => _MapScreen();
}

class _MapScreen extends State<MapPage> with TickerProviderStateMixin {
  final PopupController _popupLayerController = PopupController();
  final List<Tab> myTabs = <Tab>[
    Tab(text: 'Техника'),
    Tab(text: 'Маршрут'),
  ];
  TabController _tabController;
  DoubleLinkedQueue<dynamic> _points = new DoubleLinkedQueue();
  List<Polyline> polylines = [];
  List<Marker> currentCarPos = [];
  List<Marker> markers = <Marker>[];
  List<dynamic> parkings = [];
  List<Marker> parkingMarkers = [];
  List<List<LatLng>> _currentSections = [];
  List<dynamic> displayedSections = [];
  List<markers_enum> currentDisplayedMarkers = [
    markers_enum.park,
    markers_enum.track,
    markers_enum.heading
  ];
  ValueNotifier<int> selected = ValueNotifier(0);
  ValueNotifier<int> selectedSegment = ValueNotifier(0);
  String urlMapTiles = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  DateTime now = DateTime.now();
  DateTime fromDate = DateTime.now().toLocal();
  DateTime toDate = DateTime.now().toLocal();
  List<Widget> carListWidgets = [];
  List cars = [];

  List<dynamic> dots = [];
  SharedPreferences prefs;
  PanelController panelController;
  MapController mapController;

  StatefulMapController statefulMapController;

  StreamSubscription<StatefulMapControllerStateChange> sub;

  var isSwitched = false;

  f() async {
    prefs = await SharedPreferences.getInstance();
  }

  void initState() {
    fromDate = DateTime(now.year, now.month, now.day).toLocal();
    toDate = DateTime.now().toLocal();
    _tabController = TabController(length: myTabs.length, initialIndex: 0, vsync: this);
    // context.showLoaderOverlay();
    f().then((_) {
      var token = prefs.getString('Token');
      if (token == '' || token == null) {
        // context.hideLoaderOverlay();
        _logOut();
      } else {
        var dmp = prefs.getBool('drawable_markers_park',);
        var dmt = prefs.getBool('drawable_markers_track',);
        var dmh = prefs.getBool('drawable_markers_heading',);
        isSwitched = prefs.getString('theme') == '0' ? false : true;
        // currentMarkers = prefs.getString('drawable_markers').split(',');
        if (!(dmp ?? true)) {
          setState(() {
            currentDisplayedMarkers.remove(markers_enum.park);
          });
        } else if (dmp == null) {
          prefs.setBool('drawable_markers_park', true);
        }
        if (!(dmt ?? true)) {
          setState(() {
            currentDisplayedMarkers.remove(markers_enum.track);
          });
        } else if (dmt == null) {
          prefs.setBool('drawable_markers_park', true);
        }
        if (!(dmh ?? true)) {
          setState(() {
            currentDisplayedMarkers.remove(markers_enum.heading);
          });
        } else if (dmh == null) {
          prefs.setBool('drawable_markers_park', true);
        }
        // context.hideLoaderOverlay();
        Func.fetchCars().then((value) {
          setState(() {
            createCarListWidgets(value);
            cars = value;
          });
        });
      }
    });
    panelController = new PanelController();
    mapController = MapController();
    statefulMapController =
        StatefulMapController(mapController: mapController);

    sub = statefulMapController.changeFeed.listen((change) {
      setState(() {});
    });
    // intialize the controllers
    super.initState();
  }


  void _logOut() async {
    prefs.setString('Token', '');
    Navigator.of(context)
        .pushNamedAndRemoveUntil(
        LoginScreen.routeName, (Route<dynamic> route) => false);
    print('logOut');
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
    for (var i = 0; i < cars.length; i++) {
      var car = cars[i];
      temp.add(
        ValueListenableBuilder<int>(
            valueListenable: selected,
            builder: (context, value, _) {
              context.theme;
              return SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                child: ListTile(
                  key: Key(car['id'].toString()),
                  selected: value == car['id'],
                  selectedTileColor: Get.theme.primaryColor,
                  title: Row(children: [
                    Text(
                      car['nomer'],
                      style: value == car['id'] ?
                      Get.theme.textTheme.headline6.copyWith(
                          color: Colors.white
                      ) :
                      Get.theme.textTheme.headline6.copyWith(
                          color: Get.theme.primaryColor
                      ),
                    ),
                  ]),
                  onTap: () {
                    selected.value = car['id'];
                    setPoints(carName: car['id']);
                  },
                ),
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
      if (currentDisplayedMarkers.contains(a)) {
        currentDisplayedMarkers.remove(a);
        setState(() {
          currentDisplayedMarkers = currentDisplayedMarkers;
        });
      } else {
        currentDisplayedMarkers.add(a);
        setState(() {
          currentDisplayedMarkers = currentDisplayedMarkers;
        });
      }
      await prefs.setBool(
          'drawable_markers_park',
          currentDisplayedMarkers.contains(markers_enum.park));
      await prefs.setBool('drawable_markers_track',
          currentDisplayedMarkers.contains(markers_enum.track));
      await prefs.setBool('drawable_markers_heading',
          currentDisplayedMarkers.contains(markers_enum.heading));
    }
    parkingMarkers = [];
    _points.clear();
    markers = [];
    if (carName != 0 && !currentDisplayedMarkers.isBlank) {
      var _lat;
      var _lon;
      Func.fetchParking(
          cars: cars, car: carName, dateFrom: fromDate, dateTo: toDate).then((
          value) {
        parkings = value;
        List<Marker> temp = [];
        if (value.isBlank) {
          Future.delayed(Duration(milliseconds: timeDilation.ceil() * 1000))
              .then((_) {
            Get.rawSnackbar(message: 'нет парковок за период',);
            print('нет парковок за период');
          });
        }
        if (currentDisplayedMarkers.contains(markers_enum.park)) {
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
        }
      }).then((value) =>
          Func.fetchPath(
          cars: cars, car: carName, dateFrom: fromDate, dateTo: toDate)
          .then((List value) {
        List<dynamic> temp = [];
        List<Marker> temp2 = [];
        if (value.isBlank) {
          Get.rawSnackbar(message: 'нет перемещений за период');
          print('нет перемещений за период');
        }
        var prevElementAngle = 0;
        if (currentDisplayedMarkers.contains(markers_enum.track) ||
            currentDisplayedMarkers.contains(markers_enum.heading)) {
          value.forEach((element) {
            var lat = element['Lat'];
            var lon = element['Lon'];
            if (currentDisplayedMarkers.contains(markers_enum.track) ||
                currentDisplayedMarkers.contains(markers_enum.heading)) {
              temp.add(element);
            }
            if ((element['angle'] - prevElementAngle).abs() > 30 &&
                currentDisplayedMarkers.contains(markers_enum.heading)) {
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
        }
        return [temp, temp2];
      })).then((dynamic temp) {
        var temp1 = temp[0];
        var temp2 = temp[1];
        setState(() {
          markers = temp2;
        });
        _points.addAll(temp1);
        createSections();
        drawSegOrTrack(0);
        _tabController.index = 1;
      });
    }
    markLastCarPos(carName);
  }

  Future<LatLng> markLastCarPos(carName) async {
    return (await Func.fetchLast(car: carName).then((List<dynamic> v) {
      var _lat;
      var _lon;
      if (v.isNotEmpty) {
        _lat = v[0]['Lat'];
        _lon = v[0]['Lon'];
        currentCarPos = [(Marker(
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
        ))
        ];
      }
      return LatLng(_lat, _lon);
    })
    );

  }

  createSections() {
    _currentSections = [];
    if (_points.isNotEmpty) {
      if (parkings.isBlank) {
        _currentSections.add([]);
        _points.forEach((element) {
          var lat = element['Lat'];
          var lon = element['Lon'];
          _currentSections[0].add(LatLng(lat, lon));
        });
      } else {
        for (var i = 0; i <= parkings.length; i++) {
          _currentSections.add([]);
          var elements = _points.where((e) {
            return (i < parkings.length ? e['dt'] <
                parkings.reversed.elementAt(i)['dt'] : true) &&
                (i > 0
                    ? e['dt'] > parkings.reversed.elementAt(i - 1)['dt']
                    : true);
          });
          elements.forEach((element) {
            var lat = element['Lat'];
            var lon = element['Lon'];
            _currentSections[i].add(LatLng(lat, lon));
          });
        }
      }
    }
  }

  selectSegment(int i) {
    if (selectedSegment.value != i) {
      selectedSegment.value = i;
      drawSegOrTrack(i);
      return;
    }
    selectedSegment.value = 0;
    drawSegOrTrack(0);
  }

  drawSegOrTrack(int sections ) {
    print(sections);
    if (_currentSections.isNotEmpty) {
      if (sections != 0){
          var i = sections;
            polylines = [
              Polyline(
                  points: _currentSections[i-1],
                  strokeWidth: 10,
                  color: Colors.white
              ),
              Polyline(
                points: _currentSections[i-1],
                strokeWidth: 4.0,
                color: MyColors[i % 11],
              )
            ];
          return;
        }
      for (var i = 0; i < _currentSections.length; i++) {
          polylines = [...polylines,
            Polyline(
                points: _currentSections[i],
                strokeWidth: 10,
                color: Colors.white
            ),
            Polyline(
              points: _currentSections[i],
              strokeWidth: 4.0,
              color: MyColors[i % 11],
            )
          ];
      }
      return;
    }
  }

  List<Widget> buildSegList() => [
  for (var i=1;  i <= _currentSections.length; i++)
    ListTile(
        key: Key(i.toString()),
        title:
        InkResponse(
          onTap: selectSegment(i),
          child:
            Container(
              color: Color.fromRGBO(MyColors[i%11].red, MyColors[i%11].green, MyColors[i%11].blue, .5),
              width: 100,
              height: 50,
              child: Center(child: Text(i.toString())),
            ),
        ),
    ),
  ];

  Widget tabWidgetCars(BuildContext context, ScrollController scrollController) => carListWidgets.isEmpty ?
  Container(
      child:
      Center(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded, color: Colors.black, size: 80,),
              Text('Проверьте интернет соединение',
                style: Get.textTheme.headline4.copyWith(
                    color: Colors.black, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                  onPressed: () =>
                      Func.fetchCars().then((value) {
                        // Func.logIn(pw: 'alex', un: 'alex').then((v) {
                        createCarListWidgets(value);
                        cars = value;
                        // });
                      }),
                  child: Text(
                      'Повторить попытку',
                      style: Get.textTheme.bodyText1.copyWith(
                          fontSize: 20, color: Colors.white))),
            ]),
      )
  ) :ListView(
      controller: scrollController,
      children: [ carSelect(), ...carListWidgets ],
  );

  Widget tabWidgetSeg(BuildContext context, ScrollController scrollController) => ListView(
    controller: scrollController,
      children: [
        _currentSections.isEmpty ?
        Padding(padding: EdgeInsets.only(top: 12, bottom: 5),
          child: Text('Выберите технику', style: Get.theme.textTheme.headline5,
          textAlign: TextAlign.center,)) :
        segSelect(), ...buildSegList(),
      ],
  );

  carSelect() {
    return Container(
      padding: EdgeInsets.fromLTRB(3, 2, 3, 0),
      decoration: BoxDecoration(
        color: Get.theme.backgroundColor,
        // borderRadius: BorderRadius.vertical(
        //   top: Radius.circular(20),
        // ),
      ),
      width: MediaQuery
          .of(context)
          .size
          .width,
      height: 70.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width / 3 - 2,
            child:
            TextButton(
              onPressed: () {
                if (panelController.isPanelOpen) {
                  panelController.close();
                } else {
                  panelController.open();
                  if (cars.isBlank || cars == null)
                    Func.fetchCars().then((value) {
                      setState(() {
                        createCarListWidgets(value);
                        cars = value;
                      });
                    });
                }
              },
              child: Func.getCarNom(cars, selected.value),
            ),
          ),
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width / 3 - 2,
            child:
            FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(25.0),
                side: BorderSide(width: 1, color: Colors.white),
              ),

              onPressed:  () =>
                  _selectDate(context, 'from').then((value) {
                    if (selected.value != 0) setPoints(
                        carName: selected.value);
                  }),
              // color: Get.theme.buttonColor,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Выбрать от', style: Get.textTheme.bodyText1.copyWith(fontSize: 12),),
                    Text(fromDate.toLocal().toString().split(' ')[0], style: Get.textTheme.bodyText1.copyWith(fontSize: 12),),
                    Text(Func.formatTime(fromDate), style: Get.textTheme.bodyText1,),
                  ]
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width / 3 - 2,
            child:
            FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(25.0),
                side: BorderSide(width: 1, color: Colors.white),
              ),
              // color: Get.theme.buttonColor,
              onPressed: () =>
                  _selectDate(context, 'to').then((value) {
                    if (selected.value != 0) setPoints(
                        carName: selected.value);
                  }),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Выбрать до', style: Get.textTheme.bodyText2.copyWith(fontSize: 12),),
                    Text(toDate.toLocal().toString().split(' ')[0], style: Get.textTheme.bodyText1.copyWith(fontSize: 12),),
                    Text(Func.formatTime(toDate), style: Get.textTheme.bodyText1,),
                  ]
              ),
            ),
          ),
        ],
      ),
    );
  }

  segSelect() {
    return Container(
      height: 70,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i=1;  i <= _currentSections.length; i++)
            InkResponse(
              onTap: selectSegment(i),
              child:
              Container(
                color: Color.fromRGBO(MyColors[i%11].red, MyColors[i%11].green, MyColors[i%11].blue, .5),
                width: 100,
                height: 50,
                child: Center(child: Text(i.toString())),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildDragIcon() => Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(8),
    ),
    width: 40,
    height: 7,
  );

  buildTabBar() =>
  PreferredSize(
      preferredSize: Size.fromHeight(60),
      child:
    AppBar(
      backgroundColor: Color.fromRGBO(5, 5, 170, 0),
      title:  buildDragIcon(),
      centerTitle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight:  Radius.circular(20), bottomLeft:  Radius.circular(0), bottomRight:  Radius.circular(0))),
      bottom: TabBar(
        controller: _tabController,
        tabs: myTabs,
      ),
    ),
  );

  Widget buildSlidingPanel(
      @required ScrollController scrollController
      ) =>
      DefaultTabController(
          length: 2,
          child:
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: buildTabBar(),
            body:
            TabBarView(
              controller: _tabController,
              children: [
                tabWidgetCars(context, scrollController),
                tabWidgetSeg(context, scrollController)
              ],
            ),
          )
      );

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
        IconButton(icon: Icon(Icons.exit_to_app_rounded),
            onPressed: () => _logOut()),
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
              selected: currentDisplayedMarkers.indexOf(markers_enum.park) > -1,
              onTap: () {
                setPoints(carName: selected.value, a: markers_enum.park);
              },
            ),
            ListTile(
              title: const Text('Маршрут за период'),
              selected: currentDisplayedMarkers.indexOf(markers_enum.track) > -1,
              onTap: () {
                setPoints(carName: selected.value, a: markers_enum.track);
              },
            ),
            ListTile(
              title: const Text('Показывать направление движения'),
              selected: currentDisplayedMarkers.indexOf(markers_enum.heading) > -1,
              onTap: () {
                setPoints(carName: selected.value, a: markers_enum.heading);
              },
            ),
          ],
        ),
      ),
      // drawer: buildDrawer(context, route),
      body: SlidingUpPanel(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        controller: panelController,
        backdropTapClosesPanel: true,
        backdropEnabled: true,
        backdropOpacity: 0,
        panelBuilder: (scrollController) => buildSlidingPanel(scrollController),
        minHeight: 130,
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
                        polylines: [...polylines],
                      ),
                      MarkerLayerOptions(markers: markers, key: Key('1')),
                      MarkerLayerOptions(markers: currentCarPos, key: Key('2')),
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
                      margin: EdgeInsets.fromLTRB(0, 100, 0, 0),
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
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: Icon(Icons.car_repair),
                          color: Colors.black,
                          onPressed: () {
                            markLastCarPos(selected.value).then((v) {
                              mapController.fitBounds(LatLngBounds(v, v),);
                            });
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
