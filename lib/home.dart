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
import 'package:networkapp/map.dart';
import 'package:networkapp/map/main.dart';
import 'package:networkapp/voip/video/src/pages/call.dart';
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

import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  final position;
  final radius;
  final email;
  HomeScreen(
      {Key key,
      @required this.currentUserId,
      this.position,
      this.radius,
      this.email})
      : super(key: key);

  @override
  State createState() => HomeScreenState(
      currentUserId: currentUserId,
      position: position,
      radius: radius,
      email: email);
}

class HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  HomeScreenState(
      {Key key,
      @required this.currentUserId,
      @required this.position,
      @required this.radius,
      this.email});

  final String currentUserId;
  final position;
  String username;
  var radius;
  final email;
  Position pos;

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
  var notificationMessage;
  var channelIdVOIP;

  bool isLoading = false;

  List<Choice> choices = const <Choice>[
    const Choice(
        title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Map', icon: Icons.map),
    const Choice(
        title: 'Log out',
        icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    readLocal();
    registerNotification();
    configLocalNotification();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'status': 'online'});
    } else {
      DateTime now = DateTime.now();
      DateFormat formatter =
          DateFormat('dd-MM-yyyy');
      String formatted = formatter.format(now);
      var currentTime =
          DateFormat.jm().format(DateTime.now());
      var obj = {
        "dateTime": now,
        "date": formatted,
        "time": currentTime,
      };
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'status': 'offline',
        'lastSeen': obj
      });
    }
  }

  void registerNotification() {
    firebaseMessaging
        .requestNotificationPermissions();

    firebaseMessaging.configure(onMessage:
        (Map<String, dynamic> message) {
      print('onMessage: $message');
      notificationMessage = message;
      channelIdVOIP =
          message['data']['channelId'];
      Platform.isAndroid
          ? showNotification(
              message['notification'],
              message['data']['channelId'])
          : showNotification(
              message['aps']['alert'],
              message['data']['channelId']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(
          msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings(
            'app_icon');
    var initializationSettingsIOS =
        new IOSInitializationSettings();
    var initializationSettings =
        new InitializationSettings(
            initializationSettingsAndroid,
            initializationSettingsIOS);
    flutterLocalNotificationsPlugin
        .initialize(initializationSettings);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else if (choice.title == 'Settings') {
      setState(() {
        data = 2;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ChatSettings(x: x)));
    } else {
      setState(() {
        data = 2;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MapsDemo()));
    }
  }

  void showNotification(
      message, channelId) async {
    var androidPlatformChannelSpecifics =
        new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.example.networkapp'
          : 'com.example.networkapp',
      'Networkapp',
      'Connecting users',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails();
    var platformChannelSpecifics =
        new NotificationDetails(
            androidPlatformChannelSpecifics,
            iOSPlatformChannelSpecifics);
    var isNavigationDone = false;

    print(message);

    if (message['title'].toString() ==
        "Channel Invitation") {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title:
              Text(message['title'].toString()),
          content:
              Text(message['body'].toString()),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.pop(context);
                isNavigationDone = true;
              },
              child: const Text('Cancel'),
            ),
            FlatButton(
              onPressed: () async {
                Navigator.pop(context);
                isNavigationDone = true;

                await _handleCameraAndMic(
                    Permission.camera);

                await _handleCameraAndMic(
                    Permission.microphone);

                Fluttertoast.showToast(
                    msg: channelId.toString());

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CallPage(
                      channelName:
                          channelId.toString(),
                    ),
                  ),
                );
              },
              child: const Text('Join'),
            )
          ],
        ),
      );
    }

    await flutterLocalNotificationsPlugin.show(
        0,
        message['title'].toString(),
        message['body'].toString(),
        platformChannelSpecifics,
        payload: json.encode(message));

    if (!isNavigationDone &&
        message['title'].toString() ==
            "Channel Invitation") {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: channelId.toString(),
          ),
        ),
      );
    }
//    print(message['body'].toString());
//    print(json.encode(message));
/*
    await flutterLocalNotificationsPlugin.show(
        0,
        message['title'].toString(),
        message['body'].toString(),
        platformChannelSpecifics,
        payload: json.encode(message));
*/

//    await flutterLocalNotificationsPlugin.show(
//        0, 'plain title', 'plain body', platformChannelSpecifics,
//        payload: 'item x');
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.only(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(
                    bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(
                          bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight:
                              FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(
                          right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight:
                              FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(
                          right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight:
                              FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<void> _handleCameraAndMic(
      Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'status': 'offline'});

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    radius = prefs.getInt('radius') ?? radius;
    pos = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    username = prefs.getString('nickname');
  }

  Future<void> sendNotification(
      receiver, msg) async {
    var token = await getToken(receiver);
    print('receiver id: $receiver');
    print('token : $token');

    final data = jsonEncode({
      "notification": {
        "body": msg,
        "title": "Chat Invitation"
      },
      "priority": "high",
      "data": {
        "click_action":
            "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done"
      },
      "to": "$token"
    });

    try {
      await http.post(
        Uri.parse(
            "https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'content-type': 'application/json',
          'Authorization':
              'key=AAAABKJiMQo:APA91bGkKzaM07yF2FTfTIrKALQajayZuutRguc1gxvkWZDd19p-xI0VYt9G0lQR3maypMb9Nt_1t4VmtKTKZ66ISl-ZHmvOd2CrtjfzvEeMNg_Mk9XqbRT5ECZbiiBULQuYuAKCM8z0'
        },
        body: data,
      );
      print('FCM request for device sent!');
    } catch (e) {
      print('error: $e');
    }
  }

  static Future<String> getToken(userId) async {
    final FirebaseFirestore _db =
        FirebaseFirestore.instance;
    var token;
    await _db
        .collection('users')
        .doc(userId)
        .get()
        .then((document) {
      token = document.data()['pushToken'];
    });
    return token;
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

    /*
    if (notificationMessage != null) {
      Fluttertoast.showToast(msg: 'heml0oooooo');
      if (notificationMessage['title']
              .toString() ==
          "Channel Invitation") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallPage(
              channelName:
                  channelIdVOIP.toString(),
            ),
          ),
        );
        notificationMessage = null;
        Fluttertoast.showToast(msg: 'hemlo');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ChatSettings(x: x)));
      }
    }
    */

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MAIN',
          style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(
                              color:
                                  primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
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
                                    Color>(
                                themeColor),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding:
                          EdgeInsets.all(10.0),
                      itemBuilder: (context,
                              index) =>
                          buildItem(
                              context,
                              snapshot
                                  .data[index]),
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
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildItem(BuildContext context,
      DocumentSnapshot document) {
    if (document.data()['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
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
                          imageUrl: document
                              .data()['photoUrl'],
                          width: 50.0,
                          height: 50.0,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.account_circle,
                          size: 50.0,
                          color: greyColor,
                        ),
                  borderRadius: BorderRadius.all(
                      Radius.circular(25.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                new Positioned(
                  right: 0.0,
                  bottom: 0.0,
                  child: new Icon(Icons.circle,
                      size: 14,
                      color: document.data()[
                                  'status'] ==
                              "online"
                          ? Colors.green
                          : Colors.black54),
                ),
              ]),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          'Nickname: ${document.data()['nickname']}',
                          style: TextStyle(
                              color:
                                  primaryColor),
                        ),
                        alignment:
                            Alignment.centerLeft,
                        margin:
                            EdgeInsets.fromLTRB(
                                10.0,
                                0.0,
                                0.0,
                                5.0),
                      ),
                      Container(
                        child: Text(
                          'About me: ${document.data()['aboutMe'] ?? 'Not available'}',
                          style: TextStyle(
                              color:
                                  primaryColor),
                        ),
                        alignment:
                            Alignment.centerLeft,
                        margin:
                            EdgeInsets.fromLTRB(
                                10.0,
                                0.0,
                                0.0,
                                0.0),
                      )
                    ],
                  ),
                  margin:
                      EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(
                        peerId: document.id,
                        peerAvatar: document
                            .data()['photoUrl'],
                        emailId: document
                            .data()['email'],
                        peerName: document
                            .data()['nickname'],
                        peerStatus: document
                            .data()['status'])));

            final Email email = Email(
              body:
                  'Inviting you to chat on the Network App',
              subject: 'Chat Invitation',
              recipients: [
                document.data()['email']
              ],
              isHTML: false,
            );
            FlutterEmailSender.send(email);

            sendNotification(
                document.id,
                username != null
                    ? username +
                        " is inviting you to chat"
                    : "User is inviting you to chat");
            prefs.setString('peerAvatar',
                document.data()['photoUrl']);
          },
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(
              25.0, 10.0, 25.0, 10.0),
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(
            bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
