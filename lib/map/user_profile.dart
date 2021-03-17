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

class UserProfile extends StatelessWidget {
  var x;
  var data;
  UserProfile({Key key, this.x, this.data})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'USER PROFILE',
          style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SettingsScreen(x: x, data: data),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  var x;
  var data;
  SettingsScreen({Key key, this.x, this.data})
      : super(key: key);
  @override
  State createState() =>
      SettingsScreenState(x: x, data: data);
}

class SettingsScreenState
    extends State<SettingsScreen> {
  var x;
  var data;
  SettingsScreenState(
      {Key key, this.x, this.data});

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
    id = prefs.getString('id') ?? '';
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
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      (avatarImageFile == null)
                          ? (photoUrl != ''
                              ? Material(
                                  child:
                                      CachedNetworkImage(
                                    placeholder: (context,
                                            url) =>
                                        Container(
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                themeColor),
                                      ),
                                      width: 90.0,
                                      height:
                                          90.0,
                                      padding:
                                          EdgeInsets.all(
                                              20.0),
                                    ),
                                    imageUrl:
                                        photoUrl,
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
                                )
                              : Icon(
                                  Icons
                                      .account_circle,
                                  size: 90.0,
                                  color:
                                      greyColor,
                                ))
                          : Material(
                              child: Image.file(
                                avatarImageFile,
                                width: 90.0,
                                height: 90.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(
                                      Radius.circular(
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
                      'Nickname',
                      style: TextStyle(
                          fontStyle:
                              FontStyle.italic,
                          fontWeight:
                              FontWeight.bold,
                          color: primaryColor),
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
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
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
                        left: 30.0, right: 30.0),
                  ),

                  Container(
                    child: Text(
                      'Status',
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
                          hintText: 'Offline',
                          contentPadding:
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
                        ),
                        controller:
                            controllerStatus,
                        onChanged: (value) {},
                        focusNode:
                            focusNodeAboutMe,
                      ),
                    ),
                    margin: EdgeInsets.only(
                        left: 30.0, right: 30.0),
                  ),

                  // About me
                  Container(
                    child: Text(
                      'About me',
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
                          hintText:
                              'Personal description',
                          contentPadding:
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
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
                        left: 30.0, right: 30.0),
                  ),

                  // Email
                  Container(
                    child: Text(
                      'Email',
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
                          hintText:
                              'example@gmail.com',
                          contentPadding:
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
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
                        left: 30.0, right: 30.0),
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
                          hintText: '0.70km',
                          contentPadding:
                              EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                              color: greyColor),
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
                        left: 30.0, right: 30.0),
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
    );
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
