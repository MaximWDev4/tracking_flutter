import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

extension E on String {
  String lastChars(int n) => substring(length - n);
}

class Func {

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

  static String formatToLocalDT(int date, int dur) {
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
            Text(id, style: Get.theme.textTheme.bodyText1),
            Text(name, style: Get.theme.textTheme.bodyText1)
          ],
        ),
      );
    } else {
      carIdName = 'Выбрать\n технику';
      return Text(
          carIdName, style: Get.theme.textTheme.bodyText1.copyWith(fontSize: 18));
    }
  }

  static formatTime(DateTime time) {
    return "${('0' + time.hour.toString()).substring(
        ('0' + time.hour.toString()).length - 2)}:${('0' +
        time.minute.toString()).substring(
        ('0' + time.minute.toString()).length - 2)}";
  }
}
