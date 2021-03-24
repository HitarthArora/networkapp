import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:networkapp/status-page/pages/status_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class MyStatusPage extends StatefulWidget {
  final int id;
  final avatar;
  final name;
  final statusList;
  final currentUserId;

  MyStatusPage(
      {this.id,
      this.avatar,
      this.name,
      this.statusList,
      this.currentUserId});

  @override
  State createState() => MyStatusPageState(
      avatar: avatar,
      name: name,
      statusList: statusList,
      currentUserId: currentUserId);
}

class MyStatusPageState
    extends State<MyStatusPage> {
  final avatar;
  final currentUserId;
  final name;
  var data;
  var statusList;
  var dTimeLabel;

  MyStatusPageState(
      {Key key,
      this.avatar,
      this.name,
      this.statusList,
      this.currentUserId});

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

    return Scaffold(
        appBar: AppBar(
            title: Text(
              'My Status',
              style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold),
            ),
            centerTitle: true),
        body: Container(
            margin: EdgeInsets.only(top: 10.0),
            child: ListView.builder(
              itemCount: statusList.length,
              shrinkWrap: true,
              physics: ScrollPhysics(),
              itemBuilder: (BuildContext context,
                  int index) {
                return buildItem(context,
                    statusList[index], index);
              },
            )));
  }

  Widget buildItem(
      BuildContext context, var item, var index) {
    var dateTime =
        new DateTime.fromMicrosecondsSinceEpoch(
            item['time'].microsecondsSinceEpoch);
    DateFormat formatter =
        DateFormat('dd-MM-yyyy');
    var today = formatter.format(DateTime.now());
    String date = formatter.format(dateTime);
    var time = DateFormat.jm().format(dateTime);

    if (today == date) {
      dTimeLabel = "Today at " + time.toString();
    } else {
      dTimeLabel =
          date.toString() + " " + time.toString();
    }

    return Container(
      child: FlatButton(
        child: Row(
          children: <Widget>[
            Material(
              child: item['url'] != null
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
                            EdgeInsets.all(15.0),
                      ),
                      imageUrl: item['url'],
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
            Flexible(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Text(
                        item['views'] != null
                            ? item['views'] == 1
                                ? '1 view'
                                : item['views']
                                        .toString() +
                                    ' views'
                            : '0 views',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      alignment:
                          Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(
                          10.0, 0.0, 0.0, 5.0),
                    ),
                    Container(
                      child: Text(
                        dTimeLabel.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      alignment:
                          Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(
                          10.0, 0.0, 0.0, 0.0),
                    )
                  ],
                ),
                margin:
                    EdgeInsets.only(left: 20.0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  statusList.removeAt(index);
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .update({
                    'statusList': statusList
                  });
                },
              ),
            )
          ],
        ),
        onPressed: () {
          var sL = new List.from([]);
          sL.add(item);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DetailStatusScreen(
                        statusList: sL,
                        avatar: avatar,
                      )));
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
