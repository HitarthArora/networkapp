import 'package:flutter/material.dart';

import 'samples/line_chart_sample2.dart';

class LineChartPage extends StatefulWidget {
  final String currentUserId;

  LineChartPage({Key key, this.currentUserId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      LineChartPageState(
          currentUserId: currentUserId);
}

class LineChartPageState
    extends State<LineChartPage> {
  final String currentUserId;

  LineChartPageState(
      {Key key, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff262545),
      child: ListView(
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 36.0,
                top: 50,
              ),
              child: Text(
                'Profile Visits Trends Over a Year',
                style: TextStyle(
                    color: Color(
                      0xff6f6f97,
                    ),
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const SizedBox(
            height: 65,
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 10.0, right: 10),
            child: LineChartSample2(currentUserId:currentUserId),
          ),
        ],
      ),
    );
  }
}
