import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:networkapp/status-page/pages/singe_item_story_page.dart';
import 'package:networkapp/status-page/style.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StatusPage extends StatefulWidget {
  final String currentUserId;
  final position;
  final radius;
  final email;
  final avatar;

  StatusPage(
      {Key key,
      this.currentUserId,
      this.position,
      this.radius,
      this.email,
      this.avatar})
      : super(key: key);

  @override
  State createState() => StatusPageState(
      currentUserId: currentUserId,
      position: position,
      radius: radius,
      email: email,
      avatar: avatar);
}

class StatusPageState extends State<StatusPage> {
  final String currentUserId;
  final position;
  final radius;
  final email;
  final avatar;
  StatusPageState(
      {Key key,
      this.currentUserId,
      this.position,
      this.radius,
      this.email,
      this.avatar});

  @override
  Widget build(BuildContext context) {
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
        body: Stack(
          children: <Widget>[
            _customFloatingActionButton(),
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
            )
          ],
        ),
      ),
    );
  }

  Widget _customFloatingActionButton() {
    return Positioned(
      right: 10,
      bottom: 15,
      child: Column(
        children: <Widget>[
          Container(
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
          ),
          SizedBox(
            height: 8.0,
          ),
          Container(
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
          ),
        ],
      ),
    );
  }

  Widget _storyWidget() {
    return Container(
      margin: EdgeInsets.only(
          left: 10, right: 10, top: 4),
      child: Row(
        children: <Widget>[
          Container(
            height: 55,
            width: 55,
            child: Stack(
              children: <Widget>[
                Padding(
                  padding:
                      const EdgeInsets.all(2.0),
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder:
                          (context, url) =>
                              Container(
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor:
                              AlwaysStoppedAnimation<
                                      Color>(
                                  Color(
                                      0xfff5a623)),
                        ),
                        width: 80.0,
                        height: 80.0,
                        padding:
                            EdgeInsets.all(15.0),
                      ),
                      imageUrl: avatar,
                      width: 80.0,
                      height: 80.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius:
                        BorderRadius.all(
                            Radius.circular(
                                40.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius:
                            BorderRadius.all(
                                Radius.circular(
                                    20))),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                )
              ],
            ),
          ),
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
                  fontWeight: FontWeight.w500,
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
    return ListView.builder(
      itemCount: 10,
      shrinkWrap: true,
      physics: ScrollPhysics(),
      itemBuilder:
          (BuildContext context, int index) {
        return SingleItemStoryPage();
      },
    );
  }
}
