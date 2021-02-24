import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';

class MapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String token =
        'pk.eyJ1IjoiaHJpc2hpayIsImEiOiJja2p1M2FxdzYwanVzMnJxc2FpZTlvN29rIn0.L3rKAq6uzI9McmnwV_bQag';
    final String style =
        'https://api.mapbox.com/styles/v1/hrishik/ckldqnvic4clw17nuvw2jm7ey/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiaHJpc2hpayIsImEiOiJja2p1M2FxdzYwanVzMnJxc2FpZTlvN29rIn0.L3rKAq6uzI9McmnwV_bQag';

    return Scaffold(
      body: MapboxMap(
        accessToken: token,
        styleString: style,
        initialCameraPosition: CameraPosition(
          zoom: 15.0,
          target: LatLng(14.508, 46.048),
        ),
        onMapCreated: (MapboxMapController
            controller) async {
          final result =
              await acquireCurrentLocation();
          await controller.animateCamera(
            CameraUpdate.newLatLng(result),
          );

          await controller.addCircle(
            CircleOptions(
              circleRadius: 8.0,
              circleColor: '#006992',
              circleOpacity: 0.8,
              geometry: result,
              draggable: false,
            ),
          );
        },

        // I'm using the onMapLongClick callback here, but there's also one for
        // a single tap, onMapClick, but heck, that's just for a tutorial
      ),
    );
  }

  Future<LatLng> acquireCurrentLocation() async {
    // Initializes the plugin and starts listening for potential platform events
    Location location = new Location();

    // Whether or not the location service is enabled
    bool serviceEnabled;

    // Status of a permission request to use location services
    PermissionStatus permissionGranted;

    // Check if the location service is enabled, and if not, then request it. In
    // case the user refuses to do it, return immediately with a null result
    serviceEnabled =
        await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled =
          await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    // Check for location permissions; similar to the workflow in Android apps,
    // so check whether the permissions is granted, if not, first you need to
    // request it, and then read the result of the request, and only proceed if
    // the permission was granted by the user
    permissionGranted =
        await location.hasPermission();
    if (permissionGranted ==
        PermissionStatus.denied) {
      permissionGranted =
          await location.requestPermission();
      if (permissionGranted !=
          PermissionStatus.granted) {
        return null;
      }
    }

    // Gets the current location of the user
    final locationData =
        await location.getLocation();
    return LatLng(locationData.latitude,
        locationData.longitude);
  }
}

