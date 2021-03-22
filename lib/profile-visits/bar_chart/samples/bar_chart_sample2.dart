import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarChartSample2 extends StatefulWidget {
  final String currentUserId;

  BarChartSample2({Key key, this.currentUserId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      BarChartSample2State(
          currentUserId: currentUserId);
}

class BarChartSample2State
    extends State<BarChartSample2> {
  final String currentUserId;

  BarChartSample2State(
      {Key key, this.currentUserId});

  final Color leftBarColor =
      const Color(0xff53fdd7);
  final Color rightBarColor =
      const Color(0xffff5182);
  final double width = 7;
  var data;

  List<BarChartGroupData> rawBarGroups;
  List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex;

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  readLocal() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get()
        .then((document) {
      if (document.data()['visitsWeekData'] !=
          null) {
        var dat =
            document.data()['visitsWeekData'];
        var mon = dat['Monday'];
        var tue = dat['Tuesday'];
        var wed = dat['Wednesday'];
        var thu = dat['Thursday'];
        var fri = dat['Friday'];
        var sat = dat['Saturday'];
        var sun = dat['Sunday'];

        final barGroup1 = makeGroupData(
            0,
            mon != null
                ? dat['Monday'].toDouble()
                : 0.0,
            12);
        final barGroup2 = makeGroupData(
            1,
            tue != null
                ? dat['Tuesday'].toDouble()
                : 0.0,
            12);
        final barGroup3 = makeGroupData(
            2,
            wed != null
                ? dat['Wednesday'].toDouble()
                : 0.0,
            5);
        final barGroup4 = makeGroupData(
            3,
            thu != null
                ? dat['Thursday'].toDouble()
                : 0.0,
            16);
        final barGroup5 = makeGroupData(
            4,
            fri != null
                ? dat['Friday'].toDouble()
                : 0.0,
            6);
        final barGroup6 = makeGroupData(
            5,
            sat != null
                ? dat['Saturday'].toDouble()
                : 0.0,
            1.5);
        final barGroup7 = makeGroupData(
            6,
            sun != null
                ? dat['Sunday'].toDouble()
                : 0.0,
            1.5);

        final items = [
          barGroup1,
          barGroup2,
          barGroup3,
          barGroup4,
          barGroup5,
          barGroup6,
          barGroup7,
        ];

        rawBarGroups = items;

        showingBarGroups = rawBarGroups;
      } else {
        final barGroup1 = makeGroupData(0, 5, 12);
        final barGroup2 = makeGroupData(1, 5, 12);
        final barGroup3 = makeGroupData(2, 3, 5);
        final barGroup4 = makeGroupData(3, 1, 16);
        final barGroup5 = makeGroupData(4, 3, 6);
        final barGroup6 =
            makeGroupData(5, 4, 1.5);
        final barGroup7 =
            makeGroupData(6, 5, 1.5);

        final items = [
          barGroup1,
          barGroup2,
          barGroup3,
          barGroup4,
          barGroup5,
          barGroup6,
          barGroup7,
        ];

        rawBarGroups = items;

        showingBarGroups = rawBarGroups;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    new Future<String>.delayed(
            new Duration(seconds: 2),
            () => '["123", "456", "789"]')
        .then((String value) {
      setState(() {
        data = json.decode(value);
      });
    });

    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(4)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            mainAxisAlignment:
                MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    MainAxisAlignment.start,
                children: <Widget>[
                  makeTransactionsIcon(),
                  const SizedBox(
                    width: 38,
                  ),
                  const Text(
                    'Profile Visits Data',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Text(
                    'state',
                    style: TextStyle(
                        color: Color(0xff77839a),
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(
                height: 38,
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8.0),
                  child: BarChart(
                    BarChartData(
                      maxY: 20,
                      barTouchData: BarTouchData(
                          touchTooltipData:
                              BarTouchTooltipData(
                            tooltipBgColor:
                                Colors.grey,
                            getTooltipItem: (_a,
                                    _b, _c, _d) =>
                                null,
                          ),
                          touchCallback:
                              (response) {
                            if (response.spot ==
                                null) {
                              setState(() {
                                touchedGroupIndex =
                                    -1;
                                showingBarGroups =
                                    List.of(
                                        rawBarGroups);
                              });
                              return;
                            }

                            touchedGroupIndex =
                                response.spot
                                    .touchedBarGroupIndex;

                            setState(() {
                              if (response.touchInput
                                      is FlLongPressEnd ||
                                  response.touchInput
                                      is FlPanEnd) {
                                touchedGroupIndex =
                                    -1;
                                showingBarGroups =
                                    List.of(
                                        rawBarGroups);
                              } else {
                                showingBarGroups =
                                    List.of(
                                        rawBarGroups);
                                if (touchedGroupIndex !=
                                    -1) {
                                  double sum = 0;
                                  for (BarChartRodData rod
                                      in showingBarGroups[
                                              touchedGroupIndex]
                                          .barRods) {
                                    sum += rod.y;
                                  }
                                  final avg = sum /
                                      showingBarGroups[
                                              touchedGroupIndex]
                                          .barRods
                                          .length;

                                  showingBarGroups[
                                          touchedGroupIndex] =
                                      showingBarGroups[
                                              touchedGroupIndex]
                                          .copyWith(
                                    barRods: showingBarGroups[
                                            touchedGroupIndex]
                                        .barRods
                                        .map(
                                            (rod) {
                                      return rod
                                          .copyWith(
                                              y: avg);
                                    }).toList(),
                                  );
                                }
                              }
                            });
                          }),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) =>
                              const TextStyle(
                                  color: Color(
                                      0xff7589a2),
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 14),
                          margin: 20,
                          getTitles:
                              (double value) {
                            switch (
                                value.toInt()) {
                              case 0:
                                return 'Mon';
                              case 1:
                                return 'Tue';
                              case 2:
                                return 'Wed';
                              case 3:
                                return 'Thu';
                              case 4:
                                return 'Fri';
                              case 5:
                                return 'Sat';
                              case 6:
                                return 'Sun';
                              default:
                                return '';
                            }
                          },
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (value) =>
                              const TextStyle(
                                  color: Color(
                                      0xff7589a2),
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 14),
                          margin: 32,
                          reservedSize: 14,
                          getTitles: (value) {
                            if (value == 0) {
                              return '0';
                            } else if (value ==
                                10) {
                              return '10';
                            } else if (value ==
                                20) {
                              return '20';
                            } else if (value ==
                                30) {
                              return '30';
                            } else {
                              return '';
                            }
                          },
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: showingBarGroups,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(
      int x, double y1, double y2) {
    return BarChartGroupData(
        barsSpace: 4,
        x: x,
        barRods: [
          BarChartRodData(
            y: y1,
            colors: [leftBarColor],
            width: width,
          ),
        ]);
  }

  Widget makeTransactionsIcon() {
    const double width = 4.5;
    const double space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color: Colors.white.withOpacity(1),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color: Colors.white.withOpacity(0.4),
        ),
      ],
    );
  }
}
