import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';
import './src/pages/index.dart';

class VoiceCall extends StatelessWidget {
  final String emailId;
  final String peerId;
  final String peerAvatar;

  VoiceCall({Key key, this.emailId, this.peerId, this.peerAvatar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice Call',
          style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: IndexPage(
          emailId: emailId, peerId: peerId,peerAvatar:peerAvatar),
    );
  }
}
