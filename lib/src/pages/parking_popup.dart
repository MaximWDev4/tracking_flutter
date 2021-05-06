import 'dart:convert';

import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  const ParkingMarkerPopup({Key key, this.monument,}) : super(key: key);
  final Parking monument;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: BuildParkingInfo(monument),
        ),
      ),
    );
  }
}

class ManyParkingMarkersPopup extends StatefulWidget {
  const ManyParkingMarkersPopup({Key key, this.monuments}) : super(key: key);
  final List<Parking> monuments;

  State<StatefulWidget> createState() {
    return ManyParkingMarkersPopupState();
  }
}
class ManyParkingMarkersPopupState extends State<ManyParkingMarkersPopup> {
  final CarouselController buttonCarouselController = new CarouselController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 280,
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        height: 100,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.1,
                        child:
                        TextButton(
                          onPressed: () =>
                              buttonCarouselController.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut),
                          child: Icon(Icons.keyboard_arrow_left_rounded),
                        ),
                      ),
                      ParksCarousel(widget.monuments, buttonCarouselController),
                      Container(
                        height: 100,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.1,
                        child:
                        TextButton(
                          onPressed: () {
                            buttonCarouselController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                          child: Icon(Icons.keyboard_arrow_right_rounded),
                        ),
                      ),
                    ],
                  )
            )
        )
    );
  }
}

class ParksCarousel extends StatefulWidget {
  ParksCarousel(this.monuments, this.buttonCarouselController);
  @required final CarouselController buttonCarouselController;
  @required final monuments;
  @override
  State<StatefulWidget> createState() {
    return _ManuallyControlledSliderState();
  }
}
class _ManuallyControlledSliderState extends State<ParksCarousel> {
  var _current = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      Container(
        height: 240,
          width: MediaQuery
              .of(context)
              .size
              .width * 0.5,
          child: Column(
            children: [
              CarouselSlider(
                items: [
                  for (var monument in widget.monuments)
                    BuildParkingInfo(monument)
                ],
                carouselController: widget.buttonCarouselController,
                options: CarouselOptions(
                    height: 210,
                    scrollDirection: Axis.horizontal,
                    viewportFraction: 1,
                    autoPlay: false,
                    onPageChanged: (i, r) {
                      setState(() {
                        _current = i;
                      });
                    }
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var item in widget.monuments)
                  Container(
                    width: 8.0,
                    height: 8.0,
                    margin: EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _current == widget.monuments.indexOf(item)
                          ? Color.fromRGBO(0, 0, 0, 0.9)
                          : Color.fromRGBO(0, 0, 0, 0.4),
                    ),
                  ),
                  ]
                ),
            ],
          )
      );
}

class BuildParkingInfo extends StatelessWidget {
  BuildParkingInfo(this.monument);

  final monument;

  DateTime getParkDuration(Parking monument) {
    return new DateTime.fromMillisecondsSinceEpoch(monument.park * 1000)
        .toUtc();
  }

  @override
  Widget build(BuildContext context) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Парковка', style: Get.theme.textTheme.headline5, textAlign: TextAlign.center,),
          Func.formatToLocalDT(monument.dt, monument.park),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child:
            SizedBox(
              width: 200,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black)
                ),
              ),
            ),
          ),
          Column(children: [
            Text('Длительность: ',
              style: Get.theme.textTheme.headline6.copyWith(
                  fontWeight: FontWeight.normal,
                  fontSize: 15),),
            Text(
            (getParkDuration(monument).hour > 0
                ? (getParkDuration(monument).hour.toString() +
                'ч. ')
                : ' ') +
                getParkDuration(monument).minute.toString() + 'м.',
            style: Get.theme.textTheme.headline6.copyWith(
                fontSize: 16),),
          ],)
        ],
      );
}
