import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';

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
import 'package:networkapp/profile-visits/profile_visits.dart';
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

class UsersReportsPage extends StatefulWidget {
  final String currentUserId;

  UsersReportsPage({Key key, this.currentUserId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      UsersReportsPageState(
          currentUserId: currentUserId);
}

class UsersReportsPageState
    extends State<UsersReportsPage> {
  UsersReportsPageState(
      {Key key,
      @required this.currentUserId,
      this.position,
      this.radius,
      this.email});

  String currentUserId;
  var position;
  String username;
  var radius;
  String email;
  String peerEmail;
  Position pos;
  bool showingIncomingScreen = false;
  SharedPreferences prefs;
  final FirebaseMessaging firebaseMessaging =
      FirebaseMessaging();
  final FlutterLocalNotificationsPlugin
      flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn =
      GoogleSignIn();
  final geo = Geoflutterfire();
  final _firestore = FirebaseFirestore.instance;
  var data;
  var x = 2;
  var notificationTitle;
  var notificationMsg;
  var channelIdVOIP;
  List<Map<String, String>> installedApps;
  bool isLoading = false;
  var userWiseData = {};
  var lastVisitUserData = {};

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    radius = prefs.getInt('radius') ?? radius;
    email = prefs.getString('email') ?? email;
    currentUserId =
        prefs.getString('id') ?? currentUserId;
    pos = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    username = prefs.getString('nickname');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get()
        .then((document) {
      userWiseData =
          document.data()['userWiseData'];
      lastVisitUserData =
          document.data()['lastVisitUserData'];
    });
  }

  @override
  Widget build(BuildContext context) {
    readLocal();

    GeoFirePoint center = geo.point(
        latitude: pos != null ? pos.latitude : 34,
        longitude:
            pos != null ? pos.longitude : 34);

    var collectionReference =
        _firestore.collection('users');

    String field = 'position';

    new Future<String>.delayed(
            new Duration(seconds: 2),
            () => '["123", "456", "789"]')
        .then((String value) {
      setState(() {
        data = json.decode(value);
      });
    });

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // List
          Container(
            color: const Color(0xff132240),
            child: StreamBuilder(
              stream: geo
                  .collection(
                      collectionRef:
                          collectionReference)
                  .within(
                      center: center,
                      radius: radius != null
                          ? radius.toDouble()
                          : 100000000,
                      field: field),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child:
                        CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(themeColor),
                    ),
                  );
                } else {
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context,
                            index) =>
                        buildItem(context,
                            snapshot.data[index]),
                    itemCount:
                        snapshot.data.length,
                  );
                }
              },
            ),
          ),

          // Loading
          Positioned(
            child: isLoading
                ? const Loading()
                : Container(),
          )
        ],
      ),
    );
  }

  var firstRow = 0;

  Widget buildItem(BuildContext context,
      DocumentSnapshot document) {
    if (document.data()['id'] == currentUserId) {
      return Container();
    } else {
      firstRow++;

      return Column(children: <Widget>[
        Text(firstRow == 1 ? 'sllsls' : ''),
        Container(
          color: const Color(0xff2c4260),
          child: FlatButton(
            child: Row(
              children: <Widget>[
                Stack(children: <Widget>[
                  Material(
                    child: document.data()[
                                'photoUrl'] !=
                            null
                        ? CachedNetworkImage(
                            placeholder:
                                (context, url) =>
                                    Container(
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 1.0,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                            Color>(
                                        themeColor),
                              ),
                              width: 50.0,
                              height: 50.0,
                              padding:
                                  EdgeInsets.all(
                                      15.0),
                            ),
                            imageUrl:
                                document.data()[
                                    'photoUrl'],
                            width: 50.0,
                            height: 50.0,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            color: const Color(0xff2c4260),
                          ),
                    borderRadius:
                        BorderRadius.all(
                            Radius.circular(
                                0.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  
                ]),
                Flexible(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: Text(
                            'Name: ${document.data()['nickname']}',
                            style: TextStyle(
                                color:
                                    Colors.white),
                          ),
                          alignment: Alignment
                              .centerLeft,
                          margin:
                              EdgeInsets.fromLTRB(
                                  10.0,
                                  0.0,
                                  0.0,
                                  10.0),
                        ),
                        Container(
                          child: Text(
                            'Number of visits: ${userWiseData != null ? userWiseData[document.data()['id']] != null ? userWiseData[document.data()['id']].toString() : '0' : '0'}',
                            style: TextStyle(
                                color:
                                    Colors.white),
                          ),
                          alignment: Alignment
                              .centerLeft,
                          margin:
                              EdgeInsets.fromLTRB(
                                  10.0,
                                  0.0,
                                  0.0,
                                  10.0),
                        ),
                        Container(
                          child: Text(
                            'Last Visited: ${lastVisitUserData != null ? lastVisitUserData[document.data()['id']] != null ? lastVisitUserData[document.data()['id']] : '' : ''}',
                            style: TextStyle(
                                color:
                                    Colors.white),
                          ),
                          alignment: Alignment
                              .centerLeft,
                          margin:
                              EdgeInsets.fromLTRB(
                                  10.0,
                                  0.0,
                                  0.0,
                                  0.0),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(
                        left: 20.0),
                  ),
                ),
              ],
            ),
            onPressed: () {},
            color: const Color(0xff2c4260),
            padding: EdgeInsets.fromLTRB(
                25.0, 10.0, 25.0, 10.0),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                        0.0)),
          ),
          margin: EdgeInsets.only(
              bottom: 10.0,
              left: 5.0,
              right: 5.0),
        )
      ]);
    }
  }
}
