import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:networkapp/const.dart';
import 'package:networkapp/home.dart';
import 'package:networkapp/widget/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title})
      : super(key: key);

  final String title;

  @override
  LoginScreenState createState() =>
      LoginScreenState();
}

class LoginScreenState
    extends State<LoginScreen> {
  final GoogleSignIn googleSignIn =
      GoogleSignIn();
  final FirebaseAuth firebaseAuth =
      FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  User currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(
                currentUserId:
                    prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    var radius;

    GoogleSignInAccount googleUser =
        await googleSignIn.signIn();

    GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential =
        GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    User firebaseUser = (await firebaseAuth
            .signInWithCredential(credential))
        .user;

    Position position = await Geolocator()
        .getCurrentPosition(
            desiredAccuracy:
                LocationAccuracy.high);

    final geo = Geoflutterfire();

    GeoFirePoint myLocation = geo.point(
        latitude: position.latitude,
        longitude: position.longitude);

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result =
          await FirebaseFirestore.instance
              .collection('users')
              .where('id',
                  isEqualTo: firebaseUser.uid)
              .get();
      final List<DocumentSnapshot> documents =
          result.docs;

      if (documents.length == 0) {
        // Update data to server if new user
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoURL,
          'id': firebaseUser.uid,
          'email': firebaseUser.email,
          'createdAt': DateTime.now()
              .millisecondsSinceEpoch
              .toString(),
          'chattingWith': null,
          'position': myLocation.data,
          'radius': 10,
        });
        radius = 10;
        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString(
            'id', currentUser.uid);
        await prefs.setString(
            'nickname', currentUser.displayName);
        await prefs.setString(
            'photoUrl', currentUser.photoURL);
        await prefs.setInt(
            'radius', 10);
        await prefs.setString(
            'email', currentUser.email);
      } else {
        FirebaseFirestore.instance
            .collection('users')
            .doc(documents[0].data()['id'])
            .update(
                {'position': myLocation.data});

        // Write data to local
        await prefs.setString(
            'id', documents[0].data()['id']);
        await prefs.setString('nickname',
            documents[0].data()['nickname']);
        await prefs.setString('photoUrl',
            documents[0].data()['photoUrl']);
        await prefs.setString('aboutMe',
            documents[0].data()['aboutMe']);
        await prefs.setInt('radius',
            documents[0].data()['radius']);
        await prefs.setString('email',
            documents[0].data()['email']);
        radius = documents[0].data()['radius'];
      }

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                  currentUserId: firebaseUser.uid,
                  position: position,
                  radius: radius,
                  email: firebaseUser.email)));

      Fluttertoast.showToast(
          msg: "Sign in success");

      this.setState(() {
        isLoading = false;
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({'status': 'online'});
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: FlatButton(
                  onPressed: handleSignIn,
                  child: Text(
                    'SIGN IN WITH GOOGLE',
                    style:
                        TextStyle(fontSize: 16.0),
                  ),
                  color: Color(0xffdd4b39),
                  highlightColor:
                      Color(0xffff7f7f),
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                      30.0, 15.0, 30.0, 15.0)),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? const Loading()
                  : Container(),
            ),
          ],
        ));
  }
}
