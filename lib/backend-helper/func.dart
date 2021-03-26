import 'dart:convert';
import 'dart:io';
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
    String from =  DateTime.fromMillisecondsSinceEpoch(date * 1000).toLocal().toString();
    String to = DateTime.fromMillisecondsSinceEpoch((date + dur) * 1000).toLocal().toString();
    return 'С ' + from + '\nДо' + to;
  }
}
