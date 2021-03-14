import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';
import 'package:networkapp/widget/full_photo.dart';
import 'package:networkapp/widget/loading.dart';
import 'package:networkapp/voip/video/main.dart';
import 'package:networkapp/voip/audio/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class Chat extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String emailId;
  final String peerName;
  final String peerStatus;

  Chat(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      this.emailId,
      this.peerName,
      this.peerStatus})
      : super(key: key);

  @override
  State createState() => ChatS(
      peerId: peerId,
      peerAvatar: peerAvatar,
      emailId: emailId,
      peerName: peerName,
      peerStatus: peerStatus);
}

class ChatS extends State<Chat> {
  final String peerId;
  final String peerAvatar;
  final String emailId;
  final String peerName;
  String peerStatus;
  var date2;
  var diff;
  var dateTime;
  var date;
  var time;
  var lastSeenString;
  var data;
  bool isTyping = false;
  SharedPreferences prefs;

  ChatS(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      this.emailId,
      this.peerName,
      this.peerStatus});

  void initState() {
    super.initState();
    readLocal();
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
  }

  List<Choice> choices = <Choice>[
    Choice(
        title: 'Voice Call',
        icon: Icons.local_phone),
    Choice(
        title: 'Video Call',
        icon: Icons.video_call_sharp),
  ];

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Voice Call') {
      Navigator.push(
          choice.context,
          MaterialPageRoute(
              builder: (context) => VoiceCall(
                  emailId: emailId,
                  peerId: peerId)));
    } else {
      Navigator.push(
          choice.context,
          MaterialPageRoute(
              builder: (context) => VideoCall(
                  emailId: emailId,
                  peerId: peerId)));
    }
  }

  getLastSeen() async {
    final FirebaseFirestore _db =
        FirebaseFirestore.instance;
    await _db
        .collection('users')
        .doc(peerId)
        .get()
        .then((document) {
      dateTime =
          new DateTime.fromMicrosecondsSinceEpoch(
              document
                  .data()['lastSeen']['dateTime']
                  .microsecondsSinceEpoch);
      date = document.data()['lastSeen']['date'];
      time = document.data()['lastSeen']['time'];
      peerStatus = document.data()['status'];
      if (document.data()['typingStatus']
              ['typingTo'] ==
          prefs.getString('id')) {
        isTyping = document.data()['typingStatus']
                    ['isTyping'] !=
                null
            ? document.data()['typingStatus']
                ['isTyping']
            : false;
      }
    });
    date2 = DateTime.now();
    diff = date2.difference(dateTime).inDays;
    if (diff == 0) {
      lastSeenString = "today at " + time;
    } else if (diff == 1) {
      lastSeenString = "yesterday at " + time;
    } else {
      lastSeenString = "on" + date;
    }
  }

  @override
  Widget build(BuildContext context) {
    getLastSeen();
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
        titleSpacing: 0,
        title: Row(
            mainAxisAlignment:
                MainAxisAlignment.start,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: <Widget>[
              Stack(children: <Widget>[
                Material(
                  child: peerAvatar != null
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
                            width: 38.0,
                            height: 38.0,
                            padding:
                                EdgeInsets.only(
                                    left: 0.0,
                                    top: 15.0,
                                    bottom: 15.0,
                                    right: 15.0),
                          ),
                          imageUrl: peerAvatar,
                          width: 38.0,
                          height: 38.0,
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
                      color:
                          peerStatus == "online"
                              ? Colors.green
                              : Colors.black54),
                ),
              ]),
              lastSeenString != null
                  ? Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                          Text(
                            peerName != null
                                ? "   " + peerName
                                : 'CHAT',
                            style: TextStyle(
                                color:
                                    primaryColor,
                                fontWeight:
                                    FontWeight
                                        .bold),
                          ),
                          Container(
                              child: Text(
                            peerStatus == "online"
                                ? isTyping
                                    ? "      " +
                                        "typing...."
                                    : "      " +
                                        "online"
                                : lastSeenString !=
                                        null
                                    ? "      " +
                                        "last seen " +
                                        lastSeenString
                                    : "",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight:
                                  FontWeight
                                      .normal,
                              fontStyle: FontStyle
                                  .italic,
                              fontSize: 11.0,
                            ),
                          )),
                        ])
                  : Text(
                      peerName != null
                          ? "   " + peerName
                          : '   CHAT',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight:
                              FontWeight.bold),
                    ),
            ]),
        centerTitle: false,
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                choice.context = context;
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
      body: ChatScreen(
        peerId: peerId,
        peerAvatar: peerAvatar,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;

  ChatScreen(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar})
      : super(key: key);

  @override
  State createState() => ChatScreenState(
      peerId: peerId, peerAvatar: peerAvatar);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar});

  String peerId;
  String peerAvatar;
  String id;

  List<QueryDocumentSnapshot> listMessage =
      new List.from([]);
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId;
  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  var msgCount;
  bool isComposing = false;

  final TextEditingController
      textEditingController =
      TextEditingController();
  final ScrollController listScrollController =
      ScrollController();
  final FocusNode focusNode = FocusNode();

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController
                .position.maxScrollExtent &&
        !listScrollController
            .position.outOfRange) {
      print("reach the bottom");
      setState(() {
        print("reach the bottom");
        _limit += _limitIncrement;
      });
    }
    if (listScrollController.offset <=
            listScrollController
                .position.minScrollExtent &&
        !listScrollController
            .position.outOfRange) {
      print("reach the top");
      setState(() {
        print("reach the top");
      });
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    listScrollController
        .addListener(_scrollListener);

    groupChatId = '';

    isLoading = false;
    isShowSticker = false;
    imageUrl = '';

    readLocal();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }
    peerAvatar = prefs.getString('peerAvatar');

    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({'chattingWith': peerId});

    setState(() {});
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(
        source: ImageSource.gallery);
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now()
        .millisecondsSinceEpoch
        .toString();
    StorageReference reference = FirebaseStorage
        .instance
        .ref()
        .child(fileName);
    StorageUploadTask uploadTask =
        reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot =
        await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then(
        (downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
          msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = FirebaseFirestore
          .instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(DateTime.now()
              .millisecondsSinceEpoch
              .toString());

      FirebaseFirestore.instance
          .runTransaction((transaction) async {
        transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now()
                .millisecondsSinceEpoch
                .toString(),
            'content': content,
            'type': type
          },
        );
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send',
          backgroundColor: Colors.black,
          textColor: Colors.red);
    }
  }

  Widget buildItem(
      int index, DocumentSnapshot document) {
    if (document.data()['idFrom'] == id) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document.data()['type'] == 0
              // Text
              ? Container(
                  child: Text(
                    document.data()['content'],
                    style: TextStyle(
                        color: primaryColor),
                  ),
                  padding: EdgeInsets.fromLTRB(
                      15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      color: greyColor2,
                      borderRadius:
                          BorderRadius.circular(
                              8.0)),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(
                              index)
                          ? 20.0
                          : 10.0,
                      right: 10.0),
                )
              : document.data()['type'] == 1
                  // Image
                  ? Container(
                      child: FlatButton(
                        child: Material(
                          child:
                              CachedNetworkImage(
                            placeholder:
                                (context, url) =>
                                    Container(
                              child:
                                  CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<
                                            Color>(
                                        themeColor),
                              ),
                              width: 200.0,
                              height: 200.0,
                              padding:
                                  EdgeInsets.all(
                                      70.0),
                              decoration:
                                  BoxDecoration(
                                color: greyColor2,
                                borderRadius:
                                    BorderRadius
                                        .all(
                                  Radius.circular(
                                      8.0),
                                ),
                              ),
                            ),
                            errorWidget: (context,
                                    url, error) =>
                                Material(
                              child: Image.asset(
                                'images/img_not_available.jpeg',
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .all(
                                Radius.circular(
                                    8.0),
                              ),
                              clipBehavior:
                                  Clip.hardEdge,
                            ),
                            imageUrl:
                                document.data()[
                                    'content'],
                            width: 200.0,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                          borderRadius:
                              BorderRadius.all(
                                  Radius.circular(
                                      8.0)),
                          clipBehavior:
                              Clip.hardEdge,
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FullPhoto(
                                      url: document
                                              .data()[
                                          'content'])));
                        },
                        padding:
                            EdgeInsets.all(0),
                      ),
                      margin: EdgeInsets.only(
                          bottom:
                              isLastMessageRight(
                                      index)
                                  ? 20.0
                                  : 10.0,
                          right: 10.0),
                    )
                  // Sticker
                  : Container(
                      child: Image.asset(
                        'images/${document.data()['content']}.gif',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                      margin: EdgeInsets.only(
                          bottom:
                              isLastMessageRight(
                                      index)
                                  ? 20.0
                                  : 10.0,
                          right: 10.0),
                    ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Material(
                  child: CachedNetworkImage(
                    placeholder: (context, url) =>
                        Container(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor:
                            AlwaysStoppedAnimation<
                                    Color>(
                                themeColor),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding:
                          EdgeInsets.all(10.0),
                    ),
                    imageUrl: peerAvatar,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(18.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                document.data()['type'] == 0
                    ? Container(
                        child: Text(
                          document
                              .data()['content'],
                          style: TextStyle(
                              color:
                                  Colors.white),
                        ),
                        padding:
                            EdgeInsets.fromLTRB(
                                15.0,
                                10.0,
                                15.0,
                                10.0),
                        width: 200.0,
                        decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        8.0)),
                        margin: EdgeInsets.only(
                            left: 10.0),
                      )
                    : document.data()['type'] == 1
                        ? Container(
                            child: FlatButton(
                              child: Material(
                                child:
                                    CachedNetworkImage(
                                  placeholder:
                                      (context,
                                              url) =>
                                          Container(
                                    child:
                                        CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              themeColor),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding:
                                        EdgeInsets
                                            .all(
                                                70.0),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          greyColor2,
                                      borderRadius:
                                          BorderRadius
                                              .all(
                                        Radius.circular(
                                            8.0),
                                      ),
                                    ),
                                  ),
                                  errorWidget:
                                      (context,
                                              url,
                                              error) =>
                                          Material(
                                    child: Image
                                        .asset(
                                      'images/img_not_available.jpeg',
                                      width:
                                          200.0,
                                      height:
                                          200.0,
                                      fit: BoxFit
                                          .cover,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .all(
                                      Radius
                                          .circular(
                                              8.0),
                                    ),
                                    clipBehavior:
                                        Clip.hardEdge,
                                  ),
                                  imageUrl: document
                                          .data()[
                                      'content'],
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit
                                      .cover,
                                ),
                                borderRadius: BorderRadius
                                    .all(Radius
                                        .circular(
                                            8.0)),
                                clipBehavior:
                                    Clip.hardEdge,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            FullPhoto(
                                                url: document.data()['content'])));
                              },
                              padding:
                                  EdgeInsets.all(
                                      0),
                            ),
                            margin:
                                EdgeInsets.only(
                                    left: 10.0),
                          )
                        : Container(
                            child: Image.asset(
                              'images/${document.data()['content']}.gif',
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(
                                bottom:
                                    isLastMessageRight(
                                            index)
                                        ? 20.0
                                        : 10.0,
                                right: 10.0),
                          ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      DateFormat('dd MMM kk:mm')
                          .format(DateTime
                              .fromMillisecondsSinceEpoch(
                                  int.parse(document
                                          .data()[
                                      'timestamp']))),
                      style: TextStyle(
                          color: greyColor,
                          fontSize: 12.0,
                          fontStyle:
                              FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(
                        left: 50.0,
                        top: 5.0,
                        bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment:
              CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]
                    .data()['idFrom'] ==
                id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]
                    .data()['idFrom'] !=
                id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageOfPeer() {
    Fluttertoast.showToast(
        msg: listMessage[msgCount]
            .data()['idFrom']
            .toString());
    if ((msgCount > 0 &&
            listMessage != null &&
            listMessage[msgCount]
                    .data()['idFrom'] !=
                id) ||
        msgCount == 0) {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({'chattingWith': null});
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              // Sticker
              (isShowSticker
                  ? buildSticker()
                  : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi1', 2),
                child: Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi2', 2),
                child: Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi3', 2),
                child: Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi4', 2),
                child: Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi5', 2),
                child: Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi6', 2),
                child: Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi7', 2),
                child: Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi8', 2),
                child: Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () =>
                    onSendMessage('mimi9', 2),
                child: Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: greyColor2, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? const Loading()
          : Container(),
    );
  }

  typingStatusSave() async {
    var typObject = {
      "isTyping": isComposing,
      "typingTo": peerId,
    };
    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({'typingStatus': typObject});
  }

  Widget buildInput() {
    typingStatusSave();
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                onPressed: getImage,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.face),
                onPressed: getSticker,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (value) {
                  onSendMessage(
                      textEditingController.text,
                      0);
                  setState(() {
                    isComposing = false;
                  });
                },
                onChanged: (String text) {
                  setState(() {
                    isComposing = text != null
                        ? text.length > 0
                        : false;
                  });
                },
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 15.0),
                controller: textEditingController,
                decoration:
                    InputDecoration.collapsed(
                  hintText:
                      'Type your message...',
                  hintStyle:
                      TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(
                  horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => onSendMessage(
                    textEditingController.text,
                    0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: greyColor2, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(themeColor)))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp',
                      descending: true)
                  .limit(_limit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<
                                      Color>(
                                  themeColor)));
                } else {
                  listMessage.addAll(
                      snapshot.data.documents);
                  msgCount = snapshot
                      .data.documents.length;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context,
                            index) =>
                        buildItem(
                            index,
                            snapshot.data
                                    .documents[
                                index]),
                    itemCount: snapshot
                        .data.documents.length,
                    reverse: true,
                    controller:
                        listScrollController,
                  );
                }
              },
            ),
    );
  }
}

class Choice {
  Choice({this.title, this.icon});

  final String title;
  final IconData icon;
  BuildContext context;
}
