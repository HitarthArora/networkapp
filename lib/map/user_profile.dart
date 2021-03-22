import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:intl/intl.dart';
import 'package:networkapp/chat.dart';
import 'package:networkapp/voip/video/main.dart';
import 'package:networkapp/voip/audio/main.dart';

class UserProfile extends StatefulWidget {
  final x;
  final data;
  final currentUserId;
  UserProfile(
      {Key key,
      this.x,
      this.data,
      this.currentUserId})
      : super(key: key);
  @override
  State createState() => UserProfileState(
        x: x,
        data: data,
        currentUserId: currentUserId,
      );
}

class UserProfileState
    extends State<UserProfile> {
  var x;
  var data;
  final currentUserId;
  UserProfileState(
      {Key key,
      this.x,
      this.data,
      this.currentUserId});

  TextEditingController controllerNickname;
  TextEditingController controllerStatus;
  TextEditingController controllerAboutMe;
  TextEditingController controllerRadius;
  TextEditingController controllerLatitude;
  TextEditingController controllerLongitude;
  TextEditingController controllerEmail;
  TextEditingController controllerDistance;

  SharedPreferences prefs;

  String id = '';
  String nickname = '';
  String status = '';
  String aboutMe = '';
  String email = '';
  String photoUrl = '';
  var latitude;
  var longitude;
  var distance;
  int radius = 10000000000;
  double _currentSliderValue = 0;
  double _lowerValue = 0;

  bool isLoading = false;
  File avatarImageFile;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();
  final FocusNode focusNodeRadius = FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = data != null ? data['id'] : '';
    nickname = data != null ? data['name'] : '';
    status = data != null
        ? data['status'] != null
            ? data['status'] == "online"
                ? "Online"
                : "Offline"
            : ''
        : '';
    aboutMe = data != null ? data['aboutMe'] : '';
    photoUrl =
        data != null ? data['photoUrl'] : '';
    latitude =
        data != null ? data['latitude'] : '';
    longitude =
        data != null ? data['longitude'] : '';
    distance =
        data != null ? data['distance'] : '';
    email = data != null ? data['email'] : '';
    radius = prefs.getInt('radius') ?? '';
    _currentSliderValue =
        prefs.getInt('radius').toDouble() ?? 0;
    _lowerValue =
        prefs.getInt('radius').toDouble() ?? 0;

    controllerNickname =
        TextEditingController(text: nickname);
    controllerStatus =
        TextEditingController(text: status);
    controllerAboutMe =
        TextEditingController(text: aboutMe);
    controllerRadius =
        new TextEditingController();
    controllerLatitude =
        new TextEditingController(
            text: latitude.toString());
    controllerLongitude =
        new TextEditingController(
            text: longitude.toString());
    controllerDistance =
        new TextEditingController(
            text: distance.toString() + " km");
    controllerEmail =
        new TextEditingController(text: email);

    // Force refresh input
    setState(() {});

    var date = DateTime.now();
    var day = DateFormat('EEEE').format(date);
    var month = DateFormat.MMMM().format(date);
    var insertionValue, monthValue;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .get()
        .then((document) {
      var currentValue =
          document.data()['visitsWeekData'];
      var weekData = {};
      if (currentValue != null) {
        if (currentValue[day.toString()] !=
            null) {
          insertionValue =
              currentValue[day.toString()] + 1;
        } else {
          insertionValue = 1;
        }
        weekData = currentValue;
        weekData[day] = insertionValue;
      } else {
        weekData[day] = 1;
      }

      var monthDataDB =
          document.data()['visitsMonthData'];
      var monthData = {};
      if (monthDataDB != null) {
        if (monthDataDB[month.toString()] !=
            null) {
          monthValue =
              monthDataDB[month.toString()] + 1;
        } else {
          monthValue = 1;
        }
        monthData = monthDataDB;
        monthData[month] = monthValue;
      } else {
        monthData[month] = 1;
      }

      var userWiseDataDB =
          document.data()['visitsUserData'];
      var userWiseData = {}, userValue;
      if (userWiseDataDB != null) {
        if (userWiseDataDB[currentUserId] !=
            null) {
          userValue =
              userWiseDataDB[currentUserId] + 1;
        } else {
          userValue = 1;
        }
        userWiseData = userWiseDataDB;
        userWiseData[currentUserId] = userValue;
      } else {
        userWiseData[currentUserId] = 1;
      }

      var lastVisitUserDataDB =
          document.data()['visitsUserData'];
      var lastVisitUserData = {};
      DateTime now = DateTime.now();
      DateFormat formatter =
          DateFormat('dd-MM-yyyy');
      String formatted = formatter.format(now);
      String currentTime =
          DateFormat.jm().format(DateTime.now());
      if (userWiseDataDB != null) {
        lastVisitUserData = lastVisitUserDataDB;
        lastVisitUserData[currentUserId] =
            formatted + " " + currentTime;
      } else {
        lastVisitUserData[currentUserId] =
            formatted + " " + currentTime;
      }

      FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({
        'visitsWeekData': weekData,
        'visitsMonthData': monthData,
        'userWiseData': userWiseData,
        'lastVisitUserData': lastVisitUserData,
      });
    });
  }

  List<Choice> choices = const <Choice>[
    const Choice(
        title: 'Chat',
        icon: Icons.message_outlined),
    const Choice(
        title: 'Voice Call',
        icon: Icons.local_phone),
    const Choice(
        title: 'Video Call',
        icon: Icons.video_call_sharp),
  ];

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Chat') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Chat(
                  peerId: id,
                  peerAvatar: photoUrl,
                  emailId: email,
                  peerName: nickname,
                  peerStatus: status)));
    } else if (choice.title == 'Voice Call') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VoiceCall(
                  emailId: email,
                  peerId: id,
                  peerAvatar: photoUrl)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VideoCall(
                  emailId: email, peerId: id)));
    }
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(
        source: ImageSource.gallery);

    File image = File(pickedFile.path);

    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
    }
    uploadFile();
  }

  Future uploadFile() async {
    String fileName = id;
    StorageReference reference = FirebaseStorage
        .instance
        .ref()
        .child(fileName);
    StorageUploadTask uploadTask =
        reference.putFile(avatarImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref
            .getDownloadURL()
            .then((downloadUrl) {
          photoUrl = downloadUrl;
          FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .update({
            'nickname': nickname,
            'aboutMe': aboutMe,
            'photoUrl': photoUrl,
            'radius': radius,
          }).then((data) async {
            await prefs.setString(
                'photoUrl', photoUrl);
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(
                msg: "Upload success");
          }).catchError((err) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(
                msg: err.toString());
          });
        }, onError: (err) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(
              msg: 'This file is not an image');
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(
            msg: 'This file is not an image');
      }
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();
    focusNodeRadius.unfocus();

    setState(() {
      isLoading = true;
      x = 3;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({
      'nickname': nickname,
      'aboutMe': aboutMe,
      'photoUrl': photoUrl,
      'radius': radius,
    }).then((data) async {
      await prefs.setString('nickname', nickname);
      await prefs.setString('aboutMe', aboutMe);
      await prefs.setString('photoUrl', photoUrl);
      await prefs.setInt('radius', radius);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(
          msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    print(radius);
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'USER PROFILE',
            style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: currentUserId != id
              ? <Widget>[
                  PopupMenuButton<Choice>(
                    onSelected: onItemMenuPress,
                    itemBuilder:
                        (BuildContext context) {
                      return choices
                          .map((Choice choice) {
                        return PopupMenuItem<
                                Choice>(
                            value: choice,
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  choice.icon,
                                  color:
                                      primaryColor,
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
                ]
              : <Widget>[],
        ),
        body: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  // Avatar
                  Container(
                    child: Center(
                      child: Stack(
                        children: <Widget>[
                          (avatarImageFile ==
                                  null)
                              ? (photoUrl != ''
                                  ? Material(
                                      child:
                                          CachedNetworkImage(
                                        placeholder:
                                            (context, url) =>
                                                Container(
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(themeColor),
                                          ),
                                          width:
                                              90.0,
                                          height:
                                              90.0,
                                          padding:
                                              EdgeInsets.all(20.0),
                                        ),
                                        imageUrl:
                                            photoUrl,
                                        width:
                                            90.0,
                                        height:
                                            90.0,
                                        fit: BoxFit
                                            .cover,
                                      ),
                                      borderRadius:
                                          BorderRadius.all(
                                              Radius.circular(45.0)),
                                      clipBehavior:
                                          Clip.hardEdge,
                                    )
                                  : Icon(
                                      Icons
                                          .account_circle,
                                      size: 90.0,
                                      color:
                                          greyColor,
                                    ))
                              : Material(
                                  child:
                                      Image.file(
                                    avatarImageFile,
                                    width: 90.0,
                                    height: 90.0,
                                    fit: BoxFit
                                        .cover,
                                  ),
                                  borderRadius: BorderRadius
                                      .all(Radius
                                          .circular(
                                              45.0)),
                                  clipBehavior:
                                      Clip.hardEdge,
                                ),
                        ],
                      ),
                    ),
                    width: double.infinity,
                    margin: EdgeInsets.all(20.0),
                  ),

                  // Input
                  Column(
                    children: <Widget>[
                      // Username
                      Container(
                        child: Text(
                          'Name',
                          style: TextStyle(
                              fontStyle: FontStyle
                                  .italic,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  primaryColor),
                        ),
                        margin: EdgeInsets.only(
                            left: 10.0,
                            bottom: 5.0,
                            top: 10.0),
                      ),
                      Container(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(
                                  primaryColor:
                                      primaryColor),
                          child: TextField(
                            enabled: false,
                            decoration:
                                InputDecoration(
                              hintText: 'Sweetie',
                              contentPadding:
                                  EdgeInsets.all(
                                      5.0),
                              hintStyle: TextStyle(
                                  color:
                                      greyColor),
                            ),
                            controller:
                                controllerNickname,
                            onChanged: (value) {
                              nickname = value;
                            },
                            focusNode:
                                focusNodeNickname,
                          ),
                        ),
                        margin: EdgeInsets.only(
                            left: 30.0,
                            right: 30.0),
                      ),

                      Container(
                        child: Text(
                          'Status',
                          style: TextStyle(
                              fontStyle: FontStyle
                                  .italic,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  primaryColor),
                        ),
                        margin: EdgeInsets.only(
                            left: 10.0,
                            top: 30.0,
                            bottom: 5.0),
                      ),
                      Container(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(
                                  primaryColor:
                                      primaryColor),
                          child: TextField(
                            enabled: false,
                            decoration:
                                InputDecoration(
                              hintText: 'Offline',
                              contentPadding:
                                  EdgeInsets.all(
                                      5.0),
                              hintStyle: TextStyle(
                                  color:
                                      greyColor),
                            ),
                            controller:
                                controllerStatus,
                            onChanged: (value) {},
                            focusNode:
                                focusNodeAboutMe,
                          ),
                        ),
                        margin: EdgeInsets.only(
                            left: 30.0,
                            right: 30.0),
                      ),

                      // About me
                      Container(
                        child: Text(
                          'About me',
                          style: TextStyle(
                              fontStyle: FontStyle
                                  .italic,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  primaryColor),
                        ),
                        margin: EdgeInsets.only(
                            left: 10.0,
                            top: 30.0,
                            bottom: 5.0),
                      ),
                      Container(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(
                                  primaryColor:
                                      primaryColor),
                          child: TextField(
                            enabled: false,
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Personal description',
                              contentPadding:
                                  EdgeInsets.all(
                                      5.0),
                              hintStyle: TextStyle(
                                  color:
                                      greyColor),
                            ),
                            controller:
                                controllerAboutMe,
                            onChanged: (value) {
                              aboutMe = value;
                            },
                            focusNode:
                                focusNodeAboutMe,
                          ),
                        ),
                        margin: EdgeInsets.only(
                            left: 30.0,
                            right: 30.0),
                      ),

                      // Email
                      Container(
                        child: Text(
                          'Email',
                          style: TextStyle(
                              fontStyle: FontStyle
                                  .italic,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  primaryColor),
                        ),
                        margin: EdgeInsets.only(
                            left: 10.0,
                            top: 30.0,
                            bottom: 5.0),
                      ),
                      Container(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(
                                  primaryColor:
                                      primaryColor),
                          child: TextField(
                            enabled: false,
                            decoration:
                                InputDecoration(
                              hintText:
                                  'example@gmail.com',
                              contentPadding:
                                  EdgeInsets.all(
                                      5.0),
                              hintStyle: TextStyle(
                                  color:
                                      greyColor),
                            ),
                            controller:
                                controllerEmail,
                            onChanged: (value) {
                              aboutMe = value;
                            },
                            focusNode:
                                focusNodeAboutMe,
                          ),
                        ),
                        margin: EdgeInsets.only(
                            left: 30.0,
                            right: 30.0),
                      ),

                      /*
                  //Latitude
                  Container(
                    child: Text(
                      'Latitude',
                      style: TextStyle(
                          fontStyle:
                              FontStyle.italic,
                          fontWeight:
                              FontWeight.bold,
                          color: primaryColor),
                    ),
                    margin: EdgeInsets.only(
                        left: 10.0,
                        top: 30.0,
                        bottom: 5.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(
                              primaryColor:
                                  primaryColor),
                      child: TextField(
                        enabled: false,
                        decoration:
                            InputDecoration(
                          hintText: 'latitude',
                          contentPadding:
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
                        ),
                        controller:
                            controllerLatitude,
                        onChanged: (value) {
                          aboutMe = value;
                        },
                        focusNode:
                            focusNodeAboutMe,
                      ),
                    ),
                    margin: EdgeInsets.only(
                        left: 30.0, right: 30.0),
                  ),

                  //Longitude
                  Container(
                    child: Text(
                      'Longitude',
                      style: TextStyle(
                          fontStyle:
                              FontStyle.italic,
                          fontWeight:
                              FontWeight.bold,
                          color: primaryColor),
                    ),
                    margin: EdgeInsets.only(
                        left: 10.0,
                        top: 30.0,
                        bottom: 5.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(
                              primaryColor:
                                  primaryColor),
                      child: TextField(
                        enabled: false,
                        decoration:
                            InputDecoration(
                          hintText: 'longitude',
                          contentPadding:
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
                        ),
                        controller:
                            controllerLongitude,
                        onChanged: (value) {
                          aboutMe = value;
                        },
                        focusNode:
                            focusNodeAboutMe,
                      ),
                    ),
                    margin: EdgeInsets.only(
                        left: 30.0, right: 30.0),
                  ),
                  */

                      //Distance
                      Container(
                        child: Text(
                          'Distance',
                          style: TextStyle(
                              fontStyle: FontStyle
                                  .italic,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  primaryColor),
                        ),
                        margin: EdgeInsets.only(
                            left: 10.0,
                            top: 30.0,
                            bottom: 5.0),
                      ),
                      Container(
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(
                                  primaryColor:
                                      primaryColor),
                          child: TextField(
                            enabled: false,
                            decoration:
                                InputDecoration(
                              hintText: '0.70km',
                              contentPadding:
                                  EdgeInsets.all(
                                      5.0),
                              hintStyle: TextStyle(
                                  color:
                                      greyColor),
                            ),
                            controller:
                                controllerDistance,
                            onChanged: (value) {
                              aboutMe = value;
                            },
                            focusNode:
                                focusNodeAboutMe,
                          ),
                        ),
                        margin: EdgeInsets.only(
                            left: 30.0,
                            right: 30.0),
                      ),
                    ],
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                  ),

                  // Button
                  Container(
                    child: Text(''),
                    margin: EdgeInsets.only(
                        top: 50.0, bottom: 50.0),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                  left: 15.0, right: 15.0),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<
                                        Color>(
                                    themeColor)),
                      ),
                      color: Colors.white
                          .withOpacity(0.8),
                    )
                  : Container(),
            ),
          ],
        ));
  }

  customHandler(IconData icon) {
    return FlutterSliderHandler(
        child: Container(
      child: Container(
        child: Icon(
          icon,
          color: Colors.red,
          size: 38,
        ),
      ),
    ));
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
