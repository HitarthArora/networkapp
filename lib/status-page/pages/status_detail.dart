import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart'
    as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart'
    as RtcRemoteView;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:networkapp/home.dart';

class DetailStatusScreen extends StatefulWidget {
  final id;
  final statusList;
  final avatar;
  final isCurrentUser;
  final name;

  DetailStatusScreen(
      {this.id,
      this.statusList,
      this.avatar,
      this.isCurrentUser,
      this.name});

  _DetailStatusScreenState createState() =>
      _DetailStatusScreenState(
          statusList: statusList,
          avatar: avatar,
          isCurrentUser: isCurrentUser,
          id: id,
          name: name);
}

class _DetailStatusScreenState
    extends State<DetailStatusScreen> {
  List<double> _width;
  int index = 0;
  int count;
  ImageProvider _image;
  Timer t;
  final avatar;
  final id;
  final isCurrentUser;
  final name;
  var imageList = new List.from([]);
  var statusList;
  var data;
  var dTimeLabel;

  _DetailStatusScreenState(
      {Key key,
      this.statusList,
      this.avatar,
      this.id,
      this.isCurrentUser,
      this.name});

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < statusList.length; i++) {
      setState(() {
        count = statusList.length;
        imageList.add(statusList[i]['url']);
        _width = new List<double>(count);
      });
    }
    for (int j = 0; j < count; j++) {
      _width[j] = 0.0;
    }
    Future.delayed(Duration(milliseconds: 100),
        () {
      _playStatus();
    });
    Future.delayed(
        Duration(
            seconds: statusList.length * 5,
            milliseconds: 100), () {
      if (!mounted) return;

      Navigator.of(context).pop();
    });
  }

  readLocal() {
    if (statusList != null) {}
  }

  _playStatus() {
    if (index < count) {
      setState(() {
        _width[index] =
            (MediaQuery.of(context).size.width -
                    4.0 -
                    (count - 1) * 4.0) /
                count;

        _image = CachedNetworkImageProvider(
            imageList[index]);

        var dateTime = new DateTime
                .fromMicrosecondsSinceEpoch(
            statusList[index]['time']
                .microsecondsSinceEpoch);
        DateFormat formatter =
            DateFormat('dd-MM-yyyy');
        var today =
            formatter.format(DateTime.now());
        String date = formatter.format(dateTime);
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

        if (isCurrentUser == false) {
          var sList = statusList, val;
          if (sList[index]['views'] != null) {
            val = sList[index]['views'] + 1;
          } else {
            val = 1;
          }
          sList[index]['views'] = val;
          FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .update({'statusList': sList});
        }
        index++;
      });

      t = Timer(Duration(seconds: 5), () {
        _playStatus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth =
        MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              GestureDetector(
                  onTap: () {
                    /*
                    t.cancel();
                    if (index ==
                        statusList.length) {
                      Navigator.of(context).pop();
                    } else {
                      _playStatus();
                    }
                    */
                  },
                  child: Center(
                    child: _image != null
                        ? Image(image: _image)
                        : Text(''),
                  )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Row(children: <Widget>[
                    Flexible(
                        child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.arrow_back,
                          size: 24.0,
                          color: Colors.white,
                        ),
                        CircleAvatar(
                          radius: 15.0,
                          backgroundImage:
                              NetworkImage(
                                  avatar),
                        ),
                      ],
                    )),
                    /*
                    Padding(
                      padding:
                          const EdgeInsets.all(
                              0.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: 24.0,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          statusList
                              .removeAt(index);
                        },
                      ),
                    )
                    */
                    /*
                      Container(
                  margin:
                      EdgeInsets.only(left: 10.0),
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: <Widget>[
                        Text(name.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            )),
                        Text(
                            dTimeLabel != null
                                ? dTimeLabel
                                    .toString()
                                : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w500,
                            ))
                      ])),
                      */
                  ]),
                ),
              ),
              Row(
                children: getImageList(),
              ),
              Row(
                children: getAnimation(),
              ),
            ],
          ),
        ));
  }

  List<Widget> getImageList() {
    List<Widget> children = new List.from([]);
    double mediaWidth =
        MediaQuery.of(context).size.width;

    for (dynamic _ in imageList) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 2.0, vertical: 4.0),
        child: Container(
          height: 2.5,
          width: (mediaWidth -
                  4.0 -
                  (statusList.length - 1) * 4.0) /
              statusList.length,
          color:
              Color.fromRGBO(255, 255, 255, 0.4),
        ),
      ));
    }
    return children;
  }

  List<Widget> getAnimation() {
    List<Widget> children = new List.from([]);
    int i = 0;
    for (dynamic _ in imageList) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 2.0, vertical: 4.0),
        child: AnimatedContainer(
          duration: Duration(seconds: 5),
          height: 2.5,
          width: _width[i],
          color: Colors.white,
        ),
      ));
      i++;
    }
    return children;
  }
}
