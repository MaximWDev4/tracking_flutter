import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong/latlong.dart';

import '../../backend-helper/func.dart';

class Parking {
  static const double size = 25;

  Parking({this.dt, this.park, this.lat, this.long});

  final int dt;
  final int park;
  final double lat;
  final double long;
}

class ParkingMarker extends Marker {
  ParkingMarker({@required this.monument})
      : super(
    anchorPos: AnchorPos.align(AnchorAlign.center),
    height: Parking.size,
    width: Parking.size,
    point: LatLng(monument.lat, monument.long),
    builder: (BuildContext ctx) => Image(image: AssetImage('assets/parked.png'), height: 30, width: 30,),
  );

  final Parking monument;
}

class ParkingMarkerPopup extends StatelessWidget {
  const ParkingMarkerPopup({Key key, this.monument}) : super(key: key);
  final Parking monument;

  @override
  Widget build(BuildContext context) {
    DateTime _parkDuration = new DateTime.fromMillisecondsSinceEpoch(monument.park*1000).toUtc();
    return Container(
      width: 280,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Парковка', style: Get.theme.textTheme.headline5,),
              Text(Func.formatToLocalDT(monument.dt, monument.park),
                style: Get.theme.textTheme.headline6,),
              Text( 'Длительность: ' + (_parkDuration.hour > 0 ? (_parkDuration.hour.toString() + 'ч. ') : ' ') + _parkDuration.minute.toString() + 'м.',
                style: Get.theme.textTheme.headline6.copyWith(fontSize: 16),),

            ],
          ),
        ),
      ),
    );
  }
}
