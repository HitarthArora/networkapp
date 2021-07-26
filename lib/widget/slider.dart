import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../const.dart';

class CustomSlider extends StatefulWidget {
  var radius;
  var maxx;
  var minn;
  var slidIcon;
  var slidIcon2;
  var color;
  var sliderThemeColor;
  final Function notifyParent;
  bool isRangeSlider;
  CustomSlider(
      {Key key,
      this.radius,
      this.maxx,
      this.minn,
      this.notifyParent,
      this.slidIcon,
      this.slidIcon2,
      this.color,
      this.sliderThemeColor,
      this.isRangeSlider})
      : super(key: key);
  @override
  State createState() => CustomSliderState(
      radius: radius,
      maxx: maxx,
      minn: minn,
      notifyParent: notifyParent,
      slidIcon: slidIcon,
      slidIcon2: slidIcon2,
      color: color,
      sliderThemeColor: sliderThemeColor,
      isRangeSlider: isRangeSlider);
}

class CustomSliderState
    extends State<CustomSlider> {
  double lowerVal = 0;
  double upperVal = 10;
  var radius;
  final Function notifyParent;
  var maxx;
  var minn;
  var slidIcon;
  var slidIcon2;
  var color;
  var sliderThemeColor;
  SharedPreferences prefs;
  bool isRangeSlider;
  CustomSliderState(
      {Key key,
      this.radius,
      this.maxx,
      this.minn,
      this.notifyParent,
      this.slidIcon,
      this.slidIcon2,
      this.color,
      this.sliderThemeColor,
      this.isRangeSlider});

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
              primaryColor: sliderThemeColor),
          child: Column(children: <Widget>[
            FlutterSlider(
              values: isRangeSlider != null
                  ? isRangeSlider
                      ? [lowerVal, upperVal]
                      : [lowerVal]
                  : [lowerVal],
              max: maxx.toDouble(),
              min: minn.toDouble(),
              rangeSlider: isRangeSlider,
              tooltip: FlutterSliderTooltip(
                /*
                leftPrefix: Icon(
                  Icons.attach_money,
                  size: 19,
                  color: Colors.black45,
                ),
                */
                leftSuffix: Text(" kms"),
                textStyle: TextStyle(
                    fontSize: 17,
                    color: Colors.black45),
              ),
              hatchMark: FlutterSliderHatchMark(
                density:
                    0.5, // means 50 lines, from 0 to 100 percent
                labels: [
                  FlutterSliderHatchMarkLabel(
                      percent: 0,
                      label:
                          Text(minn.toString())),
                  FlutterSliderHatchMarkLabel(
                      percent: 100,
                      label:
                          Text(maxx.toString())),
                ],
              ),
              handler:
                  customHandler(slidIcon, color),
              rightHandler:
                  customHandler(slidIcon2, color),
              trackBar: FlutterSliderTrackBar(
                inactiveTrackBar: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(20),
                  color: Colors.black12,
                  border: Border.all(
                      width: 3,
                      color: Colors.blue),
                ),
                activeTrackBar: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(4),
                    color: Colors.blue
                        .withOpacity(0.5)),
              ),
              onDragging: (handlerIndex,
                  lowerValue, upperValue) {
                lowerVal = lowerValue;
                upperVal = upperValue;
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

  customHandler(IconData icon, var color) {
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
                    color: color,
                    size: 53,
                  ),
                ),
              )
            ]));
  }
}
