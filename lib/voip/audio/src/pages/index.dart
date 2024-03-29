import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './call.dart';

class IndexPage extends StatefulWidget {
  final String emailId;
  final String peerId;
  final String peerAvatar;

  IndexPage(
      {Key key,
      this.emailId,
      this.peerId,
      this.peerAvatar})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      IndexState(
          emailId: emailId,
          peerId: peerId,
          peerAvatar: peerAvatar);
}

class IndexState extends State<IndexPage> {
  final String emailId;
  final String peerId;
  final String peerAvatar;
  String selfAvatar;

  IndexState(
      {Key key,
      this.emailId,
      this.peerId,
      this.peerAvatar});

  /// create a channelController to retrieve text value
  final _channelController =
      TextEditingController();

  /// if channel textField is validated to have error
  bool _validateError = false;
  int _messageCount = 0;
  String username;
  ClientRole _role = ClientRole.Broadcaster;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(prefs.getString('id'))
        .get()
        .then((document) {
      selfAvatar = document.data()['photoUrl'];
    });
    username = prefs.getString('nickname');
    _channelController.text =
        prefs.getString('id');
  }

  @override
  void dispose() {
    // dispose input controller
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20),
          height: 400,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    enabled: false,
                    controller:
                        _channelController,
                    decoration: InputDecoration(
                      errorText: _validateError
                          ? 'Channel name is mandatory'
                          : null,
                      border:
                          UnderlineInputBorder(
                        borderSide:
                            BorderSide(width: 1),
                      ),
                      hintText: 'Channel name',
                    ),
                  ))
                ],
              ),
              Column(
                children: [
                  ListTile(
                    title: Text("Broadcaster"),
                    leading: Radio(
                      value:
                          ClientRole.Broadcaster,
                      groupValue: _role,
                      onChanged:
                          (ClientRole value) {
                        setState(() {
                          _role = value;
                          if (_role ==
                              ClientRole
                                  .Broadcaster) {
                            _channelController
                                    .text =
                                prefs.getString(
                                    'id');
                          }
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text("Audience"),
                    leading: Radio(
                      value: ClientRole.Audience,
                      groupValue: _role,
                      onChanged:
                          (ClientRole value) {
                        setState(() {
                          _role = value;
                          if (_role ==
                              ClientRole
                                  .Audience) {
                            _channelController
                                .text = peerId;
                          }
                        });
                      },
                    ),
                  )
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                        vertical: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        onPressed: onJoin,
                        child: Text('Join'),
                        color: Colors.blueAccent,
                        textColor: Colors.white,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String constructFCMPayload(String token) {
    _messageCount++;
    return jsonEncode({
      'token': token,
      'data': {
        'via': 'FlutterFire Cloud Messaging!!!',
        'count': _messageCount.toString(),
      },
      'notification': {
        'title': 'Hello FlutterFire!',
        'body':
            'This notification (#$_messageCount) was created via FCM!',
      },
    });
  }

  Future<void> sendPushMessage(receiver) async {
    var token = await getToken(receiver);
    if (token == null) {
      print(
          'Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse(
            'https://api.rnfirebase.io/messaging/send'),
        headers: <String, String>{
          'Content-Type':
              'application/json; charset=UTF-8',
        },
        body: constructFCMPayload(token),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print('error aaya yaar: $e');
    }
  }

  Future<void> sendNotification(
      receiver, msg) async {
    var token = await getToken(receiver);
    print('receiver id: $peerId');
    print('token : $token');

    final data = jsonEncode({
      "notification": {
        "body": msg,
        "title": "Voice Channel Invitation",
      },
      "priority": "high",
      "data": {
        "click_action":
            "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done",
        "body": msg,
        "title": "Voice Channel Invitation",
        "channelId": _channelController.text,
        "peerAvatar": prefs.getString('photoUrl'),
        "peerName": prefs.getString('nickname'),
        "timeout": 15000,
      },
      "to": "$token",
      "channelId": _channelController.text,
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

  Future<void> onJoin() async {
    // update input validation
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      if (_role == ClientRole.Broadcaster) {
        sendNotification(
            peerId,
            username != null
                ? username +
                    " is inviting you to join the voice channel"
                : "User is inviting you to join the voice channel");

        final Email email = Email(
          body:
              "Inviting you to join the voice channel",
          subject: 'Voice Channel Invitation',
          recipients: [emailId],
          isHTML: false,
        );
        //await FlutterEmailSender.send(email);

        var invitationSoundObj = {
          'playSound': true,
          'startTime': DateTime.now(),
          'peerId': prefs.getString('id'),
          'peerAvatar':
              prefs.getString('photoUrl'),
          'peerName': prefs.getString('nickname'),
          'type': 'voice',
        };
        FirebaseFirestore.instance
            .collection('users')
            .doc(peerId)
            .update({
          'channelInvitationSounds':
              invitationSoundObj
        });
      }

      await _handleCameraAndMic(
          Permission.camera);

      await _handleCameraAndMic(
          Permission.microphone);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPageAudio(
            channelName: _channelController.text,
            peerAvatar: peerAvatar,
            selfAvatar: selfAvatar,
            isReceiver: false,
          ),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(
      Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
