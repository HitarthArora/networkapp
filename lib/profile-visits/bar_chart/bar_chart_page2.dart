import 'package:flutter/material.dart';

import 'samples/bar_chart_sample2.dart';

class BarChartPage2 extends StatefulWidget {
  final String currentUserId;

  BarChartPage2({Key key, this.currentUserId})
      : super(key: key);

  @override
  State createState() => BartChartPage2State(
      currentUserId: currentUserId);
}

class BartChartPage2State
    extends State<BarChartPage2> {
  final String currentUserId;

  BartChartPage2State(
      {Key key, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff132240),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: BarChartSample2(
              currentUserId: currentUserId),
        ),
      ),
    );
  }
}
