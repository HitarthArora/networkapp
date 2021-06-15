import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart'
    as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart'
    as RtcRemoteView;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:networkapp/const.dart';
import 'package:networkapp/home.dart';

import '../utils/settings.dart';

class CallPageAudio extends StatefulWidget {
  final String channelName;
  final String peerId;
  final ClientRole role;
  final String peerAvatar;
  final String selfAvatar;
  final bool isReceiver;

  CallPageAudio(
      {Key key,
      this.channelName,
      this.role,
      this.peerId,
      this.peerAvatar,
      this.selfAvatar,
      this.isReceiver})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState(
      peerId: peerId,
      peerAvatar: peerAvatar,
      selfAvatar: selfAvatar,
      isReceiver: isReceiver);
}

class _CallPageState
    extends State<CallPageAudio> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine _engine;
  String peerId;
  Timer _timer;
  SharedPreferences prefs;
  final String peerAvatar;
  final String selfAvatar;
  bool isReceiver;
  int noOfUsersjoined = 1;
  final _isHours = true;
  final _scrollController = ScrollController();

  _CallPageState(
      {Key key,
      this.peerId,
      this.peerAvatar,
      this.selfAvatar,
      this.isReceiver});

   final StopWatchTimer _stopWatchTimer = StopWatchTimer(
    isLapHours: true,
    onChange: (value) => print('onChange $value'),
    onChangeRawSecond: (value) => print('onChangeRawSecond $value'),
    onChangeRawMinute: (value) => print('onChangeRawMinute $value'),
  );

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    timerFunction();
  }

  timerFunction() {
    _timer = new Timer(
        const Duration(milliseconds: 15000), () {
      setState(() {
        sendNotification(peerId);
      });
    });
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

  Future<void> sendNotification(receiver) async {
    var token = await getToken(receiver);
    print('receiver id: $peerId');
    print('token : $token');

    final data = jsonEncode({
      "notification": {
        "body":
            "You have missed a voice call from " +
                prefs.getString('nickname'),
        "title": "Missed Voice Call",
      },
      "priority": "high",
      "data": {
        "click_action":
            "FLUTTER_NOTIFICATION_CLICK",
        "id": "1",
        "status": "done",
        "body":
            "You have missed a voice call from " +
                prefs.getString('nickname'),
        "title": "Missed Voice Call",
        "peerAvatar": prefs.getString('photoUrl'),
        "peerName": prefs.getString('nickname'),
        "timeout": null,
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
    _timer.cancel();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings
            .add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine
        .enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration =
        VideoEncoderConfiguration();
    configuration.dimensions =
        VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(
        configuration);
    await _engine.joinChannel(
        Token, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.disableVideo();
    await _engine.setChannelProfile(
        ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(
        widget.role != null
            ? widget.role
            : ClientRole.Broadcaster);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
        error: (code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    }, joinChannelSuccess:
            (channel, uid, elapsed) {
      setState(() {
        final info =
            'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
      });
    }, leaveChannel: (stats) {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _users.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        _infoStrings.add(info);
        _users.add(uid);
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        _users.remove(uid);
      });
    }, firstRemoteVideoFrame:
            (uid, width, height, elapsed) {
      setState(() {
        final info =
            'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    }));
  }

  Widget voiceCallView() {
    final views = _getRenderViews();
    if (views != null) {
      if (views.length > 1) {
        _timer.cancel();
      }
      noOfUsersjoined = views.length;
    }
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Center(
              heightFactor: 7,
              child: Column(children: <Widget>[
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
                      width: 70.0,
                      height: 70.0,
                      margin: EdgeInsets.only(
                          top: 170.0,
                          bottom: 50.0,
                          left: 10.0,
                          right: 30.0),
                    ),
                    imageUrl: peerAvatar,
                    width: 70.0,
                    height: 70.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                      Radius.circular(35.0)),
                  clipBehavior: Clip.hardEdge,
                ),
                /*
                noOfUsersjoined == 1
                    ? Text('')
                    : StreamBuilder<int>(
                  stream: _stopWatchTimer.rawTime,
                  initialData: _stopWatchTimer.rawTime.value,
                  builder: (context, snap) {
                    final value = snap.data;
                    final displayTime =
                        StopWatchTimer.getDisplayTime(value, hours: _isHours);
                    return Column(
                      children: <Widget>[
                        /*
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            displayTime,
                            style: const TextStyle(
                                fontSize: 40,
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        */
                        /*
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            value.toString(),
                            style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Helvetica',
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                        */
                      ],
                    );
                  },
                ),*/
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    //if (widget.role == ClientRole.Broadcaster) {
    list.add(RtcLocalView.SurfaceView());
    //}
    _users.forEach((int uid) => list.add(
        RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(
        child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews =
        views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    if (views != null) {
      if (views.length > 1) {
        _timer.cancel();
      }
      noOfUsersjoined = views.length;
    }
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[
            _videoView(views[0])
          ],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(
                views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(
                views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  /// Toolbar layout
  Widget _toolbar() {
    //if (widget.role == ClientRole.Audience)
    // return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(
          vertical: 48),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted
                  ? Colors.white
                  : Colors.blueAccent,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted
                ? Colors.blueAccent
                : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
        ],
      ),
    );
  }

  /// Info panel to show logs
  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 55),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 55),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context,
                int index) {
              if (_infoStrings.isEmpty) {
                return null;
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets
                            .symmetric(
                          vertical: 2,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.yellowAccent,
                          borderRadius:
                              BorderRadius
                                  .circular(5),
                        ),
                        child: Text(
                          _infoStrings[index],
                          style: TextStyle(
                              color: Colors
                                  .blueGrey),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onCallEnd(BuildContext context) async {
    Navigator.pop(context);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(peerId)
        .update(
            {'channelInvitationSounds': null});
    if (isReceiver) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen()));
    }
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final views = _getRenderViews();
    if (views != null) {
      if (views.length > 1) {
        _timer.cancel();
      }
      noOfUsersjoined = views.length;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Ongoing Call'),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            voiceCallView(),
            _toolbar(),
          ],
        ),
      ),
    );
  }
}
