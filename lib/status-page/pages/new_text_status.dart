import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:networkapp/status-page/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

final _random = new Random();

// Generates a positive random integer uniformly distributed on the range
// from [min], inclusive, to [max], exclusive.
int getRandomInt(int min, int max) =>
    min + _random.nextInt(max - min);

class NewTextStatusScreen extends StatefulWidget {
  final statusList;
  final currentUserId;

  NewTextStatusScreen(
      {Key key,
      this.statusList,
      this.currentUserId})
      : super(key: key);

  @override
  _NewTextStatusScreenState createState() =>
      _NewTextStatusScreenState(
          statusList: statusList,
          currentUserId: currentUserId);
}

class _NewTextStatusScreenState
    extends State<NewTextStatusScreen> {
  Color _bgColor;
  int _bgColorIndex;
  var statusImageFile;
  var statusList;
  final currentUserId;

  _NewTextStatusScreenState({
    Key key,
    this.currentUserId,
    this.statusList,
  });

  @override
  void initState() {
    super.initState();
    _bgColorIndex = getRandomInt(2, 4) * 100;
    _bgColor = Colors.primaries[getRandomInt(
            0, Colors.primaries.length - 1)]
        [_bgColorIndex];
  }

  void _changeBgColor() {
    setState(() {
      _bgColorIndex = getRandomInt(2, 4) * 100;
      _bgColor = Colors.primaries[getRandomInt(
              0, Colors.primaries.length - 1)]
          [_bgColorIndex];
    });
  }

  String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length,
          (_) => _chars.codeUnitAt(
              _rnd.nextInt(_chars.length))));

  GlobalKey _globalKey = new GlobalKey();

  Future<Uint8List> _capturePng() async {
    try {
      print('inside');
      RenderRepaintBoundary boundary = _globalKey
          .currentContext
          .findRenderObject();
      ui.Image image =
          await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
      var pngBytes =
          byteData.buffer.asUint8List();
      var bs64 = base64Encode(pngBytes);
      print(pngBytes);
      print(bs64);
      setState(() {});
      statusImageFile = pngBytes;
      Navigator.of(context).pop();
      uploadFile();
      return pngBytes;
    } catch (e) {
      print(e);
    }
  }

  Future uploadFile() async {
    String fileName = getRandomString(30);
    StorageReference reference = FirebaseStorage
        .instance
        .ref()
        .child(fileName);
    StorageUploadTask uploadTask =
        reference.putData(statusImageFile);
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
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Flexible(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: <Widget>[
                RepaintBoundary(
                    key: _globalKey,
                    child: Container(
                      color: _bgColor,
                      constraints: BoxConstraints(
                        minWidth:
                            MediaQuery.of(context)
                                .size
                                .width,
                        maxWidth:
                            MediaQuery.of(context)
                                .size
                                .width,
                        minHeight: 100.0,
                        maxHeight: MediaQuery.of(context)
                                .size
                                .height-380,
                      ),
                      child: TextField(
                        maxLines: null,
                        textAlign:
                            TextAlign.center,
                        maxLength: 60,
                        keyboardType:
                            TextInputType
                                .multiline,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40.0,
                        ),
                        decoration:
                            InputDecoration(
                                counterText: '',
                                border:
                                    InputBorder
                                        .none,
                                hintText:
                                    'Type a status',
                                hintStyle:
                                    TextStyle(
                                  color: Color
                                      .fromRGBO(
                                          255,
                                          255,
                                          255,
                                          0.5),
                                  fontSize: 40.0,
                                )),
                      ),
                    )),
              ],
            ),
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: Row(
                  children: <Widget>[
                    IconButton(
                      color: Colors.white,
                      icon: Icon(
                          Icons.insert_emoticon),
                      onPressed: () {},
                    ),
                    RawMaterialButton(
                      onPressed: () {},
                      child: Text('T',
                          style: TextStyle(
                            fontSize: 24.0,
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          )),
                      shape: new CircleBorder(),
                      padding:
                          const EdgeInsets.all(
                              18.0),
                    ),
                    IconButton(
                      color: Colors.white,
                      icon:
                          Icon(Icons.color_lens),
                      onPressed: () {
                        _changeBgColor();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.send),
                  onPressed: () {
                    _capturePng();
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
