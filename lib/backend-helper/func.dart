import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Func {

  static const _base = '192.168.0.50:8080';
  // static const _base = '185.97.113.59:8101';
  static const _headers = {
    HttpHeaders
        .contentTypeHeader: 'application/x-www-form-urlencoded; charset=UTF-8'
  };

  static Future fetchCars({String base = _base, Map<String, String> headers = _headers}) async {
    var cars;
    final Uri uri = Uri.http(
        base, '/mishka.pro/bike-gps/', { 'cars': ''});
    return http.post(uri, body: 'Token=123', headers: headers).then((response) {
      print(response);
      cars = jsonDecode(response.body)['groups']['cars'];
      return cars;
    }).catchError((err) {
      print(err);
      return [];
    });
  }

  static Future<List> fetchPath({String base = _base, Map<String, String> headers = _headers, cars, car, DateTime dateFrom, DateTime dateTo}) async {
    var dots;
    // if (cars.isNotEmpty) {
      int from = (dateFrom.millisecondsSinceEpoch / 1000).floor();
      int to = (dateTo.millisecondsSinceEpoch / 1000).floor();
      final Uri uri = Uri.http(
          base, 'mishka.pro/bike-gps/', { 'track': ''});
      var body = 'Token=123&OT=' + from.toString() + '&DO=' + to.toString() +
          '&ID=' + car.toString();
      print(body);
      return await http.post(uri, body: body, headers: headers).then((
          response) {
        // print(response.body);
        dots = jsonDecode(response.body)['data'];
        print(dots);
        return dots;
      }).catchError((error) {
        print(error);
      });
    // } else {
    //   return [];
    // }
  }


  static Future<List> fetchParking({String base = _base, Map<String, String> headers = _headers, cars, car, DateTime dateFrom, DateTime dateTo}) async {
    // if (cars.isNotEmpty) {
      int from = (dateFrom.millisecondsSinceEpoch / 1000).floor();
      int to = (dateTo.millisecondsSinceEpoch / 1000).floor();
      final Uri uri = Uri.http(
          base, 'mishka.pro/bike-gps/', { 'parking': ''});
      var body = 'Token=123&OT=' + from.toString() + '&DO=' + to.toString() +'&ID=' + car.toString();
      return await http.post(uri, body: body, headers: headers).then((response) {
        print(jsonDecode(response.body)['data']);
        return jsonDecode(response.body)['data'];
      }).catchError((error) => print(error));
    // }
    // return [];
  }

  static String formatToLocalDT(int date, int dur) {
    const months_name = [
      'января', 'февраля', 'марта',
      'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября',
      'октября', 'ноября', 'декабря'
    ];
    DateTime fromDT =  DateTime.fromMillisecondsSinceEpoch(date * 1000);
    String fromStr = fromDT.hour.toString() + ':' + fromDT.minute.toString() + ', ' + fromDT.day.toString() + ' ' + months_name[fromDT.month-1];
    DateTime toDT = DateTime.fromMillisecondsSinceEpoch((date + dur) * 1000);
    String toStr =  toDT.hour.toString() + ':' + toDT.minute.toString() + ', ' + toDT.day.toString() + ' ' + months_name[toDT.month-1];
    return 'С ' + fromStr + '\nДо ' + toStr;
  }

  static Widget getCarNom(List cars, int selected) {
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

  static formatTime(DateTime time) {
    return "${('0' + time.hour.toString()).substring(
        ('0' + time.hour.toString()).length - 2)}:${('0' +
        time.minute.toString()).substring(
        ('0' + time.minute.toString()).length - 2)}";
  }
}
