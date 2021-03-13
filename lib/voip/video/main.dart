import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';
import './src/pages/index.dart';

class VideoCall extends StatelessWidget {
  final String emailId;
  final String peerId;

  VideoCall({Key key, this.emailId, this.peerId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Video Call',
          style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: IndexPage(
          emailId: emailId, peerId: peerId),
    );
  }
}
