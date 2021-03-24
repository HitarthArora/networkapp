import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:networkapp/status-page/pages/status_detail.dart';

class SingleItemStoryPage extends StatefulWidget {
  final id;
  final sList;
  final avatar;
  final name;
  SingleItemStoryPage(
      {this.id,
      this.sList,
      this.avatar,
      this.name});

  SingleItemStoryPageState createState() =>
      SingleItemStoryPageState(
          sList: sList,
          avatar: avatar,
          name: name,
          id: id);
}

class SingleItemStoryPageState
    extends State<SingleItemStoryPage> {
  final avatar;
  var sList;
  var data;
  final name;
  final id;

  SingleItemStoryPageState(
      {Key key,
      this.sList,
      this.avatar,
      this.name,
      this.id});

  @override
  Widget build(BuildContext context) {
    var dateTime =
        new DateTime.fromMicrosecondsSinceEpoch(
            sList[sList.length - 1]['time']
                .microsecondsSinceEpoch);
    DateFormat formatter =
        DateFormat('dd-MM-yyyy');
    var today = formatter.format(DateTime.now());
    String date = formatter.format(dateTime);
    var time = DateFormat.jm().format(dateTime);
    var dTimeLabel;
    if (today == date) {
      dTimeLabel = "Today at " + time.toString();
    } else {
      dTimeLabel =
          date.toString() + " " + time.toString();
    }

    return Container(
      margin: EdgeInsets.only(
          top: 10, right: 10, left: 10),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                      height: 65,
                      width: 65,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DetailStatusScreen(
                                      statusList:
                                          sList,
                                      avatar:
                                          avatar,
                                      isCurrentUser:
                                          false,
                                      id: id,
                                      name:
                                          name)));
                        },
                        child: Container(
                            decoration:
                                BoxDecoration(
                              border: Border.all(
                                  color: Colors
                                      .blueAccent),
                              borderRadius:
                                  BorderRadius.all(
                                      Radius.circular(
                                          45.0)),
                            ),
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
                                imageUrl: sList[
                                    sList.length -
                                        1]['url'],
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
                            )),
                      )),
                  SizedBox(
                    width: 10,
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    DetailStatusScreen(
                                        statusList:
                                            sList,
                                        avatar:
                                            avatar,
                                        isCurrentUser:
                                            false,
                                        id: id,
                                        name:
                                            name)));
                      },
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: <Widget>[
                          Text(
                            name.toString(),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w500,
                                color:
                                    Colors.black),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            dTimeLabel.toString(),
                            maxLines: 1,
                            overflow: TextOverflow
                                .ellipsis,
                            style: TextStyle(
                                color:
                                    Colors.black,
                                fontWeight:
                                    FontWeight
                                        .w400),
                          )
                        ],
                      )),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 60, right: 10),
            child: Divider(
              thickness: 1.50,
            ),
          ),
        ],
      ),
    );
  }
}
