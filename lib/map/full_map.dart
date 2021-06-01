import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:networkapp/map/user_profile.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
import 'page.dart';
import 'dart:math' show cos, sqrt, asin;

class FullMapPage extends ExamplePage {
  FullMapPage()
      : super(const Icon(Icons.map),
            'Full Screen Map');

  @override
  Widget build(BuildContext context) {
    return const FullMap();
  }
}

class FullMap extends StatefulWidget {
  const FullMap();

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  MapboxMapController mapController;
  final geo = Geoflutterfire();
  SharedPreferences prefs;
  var radius;
  String userId;
  List<Map<String, dynamic>> userList = [];

  Future<void> addImageFromUrl(
      String name, Uri uri) async {
    var response = await http.get(uri);
    return mapController.addImage(
        name, response.bodyBytes);
  }

  Future readLocal() async {
    prefs = await SharedPreferences.getInstance();
    radius = prefs.getInt('radius') ?? 100000000;
    userId = prefs.getString('id') ?? "";
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

  void _onMapCreated(
      MapboxMapController controller) async {
    mapController = controller;

    await readLocal();

    Position position = await Geolocator()
        .getCurrentPosition(
            desiredAccuracy:
                LocationAccuracy.high);

    var collectionReference = FirebaseFirestore
        .instance
        .collection('users');

    GeoFirePoint center = geo.point(
        latitude: position.latitude,
        longitude: position.longitude);

    String field = 'position';

    Stream<List<DocumentSnapshot>> stream = geo
        .collection(
            collectionRef: collectionReference)
        .within(
            center: center,
            radius: radius.toDouble(),
            field: field);

    stream.listen(
        (List<DocumentSnapshot> documentList) {
      documentList
          .forEach((DocumentSnapshot document) {
        addImageFromUrl(
            document.data()['id'],
            Uri.parse(
                document.data()['photoUrl']));
        double dis = calculateDistance(
            document
                .data()['position']['geopoint']
                .latitude,
            document
                .data()['position']['geopoint']
                .longitude,
            position.latitude,
            position.longitude);
        dis = double.parse(
            (dis).toStringAsFixed(3));

        mapController.addSymbol(SymbolOptions(
          geometry: LatLng(
              document
                  .data()['position']['geopoint']
                  .latitude,
              document
                  .data()['position']['geopoint']
                  .longitude),
          iconImage: document.data()['id'],
          iconOffset: Offset(-13, -13),
          textField:
              userId == document.data()['id']
                  ? document.data()['nickname'] +
                      " (Me)"
                  : document.data()['nickname'] +
                      " (" +
                      dis.toString() +
                      " km away)",
          textSize: 12.5,
          textOffset: Offset(-1, 0.6),
          textAnchor: 'top',
          textColor: '#000000',
          textHaloBlur: 1,
          textHaloColor: '#ffffff',
          textHaloWidth: 0.8,
          fontNames: [
            'DIN Offc Pro Bold',
            'Arial Unicode MS Regular'
          ],
        ));
        controller.addCircle(
          CircleOptions(
            geometry: LatLng(
                document
                    .data()['position']
                        ['geopoint']
                    .latitude,
                document
                    .data()['position']
                        ['geopoint']
                    .longitude),
            circleColor:
                document.data()['status'] ==
                        "online"
                    ? "#00FF00"
                    : "#000000",
          ),
        );
        Map<String, dynamic> myObject = {
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
        userList.add(myObject);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: MapboxMap(
      accessToken: MapsDemo.ACCESS_TOKEN,
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
          target: LatLng(24.6424302, 77.3052066)),
      onStyleLoadedCallback:
          onStyleLoadedCallback,
      onMapClick: (point, latLng) async {
        var data = userList.where((user) =>
            ((user["latitude"] - latLng.latitude)
                    .abs() <=
                0.00005));
        if (data.length >= 1) {
          var dataLong = userList.where((user) =>
              ((user["longitude"] -
                          latLng.longitude)
                      .abs() <=
                  0.00005));
          if (dataLong.length >= 1) {
            var dataList = dataLong.toList();
            double min = 1000000.0;
            var finalData;
            print(dataList);
            for (var i = 0;
                i < dataList.length;
                i++) {
              if (min >
                  ((dataList[i]["latitude"] -
                          latLng.latitude)
                      .abs())) {
                min = ((dataList[i]["latitude"] -
                        latLng.latitude)
                    .abs());
                finalData = dataList[i];
              }
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        UserProfile(
                            data: finalData !=
                                    null
                                ? finalData
                                : dataLong
                                    .toList()[0],
                            currentUserId:
                                userId)));
          }
        }
      },
    ));
  }

  void onStyleLoadedCallback() {}
}
