import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class CustomSlider extends StatefulWidget {
  var radius;
  var maxx;
  var minn;
  var slidIcon;
  final Function notifyParent;
  CustomSlider(
      {Key key,
      this.radius,
      this.maxx,
      this.minn,
      this.notifyParent,
      this.slidIcon})
      : super(key: key);
  @override
  State createState() => CustomSliderState(
      radius: radius,
      maxx: maxx,
      minn: minn,
      notifyParent: notifyParent,
      slidIcon: slidIcon);
}

class CustomSliderState
    extends State<CustomSlider> {
  double lowerVal = 0;
  var radius;
  final Function notifyParent;
  var maxx;
  var minn;
  var slidIcon;
  SharedPreferences prefs;
  CustomSliderState(
      {Key key,
      this.radius,
      this.maxx,
      this.minn,
      this.notifyParent,
      this.slidIcon});

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Theme(
          data: Theme.of(context).copyWith(
              primaryColor: primaryColor),
          child: Column(children: <Widget>[
            FlutterSlider(
              values: [lowerVal],
              max: maxx.toDouble(),
              min: minn.toDouble(),
              tooltip: FlutterSliderTooltip(
                leftPrefix: Icon(
                  Icons.attach_money,
                  size: 19,
                  color: Colors.black45,
                ),
                rightSuffix: Text(" kms"),
                textStyle: TextStyle(
                    fontSize: 17,
                    color: Colors.black45),
              ),
              handler: customHandler(slidIcon),
              onDragging: (handlerIndex,
                  lowerValue, upperValue) {
                lowerVal = lowerValue;
                radius =
                    lowerValue.round().toInt();
                prefs.setInt('radius', radius);
                setState(() {});
                widget.notifyParent(radius);
              },
            )
          ])),
    );
  }

  customHandler(IconData icon) {
    return FlutterSliderHandler(
        decoration: BoxDecoration(),
        child: Column(
            mainAxisAlignment:
                MainAxisAlignment.start,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 100,
                height: 4,
                padding: const EdgeInsets.only(
                    bottom: 60.0),
                margin: EdgeInsets.only(top: 10),
                child: Container(
                  child: Icon(
                    icon,
                    color: Colors.red,
                    size: 53,
                  ),
                ),
              )
            ]));
  }
}
