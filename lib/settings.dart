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

class ChatSettings extends StatelessWidget {
  var x;

  ChatSettings({Key key, this.x})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SettingsScreen(x: x),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  var x;

  SettingsScreen({Key key, this.x})
      : super(key: key);
  @override
  State createState() =>
      SettingsScreenState(x: x);
}

class SettingsScreenState
    extends State<SettingsScreen> {
  var x;

  SettingsScreenState({Key key, this.x});

  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;
  TextEditingController controllerRadius;

  SharedPreferences prefs;

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
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
    nickname = prefs.getString('nickname') ?? '';
    aboutMe = prefs.getString('aboutMe') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';
    radius = prefs.getInt('radius') ?? '';
    _currentSliderValue =
        prefs.getInt('radius').toDouble() ?? 0;
    _lowerValue =
        prefs.getInt('radius').toDouble() ?? 0;

    controllerNickname =
        TextEditingController(text: nickname);
    controllerAboutMe =
        TextEditingController(text: aboutMe);
    controllerRadius =
        new TextEditingController();

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
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: primaryColor
                              .withOpacity(0.5),
                        ),
                        onPressed: getImage,
                        padding:
                            EdgeInsets.all(30.0),
                        splashColor:
                            Colors.transparent,
                        highlightColor: greyColor,
                        iconSize: 30.0,
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

                  // Radius
                  Container(
                      child: Text(
                        'Radius',
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
                      padding: EdgeInsets.only(
                          bottom: 5.0)),
                  Container(
                    child: Theme(
                        data: Theme.of(context)
                            .copyWith(
                                primaryColor:
                                    primaryColor),
                        child: Column(children: <
                            Widget>[
                          FlutterSlider(
                            values: [_lowerValue],
                            max: 10,
                            min: 0,
                            tooltip:
                                FlutterSliderTooltip(
                              leftPrefix: Icon(
                                Icons
                                    .attach_money,
                                size: 19,
                                color: Colors
                                    .black45,
                              ),
                              rightSuffix:
                                  Text(" kms"),
                              textStyle: TextStyle(
                                  fontSize: 17,
                                  color: Colors
                                      .black45),
                            ),
                            handler: customHandler(
                                Icons
                                    .flag_rounded),
                            onDragging:
                                (handlerIndex,
                                    lowerValue,
                                    upperValue) {
                              _lowerValue =
                                  lowerValue;
                              radius = lowerValue
                                  .round()
                                  .toInt();
                              setState(() {});
                            },
                          )
                        ])),
                    margin: EdgeInsets.only(
                        left: 15.0,
                        right: 15.0,
                        top: 0.0),
                  ),
                ],
                crossAxisAlignment:
                    CrossAxisAlignment.start,
              ),

              // Button
              Container(
                child: FlatButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    'UPDATE',
                    style:
                        TextStyle(fontSize: 16.0),
                  ),
                  color: primaryColor,
                  highlightColor:
                      Color(0xff8d93a0),
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                      30.0, 10.0, 30.0, 10.0),
                ),
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
                margin: EdgeInsets.only(top:10),
                child: Container(
                  child: Icon(
                    icon,
                    color: Colors.red,
                    size: 38,
                  ),
                ),
              )
            ]));
  }
}

/*
SliderTheme(
data: SliderTheme.of(
        context)
    .copyWith(
  activeTrackColor:
      Colors.red[700],
  inactiveTrackColor:
      Colors.red[100],
  trackShape:
      RoundedRectSliderTrackShape(),
  trackHeight: 4.0,
  thumbShape:
      RoundSliderThumbShape(
          enabledThumbRadius:
              12.0),
  thumbColor:
      Colors.redAccent,
  overlayColor: Colors
      .red
      .withAlpha(32),
  overlayShape:
      RoundSliderOverlayShape(
          overlayRadius:
              28.0),
  tickMarkShape:
      RoundSliderTickMarkShape(),
  activeTickMarkColor:
      Colors.red[700],
  inactiveTickMarkColor:
      Colors.red[100],
  valueIndicatorShape:
      PaddleSliderValueIndicatorShape(),
  valueIndicatorColor:
      Colors.redAccent,
  valueIndicatorTextStyle:
      TextStyle(
    color: Colors.white,
  ),
),
child: Slider(
  value:
      _currentSliderValue,
  min: 0,
  max: 10,
  divisions: 5,
  label: _currentSliderValue
          .round()
          .toString() +
      " kms",
  onChanged:
      (double value) {
    setState(() {
      _currentSliderValue =
          value;
    });
    radius = value
        .round()
        .toInt();
  },
)),
*/

/*
SliderTheme(
data: SliderTheme.of(
        context)
    .copyWith(
  activeTrackColor:
      Colors.red[700],
  inactiveTrackColor:
      Colors.red[100],
  trackShape:
      RectangularSliderTrackShape(),
  trackHeight: 4.0,
  thumbColor: Colors
      .redAccent,
  thumbShape:
      RoundSliderThumbShape(
          enabledThumbRadius:
              12.0),
  overlayColor: Colors
      .red
      .withAlpha(32),
  overlayShape:
      RoundSliderOverlayShape(
          overlayRadius:
              28.0),
),
child: Slider(
  value:
      _currentSliderValue,
  min: 0,
  max: 10,
  divisions: 5,
  label: _currentSliderValue
          .round()
          .toString() +
      "kms",
  onChanged:
      (double value) {
    setState(() {
      _currentSliderValue =
          value;
    });
    radius = value
        .round()
        .toInt();
  },
))
*/

/*
FlutterSlider(
  values: [_lowerValue],
  max: 200,
  min: 50,
  maximumDistance: 300,
  step: FlutterSliderStep(step: 100),
  jump: true,
  trackBar:
      FlutterSliderTrackBar(
    inactiveTrackBarHeight:
        2,
    activeTrackBarHeight: 3,
  ),

  disabled: false,

  handler: customHandler(
      Icons.chevron_right),
  rightHandler:
      customHandler(Icons
          .chevron_left),
  tooltip:
      FlutterSliderTooltip(
    leftPrefix: Icon(
      Icons.attach_money,
      size: 19,
      color: Colors.black45,
    ),
    rightSuffix:
        Text(" kms"),
    textStyle: TextStyle(
        fontSize: 17,
        color:
            Colors.black45),
  ),
  fixedValues: [
    FlutterSliderFixedValue(
        percent: 0,
        value: 0.0),
    FlutterSliderFixedValue(
        percent: 10,
        value: 1.0),
    FlutterSliderFixedValue(
        percent: 20,
        value: 2.0),
    FlutterSliderFixedValue(
        percent: 30,
        value: 3.0),
    FlutterSliderFixedValue(
        percent: 40,
        value: 4.0),
    FlutterSliderFixedValue(
        percent: 50,
        value: 5.0),
    FlutterSliderFixedValue(
        percent: 60,
        value: 6.0),
    FlutterSliderFixedValue(
        percent: 70,
        value: 7.0),
    FlutterSliderFixedValue(
        percent: 80,
        value: 8.0),
    FlutterSliderFixedValue(
        percent: 90,
        value: 9.0),
    FlutterSliderFixedValue(
        percent: 100,
        value: 10.0),
  ],
  onDragging: (handlerIndex,
      lowerValue,
      upperValue) {
    _lowerValue =
        lowerValue;
    radius = lowerValue.round()
              .toInt();
    setState(() {});
  },
)
*/
