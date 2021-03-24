import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:networkapp/status-page/pages/singe_item_story_page.dart';
import 'package:networkapp/status-page/pages/status_detail.dart';
import 'package:networkapp/status-page/pages/new_text_status.dart';
import 'package:networkapp/status-page/pages/my_status.dart';
import 'package:networkapp/status-page/style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class StatusPage extends StatefulWidget {
  final String currentUserId;
  final position;
  final radius;
  final email;
  final avatar;
  final statusList;
  final dTimeLabel;

  StatusPage(
      {Key key,
      this.currentUserId,
      this.position,
      this.radius,
      this.email,
      this.avatar,
      this.statusList,
      this.dTimeLabel})
      : super(key: key);

  @override
  State createState() => StatusPageState(
      currentUserId: currentUserId,
      position: position,
      radius: radius,
      email: email,
      avatar: avatar,
      statusList: statusList,
      dTimeLabel: dTimeLabel);
}

class StatusPageState extends State<StatusPage> {
  final String currentUserId;
  final position;
  final radius;
  final email;
  final avatar;
  var data;
  var statusList;
  var dTimeLabel;
  File statusImageFile;

  StatusPageState(
      {Key key,
      this.currentUserId,
      this.position,
      this.radius,
      this.email,
      this.avatar,
      this.statusList,
      this.dTimeLabel});

  @override
  void initState() {
    super.initState();
    if (statusList == null) {
      statusList = new List.from([]);
    }
    readLocal();
  }

  readLocal() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get()
        .then((document) {
      statusList = document.data()['statusList'];
      if (statusList == null) {
        statusList = new List.from([]);
      }
      if (document.data()['statusList'] != null) {
        if (document
                .data()['statusList']
                .length !=
            0) {
          var dateTime = new DateTime
                  .fromMicrosecondsSinceEpoch(
              statusList[statusList.length - 1]
                      ['time']
                  .microsecondsSinceEpoch);
          DateFormat formatter =
              DateFormat('dd-MM-yyyy');
          var today =
              formatter.format(DateTime.now());
          String date =
              formatter.format(dateTime);
          var time =
              DateFormat.jm().format(dateTime);

          if (today == date) {
            dTimeLabel =
                "Today at " + time.toString();
          } else {
            dTimeLabel = date.toString() +
                " " +
                time.toString();
          }
        }
      }
    });
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(
        source: ImageSource.gallery);

    File image = File(pickedFile.path);

    if (image != null) {
      setState(() {
        statusImageFile = image;
      });
    }
    uploadFile();
  }

  Future getVideo() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getVideo(
        source: ImageSource.gallery);

    File image = File(pickedFile.path);

    if (image != null) {
      setState(() {
        statusImageFile = image;
      });
    }
    uploadFile();
  }

  String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length,
          (_) => _chars.codeUnitAt(
              _rnd.nextInt(_chars.length))));

  Future uploadFile() async {
    String fileName = getRandomString(30);
    StorageReference reference = FirebaseStorage
        .instance
        .ref()
        .child(fileName);
    StorageUploadTask uploadTask =
        reference.putFile(statusImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref
            .getDownloadURL()
            .then((downloadUrl) {
          var statusObj = {
            'url': downloadUrl,
            'time': DateTime.now()
          };
          statusList.add(statusObj);
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .update({
            'statusList': statusList
          }).then((data) async {
            Fluttertoast.showToast(
                msg: "Upload success");
          }).catchError((err) {
            Fluttertoast.showToast(
                msg: err.toString());
          });
        }, onError: (err) {
          Fluttertoast.showToast(
              msg: 'This file is not an image');
        });
      } else {
        Fluttertoast.showToast(
            msg: 'This file is not an image');
      }
    }, onError: (err) {
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    readLocal();

    new Future<String>.delayed(
            new Duration(seconds: 2),
            () => '["123", "456", "789"]')
        .then((String value) {
      setState(() {
        data = json.decode(value);
      });
    });

    return Scaffold(
        appBar: AppBar(
            title: Text(
              'STATUS PAGE',
              style: TextStyle(
                  color: Color(0xff203152),
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true),
        body: Scaffold(
          body: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context)
                  .size
                  .width,
              maxWidth: MediaQuery.of(context)
                  .size
                  .width,
              minHeight: MediaQuery.of(context)
                  .size
                  .height,
            ),
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      _storyWidget(),
                      SizedBox(
                        height: 8,
                      ),
                      _recentTextWidget(),
                      SizedBox(
                        height: 8,
                      ),
                      _listStories(),
                    ],
                  ),
                ),
                _customFloatingActionButton(),
              ],
            ),
          ),
        ));
  }

  Widget _customFloatingActionButton() {
    return Positioned(
      right: 10,
      bottom: 15,
      child: Column(
        children: <Widget>[
          TextButton(
              onPressed: () async {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            NewTextStatusScreen(
                              currentUserId:
                                  currentUserId,
                              statusList:
                                  statusList,
                            )));
              },
              child: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.all(
                      Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(0, 4.0),
                        blurRadius: 0.50,
                        color: Colors.black
                            .withOpacity(.2),
                        spreadRadius: 0.10)
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.blueGrey,
                ),
              )),
          SizedBox(
            height: 8.0,
          ),
          TextButton(
              onPressed: () async {
                getImage();
              },
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.all(
                      Radius.circular(50)),
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(0, 4.0),
                        blurRadius: 0.50,
                        color: Colors.black
                            .withOpacity(.2),
                        spreadRadius: 0.10)
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                ),
              )),
          SizedBox(
            height: 8.0,
          ),
          TextButton(
              onPressed: () async {
                getVideo();
              },
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.all(
                      Radius.circular(50)),
                  boxShadow: [
                    BoxShadow(
                        offset: Offset(0, 4.0),
                        blurRadius: 0.50,
                        color: Colors.black
                            .withOpacity(.2),
                        spreadRadius: 0.10)
                  ],
                ),
                child: Icon(
                  Icons.video_call,
                  color: Colors.white,
                ),
              )),
        ],
      ),
    );
  }

  Widget _storyWidget() {
    return statusList.length != 0
        ? Container(
            margin: EdgeInsets.only(
                left: 10, right: 10, top: 4),
            child: Row(
              children: <Widget>[
                Container(
                    height: 65,
                    width: 65,
                    child: TextButton(
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DetailStatusScreen(
                                        statusList:
                                            statusList,
                                        avatar:
                                            avatar,
                                        isCurrentUser:
                                            true,
                                        name:
                                            "My Status")));
                      },
                      child: Stack(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets
                                    .all(0.0),
                            child: Container(
                                decoration:
                                    BoxDecoration(
                                  border: Border.all(
                                      color: Colors
                                          .blueAccent),
                                  borderRadius: BorderRadius
                                      .all(Radius
                                          .circular(
                                              45.0)),
                                ),
                                child: Material(
                                  shadowColor:
                                      Colors
                                          .black,
                                  child:
                                      CachedNetworkImage(
                                    placeholder: (context,
                                            url) =>
                                        Container(
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            1.0,
                                        valueColor: AlwaysStoppedAnimation<
                                                Color>(
                                            Color(
                                                0xfff5a623)),
                                      ),
                                      width: 90.0,
                                      height:
                                          90.0,
                                      padding:
                                          EdgeInsets.all(
                                              0.0),
                                    ),
                                    imageUrl: statusList[
                                        statusList
                                                .length -
                                            1]['url'],
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
                                )),
                          ),
                        ],
                      ),
                    )),
                SizedBox(
                  width: 12,
                ),
                TextButton(
                    onPressed: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MyStatusPage(
                                    currentUserId:
                                        currentUserId,
                                    statusList:
                                        statusList,
                                    avatar:
                                        avatar,
                                  )));
                    },
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: <Widget>[
                        Text(
                          "My Status",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                            dTimeLabel.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w400,
                              color: Colors.black,
                            )),
                      ],
                    )),
              ],
            ),
          )
        : Container(
            margin: EdgeInsets.only(
                left: 10, right: 10, top: 4),
            child: Row(
              children: <Widget>[
                Container(
                    height: 65,
                    width: 65,
                    child: TextButton(
                      onPressed: () async {
                        getImage();
                      },
                      child: Stack(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets
                                    .all(2.0),
                            child: Material(
                              child:
                                  CachedNetworkImage(
                                placeholder:
                                    (context,
                                            url) =>
                                        Container(
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        1.0,
                                    valueColor: AlwaysStoppedAnimation<
                                            Color>(
                                        Color(
                                            0xfff5a623)),
                                  ),
                                  width: 90.0,
                                  height: 90.0,
                                  padding:
                                      EdgeInsets
                                          .all(
                                              15.0),
                                ),
                                imageUrl: avatar,
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
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  color:
                                      primaryColor,
                                  borderRadius: BorderRadius
                                      .all(Radius
                                          .circular(
                                              20))),
                              child: Icon(
                                Icons.add,
                                color:
                                    Colors.white,
                                size: 15,
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
                SizedBox(
                  width: 12,
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "My Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      "Tap to add status update",
                    ),
                  ],
                )
              ],
            ),
          );
  }

  Widget _recentTextWidget() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: Colors.grey[200]),
      child: Text("Recent updates"),
    );
  }

  Widget _listStories() {
    GeoFirePoint center = Geoflutterfire()
        .point(latitude: 34.0, longitude: 34.0);

    var collectionReference = FirebaseFirestore
        .instance
        .collection('users');

    String field = 'position';

    return StreamBuilder(
      stream: Geoflutterfire()
          .collection(
              collectionRef: collectionReference)
          .within(
              center: center,
              radius: 100000000.0,
              field: field),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<
                              Color>(
                          Color(0xfff5a623))));
        } else {
          return ListView.builder(
            itemCount: snapshot.data.length,
            shrinkWrap: true,
            physics: ScrollPhysics(),
            itemBuilder: (BuildContext context,
                int index) {
              var sList = snapshot.data[index]
                  .data()['statusList'];

              if (sList != null) {
                if (sList.length != 0 &&
                    snapshot.data[index]
                            .data()['id'] !=
                        currentUserId) {
                  var avatar = snapshot
                      .data[index]
                      .data()['photoUrl'];
                  var name = snapshot.data[index]
                      .data()['nickname'];
                  var id = snapshot.data[index]
                      .data()['id'];
                  return SingleItemStoryPage(
                      sList: sList,
                      avatar: avatar,
                      name: name,
                      id: id);
                } else {
                  return Container();
                }
              } else {
                return Container();
              }
            },
          );
        }
      },
    );
  }
}
