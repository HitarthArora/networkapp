import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

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
import 'package:networkapp/widget/message_reply/message_reply_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:networkapp/map/user_profile.dart';
import 'package:geolocator/geolocator.dart';
import 'package:clipboard/clipboard.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:bubble/issue_clipper.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_10.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_2.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_3.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_6.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_7.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_8.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_9.dart';

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
  Position position;
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
    position = await Geolocator()
        .getCurrentPosition(
            desiredAccuracy:
                LocationAccuracy.high);
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
                  peerId: peerId,
                  peerAvatar: peerAvatar)));
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
      if (document.data()['lastSeen'] != null) {
        dateTime = new DateTime
                .fromMicrosecondsSinceEpoch(
            document
                .data()['lastSeen']['dateTime']
                .microsecondsSinceEpoch);
        date =
            document.data()['lastSeen']['date'];
        time =
            document.data()['lastSeen']['time'];
        peerStatus = document.data()['status'];
        if (document.data()['typingStatus']
                ['typingTo'] ==
            prefs.getString('id')) {
          isTyping = document
                          .data()['typingStatus']
                      ['isTyping'] !=
                  null
              ? document.data()['typingStatus']
                  ['isTyping']
              : false;
        }
      }
    });
    if (dateTime != null) {
      date2 = DateTime.now();
      diff = date2.difference(dateTime).inDays;
      if (diff == 0) {
        lastSeenString = "today at " + time;
      } else if (diff == 1) {
        lastSeenString = "yesterday at " + time;
      } else {
        lastSeenString = "on " + date;
      }
    }
  }

  double calculateDistance(
      lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) *
            c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  gotoUserProfileScreen() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(peerId)
        .get()
        .then((document) {
      double dis = calculateDistance(
          document
              .data()['position']['geopoint']
              .latitude,
          document
              .data()['position']['geopoint']
              .longitude,
          position.latitude,
          position.longitude);
      dis =
          double.parse((dis).toStringAsFixed(3));
      Map<String, dynamic> finalData = {
        'latitude': document
            .data()['position']['geopoint']
            .latitude,
        'longitude': document
            .data()['position']['geopoint']
            .longitude,
        'name': document.data()['nickname'],
        'photoUrl': document.data()['photoUrl'],
        'email': document.data()['email'],
        'aboutMe': document.data()['aboutMe'],
        'status': document.data()['status'],
        'distance': dis,
        'id': document.data()['id']
      };
      FocusScope.of(context).unfocus();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => UserProfile(
                  data: finalData,
                  currentUserId:
                      prefs.getString('id'))));
    });
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
        title: TextButton(
            onPressed: () async {
              gotoUserProfileScreen();
            },
            child: Row(
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
                                  (context,
                                          url) =>
                                      Container(
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      1.0,
                                  valueColor:
                                      AlwaysStoppedAnimation<
                                              Color>(
                                          themeColor),
                                ),
                                width: 38.0,
                                height: 38.0,
                                padding: EdgeInsets
                                    .only(
                                        left: 0.0,
                                        top: 15.0,
                                        bottom:
                                            15.0,
                                        right:
                                            15.0),
                              ),
                              imageUrl:
                                  peerAvatar,
                              width: 38.0,
                              height: 38.0,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons
                                  .account_circle,
                              size: 50.0,
                              color: greyColor,
                            ),
                      borderRadius:
                          BorderRadius.all(
                              Radius.circular(
                                  25.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    new Positioned(
                      right: 0.0,
                      bottom: 0.0,
                      child: new Icon(
                          Icons.circle,
                          size: 14,
                          color: peerStatus ==
                                  "online"
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
                                    ? "   " +
                                        peerName
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
                                peerStatus ==
                                        "online"
                                    ? isTyping
                                        ? "    " +
                                            "typing...."
                                        : "    " +
                                            "online"
                                    : lastSeenString !=
                                            null
                                        ? "    " +
                                            "last seen " +
                                            lastSeenString
                                        : "",
                                style: TextStyle(
                                  color:
                                      primaryColor,
                                  fontWeight:
                                      FontWeight
                                          .normal,
                                  fontStyle:
                                      FontStyle
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
                                  FontWeight
                                      .bold),
                        ),
                ])),
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
        peerName: peerName,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerName;

  ChatScreen(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      this.peerName})
      : super(key: key);

  @override
  State createState() => ChatScreenState(
      peerId: peerId,
      peerAvatar: peerAvatar,
      peerName: peerName);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      this.peerName});

  String peerId;
  String peerAvatar;
  String id;
  String peerName;

  List<QueryDocumentSnapshot> listMessage =
      new List.from([]);
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId;
  SharedPreferences prefs;
  Position position;
  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;
  var msgCount;
  bool isComposing = false;
  bool isReplying = false;
  var replyMsg;
  var replyingTo;
  var replyingToId;
  bool isSent = false;
  bool isRead = false;
  var _tapPosition;

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

    position = await Geolocator()
        .getCurrentPosition(
            desiredAccuracy:
                LocationAccuracy.high);

    setState(() {});
  }

  void cancelReply() {
    setState(() {
      isReplying = false;
    });
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

  void onSendMessage(
      String content, int type) async {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      DateTime now = DateTime.now();
      DateFormat formatter =
          DateFormat('dd-MM-yyyy');
      String dateToday = formatter.format(now);
      String dateLastMsg = '';

      if (listMessage.length != 0) {
        DateTime dTimeLastMsg = new DateTime
                .fromMillisecondsSinceEpoch(
            int.parse(listMessage[0]
                .data()['timestamp']));
        dateLastMsg =
            formatter.format(dTimeLastMsg);
      }

      var documentReference = FirebaseFirestore
          .instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(now.millisecondsSinceEpoch
              .toString());

      if (dateLastMsg != dateToday ||
          msgCount == null) {
        await FirebaseFirestore.instance
            .runTransaction((transaction) async {
          transaction.set(
            documentReference,
            {
              'idFrom': id,
              'idTo': peerId,
              'timestamp': now
                  .millisecondsSinceEpoch
                  .toString(),
              'content': dateToday,
              'type': 10
            },
          );
        });
      }

      DateTime noww = DateTime.now();

      documentReference = FirebaseFirestore
          .instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(noww.millisecondsSinceEpoch
              .toString());

      if (isReplying == true) {
        FirebaseFirestore.instance
            .runTransaction((transaction) async {
          transaction.set(
            documentReference,
            {
              'idFrom': id,
              'idTo': peerId,
              'timestamp': noww
                  .millisecondsSinceEpoch
                  .toString(),
              'content': content,
              'type': type,
              'isReplyingMsg': true,
              'replyingTo': replyingTo,
              'replyingToId': replyingToId,
              'replyMsg': replyMsg,
            },
          );
        });
      } else {
        FirebaseFirestore.instance
            .runTransaction((transaction) async {
          transaction.set(
            documentReference,
            {
              'idFrom': id,
              'idTo': peerId,
              'timestamp': noww
                  .millisecondsSinceEpoch
                  .toString(),
              'content': content,
              'type': type
            },
          );
        });
      }
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut);

      sendNotification(
          peerId,
          content,
          noww.millisecondsSinceEpoch.toString(),
          groupChatId);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send',
          backgroundColor: Colors.black,
          textColor: Colors.red);
    }
  }

  static Future<String> getToken(userId) async {
    final FirebaseFirestore _db =
        FirebaseFirestore.instance;
    var token;
    await _db
        .collection('users')
        .doc(userId)
        .get()
        .then((document) {
      token = document.data()['pushToken'];
    });
    return token;
  }

  Future<void> sendNotification(
      receiver, msg, docId, groupChatId) async {
    var token = await getToken(receiver);
    print('receiver id: $peerId');
    print('token : $token');

    final data = jsonEncode({
      "notification": {
        "body": msg,
        "title": prefs.getString('nickname'),
      },
      "priority": "high",
      "data": {
        "click_action":
            "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done",
        "body": msg,
        "title": prefs.getString('nickname'),
        "timeout": null,
        "type": "messaging",
        "peerAvatar": prefs.getString('photoUrl'),
        "name": prefs.getString('nickname'),
        "docId": docId,
        "groupChatId": groupChatId,
      },
      "to": "$token",
      "apns": {
        "payload": {
          "aps": {"sound": "default"}
        }
      },
    });

    try {
      await http.post(
        Uri.parse(
            "https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'content-type': 'application/json',
          'Authorization':
              'key=AAAABKJiMQo:APA91bGkKzaM07yF2FTfTIrKALQajayZuutRguc1gxvkWZDd19p-xI0VYt9G0lQR3maypMb9Nt_1t4VmtKTKZ66ISl-ZHmvOd2CrtjfzvEeMNg_Mk9XqbRT5ECZbiiBULQuYuAKCM8z0'
        },
        body: data,
      );
      print('FCM request for device sent!');
    } catch (e) {
      print('error: $e');
    }
  }

  double calculateDistance(
      lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) *
            c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  gotoUserProfileScreen() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(peerId)
        .get()
        .then((document) {
      double dis = calculateDistance(
          document
              .data()['position']['geopoint']
              .latitude,
          document
              .data()['position']['geopoint']
              .longitude,
          position.latitude,
          position.longitude);
      dis =
          double.parse((dis).toStringAsFixed(3));
      Map<String, dynamic> finalData = {
        'latitude': document
            .data()['position']['geopoint']
            .latitude,
        'longitude': document
            .data()['position']['geopoint']
            .longitude,
        'name': document.data()['nickname'],
        'photoUrl': document.data()['photoUrl'],
        'email': document.data()['email'],
        'aboutMe': document.data()['aboutMe'],
        'status': document.data()['status'],
        'distance': dis,
        'id': document.data()['id']
      };
      FocusScope.of(context).unfocus();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => UserProfile(
                  data: finalData,
                  currentUserId:
                      prefs.getString('id'))));
    });
  }

  getSenderView(CustomClipper clipper,
      BuildContext context, String bubbleText) {
    /*
    return ChatBubble(
      clipper: clipper,
      alignment: Alignment.topCenter,
      margin: EdgeInsets.only(top: 3, bottom: 8),
      backGroundColor: Colors.blue,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
                  0.7,
        ),
        child: Text(
          bubbleText,
          style: TextStyle(
              color: Colors.white, fontSize: 10),
        ),
      ),
    );
    */
    return Container(
        child: Bubble(
          alignment: Alignment.center,
          color:
              Color.fromRGBO(212, 234, 244, 1.0),
          child: Text(bubbleText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.0)),
        ),
        margin:
            EdgeInsets.only(top: 12, bottom: 12));
  }

  String datePrevMsg = '';
  String contentPrevMsg = '';

  void _onSwipe(var idFrom, var message) {
    setState(() {
      print('Swiped!');
      isReplying = true;
      replyMsg = message;
      if (idFrom == prefs.getString('id')) {
        replyingTo = prefs.getString('nickname');
        replyingToId = prefs.getString('id');
      } else {
        replyingTo = peerName;
        replyingToId = peerId;
      }
    });
  }

  void _onTap(var idFrom, var message) {
    setState(() {
      print('Tapped!');
      isReplying = true;
      replyMsg = message;
      if (idFrom == prefs.getString('id')) {
        replyingTo = prefs.getString('nickname');
        replyingToId = prefs.getString('id');
      } else {
        replyingTo = peerName;
        replyingToId = peerId;
      }
    });
  }

  var messageToBubbleMap = {};

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Widget buildItem(
      int index, DocumentSnapshot document) {
    var bubbleText = '';

    /*
    DateTime dTimeMsg = new DateTime
            .fromMillisecondsSinceEpoch(
        int.parse(document.data()['timestamp']));
    String dateMsg = formatter.format(dTimeMsg);

    if (index > 0) {
      if (datePrevMsg != dateMsg) {
        showBubble = true;
        if (datePrevMsg == dateToday) {
          bubbleText = 'Today';
        } else {
          bubbleText = datePrevMsg;
        }
      }
    }
    //bubbleText = contentPrevMsg;
    //showBubble = true;

    DateTime dTimePrevMsg = new DateTime
            .fromMillisecondsSinceEpoch(
        int.parse(document.data()['timestamp']));
    datePrevMsg = formatter.format(dTimePrevMsg);
    contentPrevMsg = document.data()['content'];
    */

    if (document.data()['type'] == 10) {
      DateFormat formatter =
          DateFormat('dd-MM-yyyy');

      DateTime now = DateTime.now();
      String dateToday = formatter.format(now);

      if (dateToday ==
          document.data()['content']) {
        bubbleText = 'TODAY';
      } else {
        bubbleText = document.data()['content'];
      }

      return getSenderView(
          ChatBubbleClipper4(
              type: BubbleType.sendBubble),
          context,
          bubbleText);
    }

    var messag = {
      'message': document.data()['replyMsg'],
      'username': document.data()['replyingTo'],
    };

    var dtTime = new DateTime
            .fromMillisecondsSinceEpoch(
        int.parse(document.data()['timestamp']));
    var msggTime = DateFormat.jm().format(dtTime);

    if (listMessage[index + 1] != null) {
      if (listMessage[index + 1].data()['type'] ==
          10) {
        messageToBubbleMap[document
                .data()['timestamp']
                .toString()] =
            listMessage[index + 1]
                .data()['timestamp']
                .toString();
      }
    }

    if (document.data()['idFrom'] == id) {
      // Right (my message)
      if (document.data()['deleteForId-' +
              prefs.getString('id')] !=
          null) {
        return Container();
      } else if (document
              .data()['deleteForAll'] !=
          null) {
        return GestureDetector(
            onTapDown: _storePosition,
            onLongPress: () {
              final RenderBox overlay =
                  Overlay.of(context)
                      .context
                      .findRenderObject();
              showMenu(
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                        value: 0,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context);
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                title: Text(
                                    'Delete message?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed:
                                        () {
                                      Navigator.pop(
                                          context);
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                              'messages')
                                          .doc(
                                              groupChatId)
                                          .collection(
                                              groupChatId)
                                          .doc(document
                                              .data()['timestamp']
                                              .toString())
                                          .update({
                                        'deleteForId-' +
                                                prefs.getString('id'):
                                            true,
                                      });
                                    },
                                    child: const Text(
                                        'DELETE FOR ME'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () async {
                                      Navigator.pop(
                                          context);
                                    },
                                    child: const Text(
                                        'CANCEL'),
                                  )
                                ],
                              ),
                            );
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete,
                                  color: Colors
                                      .black),
                              Text("Delete",
                                  style: TextStyle(
                                      color: Colors
                                          .black)),
                            ],
                          ),
                        )),
                  ],
                  context: context,
                  position: RelativeRect.fromRect(
                      _tapPosition &
                          const Size(40,
                              40), // smaller rect, the touch area
                      Offset.zero &
                          overlay
                              .size // Bigger rect, the entire screen
                      ));
            },
            child: ChatBubble(
                clipper: ChatBubbleClipper1(
                    type: BubbleType.sendBubble,
                    radius: 5.0),
                alignment: Alignment.topRight,
                margin: EdgeInsets.only(top: 12),
                backGroundColor:
                    HexColor.fromHex('#DCF8C6'),
                child: Container(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      mainAxisAlignment:
                          MainAxisAlignment.start,
                      children: [
                        Row(children: <Widget>[
                          Icon(
                              Icons
                                  .do_disturb_outlined,
                              color: Colors
                                  .grey.shade600,
                              size: 15),
                          Text(
                              ' You deleted this message',
                              style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontStyle:
                                      FontStyle
                                          .italic))
                        ]),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .end,
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .end,
                          mainAxisSize:
                              MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              margin:
                                  EdgeInsets.only(
                                      right: 0.0),
                              width: 200.0,
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .end,
                                children: <
                                    Widget>[
                                  Text(
                                    msggTime
                                        .toString(),
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey,
                                      fontSize:
                                          12.0,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 4.0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ]),
                  padding: EdgeInsets.fromLTRB(
                      0.0, 0.0, 0.0, 0.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      color: HexColor.fromHex(
                          '#DCF8C6'),
                      borderRadius:
                          BorderRadius.circular(
                              6.0)),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(
                              index)
                          ? 0.0
                          : 0.0,
                      right: 5.0),
                )));
      } else {
        return GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dx != 0) {
                _onSwipe(
                    document.data()['idFrom'],
                    document.data()['content']);
              }
            },
            onTapDown: _storePosition,
            onLongPress: () {
              final RenderBox overlay =
                  Overlay.of(context)
                      .context
                      .findRenderObject();
              showMenu(
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                        value: 0,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context);
                            _onSwipe(
                                document.data()[
                                    'idFrom'],
                                document.data()[
                                    'content']);
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.reply,
                                  color: Colors
                                      .black),
                              Text("Reply",
                                  style: TextStyle(
                                      color: Colors
                                          .black)),
                            ],
                          ),
                        )),
                    document.data()['type'] == 0
                        ? PopupMenuItem(
                            value: 0,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(
                                    context);
                                FlutterClipboard.copy(
                                        document.data()[
                                            'content'])
                                    .then(
                                        (value) {
                                  print('copied');
                                  Fluttertoast
                                      .showToast(
                                          msg:
                                              'Copied');
                                });
                              },
                              child: Row(
                                children: <
                                    Widget>[
                                  Icon(
                                      Icons
                                          .content_copy,
                                      color: Colors
                                          .black),
                                  Text("Copy",
                                      style: TextStyle(
                                          color: Colors
                                              .black)),
                                ],
                              ),
                            ))
                        : Container(),
                    PopupMenuItem(
                        value: 0,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context);
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                title: Text(
                                    'Delete message?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed:
                                        () {
                                      Navigator.pop(
                                          context);
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                              'messages')
                                          .doc(
                                              groupChatId)
                                          .collection(
                                              groupChatId)
                                          .doc(document
                                              .data()['timestamp']
                                              .toString())
                                          .update({
                                        'deleteForId-' +
                                                prefs.getString('id'):
                                            true,
                                      });

                                      /*
                                      if (messageToBubbleMap[document
                                              .data()['timestamp']
                                              .toString()] !=
                                          null) {
                                        FirebaseFirestore
                                            .instance
                                            .collection(
                                                'messages')
                                            .doc(
                                                groupChatId)
                                            .collection(
                                                groupChatId)
                                            .doc(messageToBubbleMap[document.data()['timestamp'].toString()]
                                                .toString())
                                            .update({
                                          'deleteForId-' +
                                                  prefs.getString('id'):
                                              true,
                                        }); 
                                      }
                                      */
                                    },
                                    child: const Text(
                                        'DELETE FOR ME'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () async {
                                      Navigator.pop(
                                          context);
                                      /*
                                      var documentReference = FirebaseFirestore
                                          .instance
                                          .collection(
                                              'messages')
                                          .doc(
                                              groupChatId)
                                          .collection(
                                              groupChatId)
                                          .doc(document
                                              .data()['timestamp']
                                              .toString());
                                      await FirebaseFirestore
                                          .instance
                                          .runTransaction((Transaction
                                              myTransaction) async {
                                        myTransaction
                                            .delete(
                                                documentReference);                      
                                      });
                                      */

                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                              'messages')
                                          .doc(
                                              groupChatId)
                                          .collection(
                                              groupChatId)
                                          .doc(document
                                              .data()['timestamp']
                                              .toString())
                                          .update({
                                        'deleteForAll':
                                            true,
                                      });
                                    },
                                    child: const Text(
                                        'DELETE FOR EVERYONE'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () async {
                                      Navigator.pop(
                                          context);
                                    },
                                    child: const Text(
                                        'CANCEL'),
                                  )
                                ],
                              ),
                            );
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete,
                                  color: Colors
                                      .black),
                              Text("Delete",
                                  style: TextStyle(
                                      color: Colors
                                          .black)),
                            ],
                          ),
                        )),
                  ],
                  context: context,
                  position: RelativeRect.fromRect(
                      _tapPosition &
                          const Size(40,
                              40), // smaller rect, the touch area
                      Offset.zero &
                          overlay
                              .size // Bigger rect, the entire screen
                      ));
            },
            onTap: () {
              _onTap(document.data()['idFrom'],
                  document.data()['content']);
            },
            child: Column(children: <Widget>[
              Row(
                children: <Widget>[
                  document.data()['type'] == 0
                      // Text
                      ? ChatBubble(
                          clipper:
                              ChatBubbleClipper1(
                                  type: BubbleType
                                      .sendBubble,
                                  radius: 5.0),
                          alignment:
                              Alignment.topRight,
                          margin: EdgeInsets.only(
                              top: 12),
                          backGroundColor:
                              HexColor.fromHex(
                                  '#DCF8C6'),
                          child: Container(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .start,
                                children: [
                                  document.data()[
                                              'isReplyingMsg'] !=
                                          null
                                      ? ReplyMessageWidget(
                                          message:
                                              messag)
                                      : Container(),
                                  document.data()[
                                              'isReplyingMsg'] !=
                                          null
                                      ? SizedBox(
                                          height:
                                              10)
                                      : Container(),
                                  Text(
                                    document.data()[
                                        'content'],
                                    style: TextStyle(
                                        color:
                                            primaryColor),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .end,
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: <
                                        Widget>[
                                      Container(
                                        margin: EdgeInsets.only(
                                            right:
                                                0.0),
                                        width:
                                            200.0,
                                        child:
                                            Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: <
                                              Widget>[
                                            Text(
                                              msggTime.toString(),
                                              style:
                                                  TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            SizedBox(
                                              width:
                                                  4.0,
                                            ),
                                            _getIcon(
                                                document.data()['isSent'] != null ? document.data()['isSent'] : false,
                                                document.data()['isRead'] != null ? document.data()['isRead'] : false),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ]),
                            padding: EdgeInsets
                                .fromLTRB(
                                    0.0,
                                    0.0,
                                    0.0,
                                    0.0),
                            width: 200.0,
                            decoration: BoxDecoration(
                                color: HexColor
                                    .fromHex(
                                        '#DCF8C6'),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            6.0)),
                            margin: EdgeInsets.only(
                                bottom:
                                    isLastMessageRight(
                                            index)
                                        ? 0.0
                                        : 0.0,
                                right: 5.0),
                          ))
                      : document.data()['type'] ==
                              1
                          // Image
                          ? ChatBubble(
                              clipper: ChatBubbleClipper1(
                                  type: BubbleType
                                      .sendBubble,
                                  radius: 5.0),
                              alignment: Alignment
                                  .topRight,
                              margin:
                                  EdgeInsets.only(
                                      top: 12),
                              backGroundColor:
                                  HexColor.fromHex(
                                      '#DCF8C6'),
                              child: Container(
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
                                              AlwaysStoppedAnimation<Color>(themeColor),
                                        ),
                                        width:
                                            200.0,
                                        height:
                                            200.0,
                                        padding:
                                            EdgeInsets.all(
                                                70.0),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              greyColor2,
                                          borderRadius:
                                              BorderRadius.all(
                                            Radius.circular(
                                                8.0),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context,
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
                                          Radius.circular(
                                              8.0),
                                        ),
                                        clipBehavior:
                                            Clip.hardEdge,
                                      ),
                                      imageUrl: document
                                              .data()[
                                          'content'],
                                      width:
                                          200.0,
                                      height:
                                          200.0,
                                      fit: BoxFit
                                          .cover,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(
                                                5.0)),
                                    clipBehavior:
                                        Clip.hardEdge,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                FullPhoto(url: document.data()['content'])));
                                  },
                                  padding:
                                      EdgeInsets
                                          .all(0),
                                ),
                                margin: EdgeInsets.only(
                                    bottom: isLastMessageRight(
                                            index)
                                        ? 0.0
                                        : 0.0,
                                    right: 4.0,
                                    top: 0.0,
                                    left: 0.0),
                              ))
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
                mainAxisAlignment:
                    MainAxisAlignment.end,
              ),
            ]));
      }
    } else {
      // Left (peer message)
      FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(document
              .data()['timestamp']
              .toString())
          .update(
              {'isSent': true, 'isRead': true});

      if (document.data()['deleteForId-' +
              prefs.getString('id')] !=
          null) {
        return Container();
      } else if (document
              .data()['deleteForAll'] !=
          null) {
        return GestureDetector(
            onTapDown: _storePosition,
            onLongPress: () {
              final RenderBox overlay =
                  Overlay.of(context)
                      .context
                      .findRenderObject();
              showMenu(
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                        value: 0,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context);
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                title: Text(
                                    'Delete message?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed:
                                        () {
                                      Navigator.pop(
                                          context);
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                              'messages')
                                          .doc(
                                              groupChatId)
                                          .collection(
                                              groupChatId)
                                          .doc(document
                                              .data()['timestamp']
                                              .toString())
                                          .update({
                                        'deleteForId-' +
                                                prefs.getString('id'):
                                            true,
                                      });
                                    },
                                    child: const Text(
                                        'DELETE FOR ME'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () async {
                                      Navigator.pop(
                                          context);
                                    },
                                    child: const Text(
                                        'CANCEL',
                                        style: TextStyle(
                                            color:
                                                Colors.black)),
                                  )
                                ],
                              ),
                            );
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete,
                                  color: Colors
                                      .black),
                              Text("Delete",
                                  style: TextStyle(
                                      color: Colors
                                          .black)),
                            ],
                          ),
                        )),
                  ],
                  context: context,
                  position: RelativeRect.fromRect(
                      _tapPosition &
                          const Size(40,
                              40), // smaller rect, the touch area
                      Offset.zero &
                          overlay
                              .size // Bigger rect, the entire screen
                      ));
            },
            child: Container(
                child: Column(children: <Widget>[
              Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  mainAxisAlignment:
                      MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
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
                                      themeColor),
                            ),
                            width: 35.0,
                            height: 35.0,
                            padding:
                                EdgeInsets.all(
                                    0.0),
                            margin:
                                EdgeInsets.only(
                                    top: 6.0),
                          ),
                          imageUrl: peerAvatar,
                          width: 35.0,
                          height: 35.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius:
                            BorderRadius.all(
                          Radius.circular(18.0),
                        ),
                        clipBehavior:
                            Clip.hardEdge,
                      ),
                      margin: EdgeInsets.only(
                          top: 10.0),
                    ),
                    ChatBubble(
                        clipper: ChatBubbleClipper1(
                            type: BubbleType
                                .receiverBubble,
                            radius: 5.0),
                        alignment:
                            Alignment.topRight,
                        margin: EdgeInsets.only(
                            top: 12),
                        backGroundColor:
                            greyColor2,
                        child: Container(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .start,
                              children: [
                                Row(children: <
                                    Widget>[
                                  Icon(
                                      Icons
                                          .do_disturb_outlined,
                                      color: Colors
                                          .grey
                                          .shade600,
                                      size: 15),
                                  Text(
                                      ' This message was deleted',
                                      style: TextStyle(
                                          color: Colors
                                              .grey
                                              .shade600,
                                          fontStyle:
                                              FontStyle.italic))
                                ]),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .end,
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .end,
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: <
                                      Widget>[
                                    Container(
                                      margin: EdgeInsets.only(
                                          right:
                                              0.0),
                                      width:
                                          200.0,
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize
                                                .min,
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .end,
                                        children: <
                                            Widget>[
                                          Text(
                                            msggTime
                                                .toString(),
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.grey,
                                              fontSize:
                                                  12.0,
                                            ),
                                          ),
                                          SizedBox(
                                            width:
                                                4.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ]),
                          padding:
                              EdgeInsets.fromLTRB(
                                  0.0,
                                  0.0,
                                  0.0,
                                  0.0),
                          width: 200.0,
                          decoration: BoxDecoration(
                              color: greyColor2,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          8.0)),
                          margin: EdgeInsets.only(
                              left: 5.0),
                        ))
                  ])
            ])));
      } else {
        return GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dx != 0) {
                _onSwipe(
                    document.data()['idFrom'],
                    document.data()['content']);
              }
            },
            onTapDown: _storePosition,
            onLongPress: () {
              final RenderBox overlay =
                  Overlay.of(context)
                      .context
                      .findRenderObject();
              showMenu(
                  items: <PopupMenuEntry>[
                    PopupMenuItem(
                        value: 0,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context);
                            _onSwipe(
                                document.data()[
                                    'idFrom'],
                                document.data()[
                                    'content']);
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.reply,
                                  color: Colors
                                      .black),
                              Text("Reply",
                                  style: TextStyle(
                                      color: Colors
                                          .black)),
                            ],
                          ),
                        )),
                    document.data()['type'] == 0
                        ? PopupMenuItem(
                            value: 0,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(
                                    context);
                                FlutterClipboard.copy(
                                        document.data()[
                                            'content'])
                                    .then(
                                        (value) {
                                  print('copied');
                                  Fluttertoast
                                      .showToast(
                                          msg:
                                              'Copied');
                                });
                              },
                              child: Row(
                                children: <
                                    Widget>[
                                  Icon(
                                      Icons
                                          .content_copy,
                                      color: Colors
                                          .black),
                                  Text("Copy",
                                      style: TextStyle(
                                          color: Colors
                                              .black)),
                                ],
                              ),
                            ))
                        : Container(),
                    PopupMenuItem(
                        value: 0,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                                context);
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                title: Text(
                                    'Delete message?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed:
                                        () {
                                      Navigator.pop(
                                          context);
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                              'messages')
                                          .doc(
                                              groupChatId)
                                          .collection(
                                              groupChatId)
                                          .doc(document
                                              .data()['timestamp']
                                              .toString())
                                          .update({
                                        'deleteForId-' +
                                                prefs.getString('id'):
                                            true,
                                      });
                                    },
                                    child: const Text(
                                        'DELETE FOR ME'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () async {
                                      Navigator.pop(
                                          context);
                                    },
                                    child: const Text(
                                        'CANCEL'),
                                  )
                                ],
                              ),
                            );
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete,
                                  color: Colors
                                      .black),
                              Text("Delete",
                                  style: TextStyle(
                                      color: Colors
                                          .black)),
                            ],
                          ),
                        )),
                  ],
                  context: context,
                  position: RelativeRect.fromRect(
                      _tapPosition &
                          const Size(40,
                              40), // smaller rect, the touch area
                      Offset.zero &
                          overlay
                              .size // Bigger rect, the entire screen
                      ));
            },
            onTap: () {
              _onTap(document.data()['idFrom'],
                  document.data()['content']);
            },
            child: Container(
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    mainAxisAlignment:
                        MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        child: Material(
                          child:
                              CachedNetworkImage(
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
                              width: 35.0,
                              height: 35.0,
                              padding:
                                  EdgeInsets.all(
                                      0.0),
                              margin:
                                  EdgeInsets.only(
                                      top: 6.0),
                            ),
                            imageUrl: peerAvatar,
                            width: 35.0,
                            height: 35.0,
                            fit: BoxFit.cover,
                          ),
                          borderRadius:
                              BorderRadius.all(
                            Radius.circular(18.0),
                          ),
                          clipBehavior:
                              Clip.hardEdge,
                        ),
                        margin: EdgeInsets.only(
                            top: 10.0),
                      ),
                      document.data()['type'] == 0
                          ? ChatBubble(
                              clipper: ChatBubbleClipper1(
                                  type: BubbleType
                                      .receiverBubble,
                                  radius: 5.0),
                              alignment: Alignment
                                  .topRight,
                              margin:
                                  EdgeInsets
                                      .only(
                                          top:
                                              12),
                              backGroundColor:
                                  greyColor2,
                              child: Container(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .start,
                                    children: [
                                      document.data()['isReplyingMsg'] !=
                                              null
                                          ? ReplyMessageWidget(
                                              message:
                                                  messag)
                                          : Container(),
                                      document.data()['isReplyingMsg'] !=
                                              null
                                          ? SizedBox(
                                              height:
                                                  10)
                                          : Container(),
                                      Text(
                                        document.data()[
                                            'content'],
                                        style: TextStyle(
                                            color:
                                                Colors.black),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .end,
                                        mainAxisSize:
                                            MainAxisSize
                                                .min,
                                        children: <
                                            Widget>[
                                          Container(
                                            margin:
                                                EdgeInsets.only(right: 0.0),
                                            width:
                                                200.0,
                                            child:
                                                Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  msggTime.toString(),
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 4.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ]),
                                padding:
                                    EdgeInsets
                                        .fromLTRB(
                                            0.0,
                                            0.0,
                                            0.0,
                                            0.0),
                                width: 200.0,
                                decoration: BoxDecoration(
                                    color:
                                        greyColor2,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                8.0)),
                                margin: EdgeInsets
                                    .only(
                                        left:
                                            5.0),
                              ))
                          : document
                                          .data()[
                                      'type'] ==
                                  1
                              ? ChatBubble(
                                  clipper: ChatBubbleClipper1(
                                      type: BubbleType
                                          .receiverBubble,
                                      radius:
                                          5.0),
                                  alignment:
                                      Alignment
                                          .topRight,
                                  margin: EdgeInsets
                                      .only(
                                          top:
                                              12),
                                  backGroundColor:
                                      greyColor2,
                                  child:
                                      Container(
                                    child:
                                        FlatButton(
                                      child:
                                          Material(
                                        child:
                                            CachedNetworkImage(
                                          placeholder:
                                              (context, url) =>
                                                  Container(
                                            child:
                                                CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(themeColor),
                                            ),
                                            width:
                                                200.0,
                                            height:
                                                200.0,
                                            padding:
                                                EdgeInsets.all(70.0),
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  greyColor2,
                                              borderRadius:
                                                  BorderRadius.all(
                                                Radius.circular(8.0),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context,
                                                  url,
                                                  error) =>
                                              Material(
                                            child:
                                                Image.asset(
                                              'images/img_not_available.jpeg',
                                              width:
                                                  200.0,
                                              height:
                                                  200.0,
                                              fit:
                                                  BoxFit.cover,
                                            ),
                                            borderRadius:
                                                BorderRadius.all(
                                              Radius.circular(8.0),
                                            ),
                                            clipBehavior:
                                                Clip.hardEdge,
                                          ),
                                          imageUrl:
                                              document.data()['content'],
                                          width:
                                              200.0,
                                          height:
                                              200.0,
                                          fit: BoxFit
                                              .cover,
                                        ),
                                        borderRadius:
                                            BorderRadius.all(
                                                Radius.circular(5.0)),
                                        clipBehavior:
                                            Clip.hardEdge,
                                      ),
                                      onPressed:
                                          () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => FullPhoto(url: document.data()['content'])));
                                      },
                                      padding:
                                          EdgeInsets
                                              .all(0),
                                    ),
                                    margin: EdgeInsets
                                        .only(
                                            left:
                                                6.0),
                                  ))
                              : Container(
                                  child:
                                      Image.asset(
                                    'images/${document.data()['content']}.gif',
                                    width: 100.0,
                                    height: 100.0,
                                    fit: BoxFit
                                        .cover,
                                  ),
                                  margin: EdgeInsets.only(
                                      bottom: isLastMessageRight(
                                              index)
                                          ? 20.0
                                          : 10.0,
                                      right:
                                          10.0),
                                ),
                    ],
                  ),

                  // Time
                  isLastMessageLeft(index)
                      ? Container(
                          child: Text(
                            DateFormat(
                                    'dd MMM kk:mm')
                                .format(DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(document
                                            .data()[
                                        'timestamp']))),
                            style: TextStyle(
                                color: greyColor,
                                fontSize: 12.0,
                                fontStyle:
                                    FontStyle
                                        .italic),
                          ),
                          margin: EdgeInsets.only(
                              left: 50.0,
                              top: 5.0,
                              bottom: 0.0),
                        )
                      : Container(),
                ],
                crossAxisAlignment:
                    CrossAxisAlignment.start,
              ),
              margin:
                  EdgeInsets.only(bottom: 10.0),
            ));
      }
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

  Widget _getIcon(
      bool isMessageSent, bool isMessageRead) {
    if (!isMessageSent) {
      return Icon(
        Icons.check,
        size: 18.0,
        color: Colors.grey,
      );
    }
    return Icon(
      Icons.done_all,
      size: 18.0,
      color: isMessageRead
          ? Colors.blue
          : Colors.grey,
    );
  }

  Widget buildInput() {
    typingStatusSave();
    var message = {
      'message': replyMsg,
      'username': replyingTo,
    };
    return Column(children: <Widget>[
      isReplying
          ? ReplyMessageWidget(
              message: message,
              onCancelReply: cancelReply)
          : Text(''),
      Container(
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
                        textEditingController
                            .text,
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
                  controller:
                      textEditingController,
                  decoration:
                      InputDecoration.collapsed(
                    hintText:
                        'Type your message...',
                    hintStyle: TextStyle(
                        color: greyColor),
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
                    color: greyColor2,
                    width: 0.5)),
            color: Colors.white),
      )
    ]);
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

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 ||
        hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(
        int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
