import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension E on String {
  String lastChars(int n) => substring(length - n);
}

class Func {
  static const double LN2 = 0.6931471805599453;
  static const int WORLD_PX_HEIGHT = 256;
  static const int WORLD_PX_WIDTH = 256;

  // static const _base = '192.168.0.50:8080';
  static const _base = '185.97.113.59:8101';
  static get url {
    // return 'mishka.pro/bike-gps/';
    return '/';
  }
  static const _headers = {
    HttpHeaders
        .contentTypeHeader: 'application/x-www-form-urlencoded; charset=UTF-8'
  };
  static Future<SharedPreferences> get pref async => await SharedPreferences.getInstance();

  static Future<String> logIn({String base = _base, Map<String, String> headers = _headers, un, pw}) async {
    final Uri uri = Uri.http(
        base, url, { 'auth': ''});
    return http.post(uri, body: 'USERNAME=' + un + '&PASSWORD=' + pw, headers: headers).then((response) async {
      var responseJson = jsonDecode(response.body);
      if (response.statusCode == 200) {
        (await pref).setString('Token', responseJson['token']);
        return null;
      } else if (response.statusCode == 404) {
        return ('error 404: ' + responseJson.statusText + '\n404 Не найден путь');
      } else {
        return ('some other error: ' + responseJson.status + '\nError Неожиданная ошибка сети');
      }
    }).timeout(Duration(milliseconds: timeDilation.ceil() * 10000), onTimeout: () => 'Время запроса истекло!')
        .catchError((onError) => 'Ошибка!');
  }

  static Future<List> fetchCars({String base = _base, Map<String, String> headers = _headers}) async {
    var token = (await pref).getString('Token');
    List cars = [];
    final Uri uri = Uri.http(
        base, url, { 'cars': ''});
    return http.post(uri, body: 'Token=' + token, headers: headers).then((response) {
      List groups = jsonDecode(response.body)['groups'];
      // cars = groups['cars'];
      groups.forEach((group) => cars = [...cars, ...group['cars']]);
      return cars;
    }).timeout(Duration(milliseconds: timeDilation.ceil() * 10000), onTimeout: () {
      Get.rawSnackbar(message:'Время запроса истекло!');
      return [];
    }).catchError((err) {
      Get.rawSnackbar(message: err);
      return [];
    });
  }

  static Future<List> fetchPath({String base = _base, Map<String, String> headers = _headers, cars, car, DateTime dateFrom, DateTime dateTo}) async {
    var dots;
    // if (cars.isNotEmpty) {
    var token = (await pref).getString('Token');
      int from = (dateFrom.millisecondsSinceEpoch / 1000).floor();
      int to = (dateTo.millisecondsSinceEpoch / 1000).floor();
      final Uri uri = Uri.http(
          base, url, { 'track': ''});
      var body = 'Token='+ token +'&OT=' + from.toString() + '&DO=' + to.toString() +
          '&ID=' + car.toString();
      return await http.post(uri, body: body, headers: headers).then((
          response) {
        dots = jsonDecode(response.body)['data'];
        return dots;
      }).timeout(Duration(milliseconds: timeDilation.ceil() * 10000), onTimeout: () {
            Get.rawSnackbar(message:'Время запроса истекло!');
            return [];
          }).catchError((error) {
              Get.rawSnackbar(message: error);
          });
    // } else {
    //   return [];
    // }
  }


  static Future<List> fetchParking({String base = _base, Map<String, String> headers = _headers, cars, car, DateTime dateFrom, DateTime dateTo}) async {
    // if (cars.isNotEmpty) {
    var token = (await pref).getString('Token');
      int from = (dateFrom.millisecondsSinceEpoch / 1000).floor();
      int to = (dateTo.millisecondsSinceEpoch / 1000).floor();
      final Uri uri = Uri.http(
          base, url, { 'parking': ''});
      var body = 'Token='+ token +'&OT=' + from.toString() + '&DO=' + to.toString() +'&ID=' + car.toString();
      return await http.post(uri, body: body, headers: headers).then((response) {
        return jsonDecode(response.body)['data'];
      }).timeout(Duration(milliseconds: timeDilation.ceil() * 10000), onTimeout: () {
        Get.rawSnackbar(message:'Время запроса истекло!');
        return [];
      }).catchError((error) {
        Get.rawSnackbar(message: error);
        return [];
      });
    // }
    // return [];
  }

  static Future<List<dynamic>> fetchLast({String base = _base, Map<String, String> headers = _headers, car,}) async {
    // track&last=1
    var token = (await pref).getString('Token');
    int from = (DateTime.now().millisecondsSinceEpoch / 1000 - 86400).floor();
    int to = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final Uri uri = Uri.http(
        base, url, { 'track': '', 'LAST': '1'});
    var body = 'Token='+ token +'&OT=' + from.toString() + '&DO=' + to.toString() +'&ID=' + car.toString()+ '&LAST=1';
    return await http.post(uri, body: body, headers: headers).then((response) {
      return jsonDecode(response.body)['data'];
    }).timeout(Duration(milliseconds: timeDilation.ceil() * 10000), onTimeout: () {
      Get.rawSnackbar(message:'Время запроса истекло!');
      return [];
    }).catchError((error) {
      Get.rawSnackbar(message: error);
      return [];
    });
  }

  static Widget formatToLocalDT(int date, int dur) {
    var normalStyle = Get.theme.textTheme.headline6.copyWith(fontWeight: FontWeight.normal, fontSize: 18);
    var thickStyle = Get.theme.textTheme.headline6.copyWith(fontWeight: FontWeight.bold, fontSize: 18);
    const months_name = [
      'января', 'февраля', 'марта',
      'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября',
      'октября', 'ноября', 'декабря'
    ];
    DateTime fromDT =  DateTime.fromMillisecondsSinceEpoch(date * 1000);
    String fromStr = ('0' + fromDT.hour.toString()).lastChars(2) + ':' + ('0' + fromDT.minute.toString()).lastChars(2) + ', ' + fromDT.day.toString() + ' ' + months_name[fromDT.month-1];
    DateTime toDT = DateTime.fromMillisecondsSinceEpoch((date + dur) * 1000);
    String toStr =  ('0' + toDT.hour.toString()).lastChars(2) + ':' + ('0' + toDT.minute.toString()).lastChars(2) + ', ' + toDT.day.toString() + ' ' + months_name[toDT.month-1];
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('С ', style: normalStyle,), Text(fromStr, style: thickStyle,) ],),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('До ', style: normalStyle,),  Text(toStr, style: thickStyle,)]),
    ]);
  }

  static dynamic getCarNom(List cars, int selected, textOrWidget) {
    var carIdName = '';
    var name = '';
    var id = '';
    if (cars.isNotEmpty && selected != 0) {
      carIdName = (cars[cars.indexWhere((element) =>
      element['id'] == selected)]['nomer']);
      name = carIdName.substring(carIdName.indexOf(' '));
      id = carIdName.substring(0, carIdName.indexOf(' '));
      if (textOrWidget) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(id,
                  style: Get.theme.textTheme.bodyText1.copyWith(fontSize: 13)),
              Text(name,
                style: Get.theme.textTheme.bodyText1.copyWith(fontSize: 12),
                textAlign: TextAlign.center,)
            ],
          ),
        );
      } else {
        return id + name;
      }
    } else {
      carIdName = 'Выбрать\n технику';
      if (textOrWidget) {
        return Text(
            carIdName,
            style: Get.theme.textTheme.bodyText1.copyWith(fontSize: 18));
      } else {
        return 'Выбрать технику';
      }
    }
  }

  static String getCarNameNom(List cars, int selected) {
    var carIdName = '';
    var name = '';
    var id = '';
    if (cars.isNotEmpty && selected != 0) {
      carIdName = (cars[cars.indexWhere((element) =>
      element['id'] == selected)]['nomer']);
      name = carIdName.substring(carIdName.indexOf(' '));
      id = carIdName.substring(0, carIdName.indexOf(' '));
      return name + '' + id;
    }
    return 'Не удалось добыть название';
  }

  static formatTime(DateTime time) {
    return "${('0' + time.hour.toString()).substring(
        ('0' + time.hour.toString()).length - 2)}:${('0' +
        time.minute.toString()).substring(
        ('0' + time.minute.toString()).length - 2)}";
  }
static formatDateOfTime(DateTime time) {
    return "${time.month}.${time.day}.${time.year}";
  }



  static latRad(double lat) {
    double ssin = sin(lat * PI / 180);
    double radX2 = log((1 + ssin) / (1 - ssin)) / 2;
    return max<double>(min<double>(radX2, PI), -PI) / 2;
  }
  static zoom(int mapPx, int worldPx, double fraction) {
    const double LN2 = 0.6931471805599453;
    return round(log(mapPx / worldPx / fraction) / LN2);
  }

  static getZoom({Function latRad: latRad, zoom: zoom, WORLD_PX_HEIGHT: WORLD_PX_HEIGHT, WORLD_PX_WIDTH: WORLD_PX_WIDTH, bounds, mapHeightPx, mapWidthPx}) {
    LatLng ne = bounds.northEast;
    LatLng sw = bounds.southWest;
    double latFraction = (latRad(ne.latitude) - latRad(sw.latitude)) / PI;

    double lngDiff = ne.longitude - sw.longitude;
    double lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360;
    double latZoom = zoom(mapHeightPx, WORLD_PX_HEIGHT, latFraction);
    double lngZoom = zoom(mapWidthPx, WORLD_PX_WIDTH, lngFraction);

    double result = min<double>(latZoom, lngZoom);
    return result;
  }

  static toRad(num n) {
    return n * PI / 180;
  }
  static double haversineFunction(LatLng A, LatLng B) {

    var lat2 = B.latitude;
    var lon2 = B.longitude;
    var lat1 = A.latitude;
    var lon1 = A.longitude;

    var R = 6371; // km
//has a problem with the .toRad() method below.
    var x1 = lat2-lat1;
    var dLat = toRad(x1);
    var x2 = lon2-lon1;
    var dLon = toRad(x2);
    var a = sin(dLat/2) * sin(dLat/2) +
        cos(toRad(lat1)) * cos(toRad(lat2)) *
            sin(dLon/2) * sin(dLon/2);
    var c = 2 * atan2(sqrt(a), sqrt(1-a));
    var d = R * c;
    print(d*1000);
    return d*1000;
  }

  static findDistFromZoom(zoom) {
    var dist = 10;
    print(zoom);
    for ( var i= 1; i <= 18 - zoom; i++) {
      dist = dist*2;
    }
    print(dist);
    return dist;
  }
}
