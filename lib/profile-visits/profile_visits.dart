import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:networkapp/chat.dart';
import 'package:networkapp/const.dart';
import 'package:networkapp/settings.dart';
import 'package:networkapp/map/main.dart';
import 'package:networkapp/voip/video/src/pages/call.dart';
import 'package:networkapp/voip/audio/src/pages/call.dart';
import 'package:networkapp/widget/loading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import 'bar_chart/bar_chart_page2.dart';
import 'line_chart/line_chart_page.dart';
import 'users_report/users_report.dart';

class ProfileVisits extends StatefulWidget {
  final String currentUserId;

  ProfileVisits({Key key, this.currentUserId})
      : super(key: key);

  @override
  State createState() => ProfileVisitsState(
      currentUserId: currentUserId);
}

class ProfileVisitsState
    extends State<ProfileVisits> {
  final String currentUserId;

  ProfileVisitsState(
      {Key key, this.currentUserId});

  int _currentPage = 0;

  final _controller =
      PageController(initialPage: 0);
  final _duration = Duration(milliseconds: 300);
  final _curve = Curves.easeInOutCubic;
  final _pages = [
    BarChartPage2(),
    LineChartPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page.round();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFILE VISITS',
          style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: PageView(
          physics: kIsWeb
              ? NeverScrollableScrollPhysics()
              : AlwaysScrollableScrollPhysics(),
          controller: _controller,
          children: [
            BarChartPage2(
                currentUserId: currentUserId),
            LineChartPage(
                currentUserId: currentUserId),
            UsersReportsPage(
                currentUserId: currentUserId)
          ],
        ),
      ),
      bottomNavigationBar: kIsWeb
          ? Container(
              padding: EdgeInsets.all(16),
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Visibility(
                    visible: _currentPage != 0,
                    child: FloatingActionButton(
                      onPressed: () => _controller
                          .previousPage(
                              duration: _duration,
                              curve: _curve),
                      child: Icon(Icons
                          .chevron_left_rounded),
                    ),
                  ),
                  Spacer(),
                  Visibility(
                    visible: _currentPage !=
                        _pages.length - 1,
                    child: FloatingActionButton(
                      onPressed: () =>
                          _controller.nextPage(
                              duration: _duration,
                              curve: _curve),
                      child: Icon(Icons
                          .chevron_right_rounded),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
