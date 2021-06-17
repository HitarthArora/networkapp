import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:networkapp/map/full_map.dart';
import 'full_map.dart';

import 'page.dart';

final List<ExamplePage> _allPages = <ExamplePage>[
  FullMapPage(),
];

class MapsDemo extends StatefulWidget {
  final position;

  static const String ACCESS_TOKEN =
      "pk.eyJ1IjoiaHJpc2hpayIsImEiOiJja2p1M2FxdzYwanVzMnJxc2FpZTlvN29rIn0.L3rKAq6uzI9McmnwV_bQag";

  MapsDemo({
    Key key,
    this.position,
  }) : super(key: key);
  @override
  State createState() => MapsDemoState(
        position: position,
      );
}

class MapsDemoState extends State<MapsDemo> {
  MapsDemoState({
    Key key,
    this.position,
  });
  final position;

  static const String ACCESS_TOKEN =
      "pk.eyJ1IjoiaHJpc2hpayIsImEiOiJja2p1M2FxdzYwanVzMnJxc2FpZTlvN29rIn0.L3rKAq6uzI9McmnwV_bQag";

  void _pushPage(BuildContext context,
      ExamplePage page) async {
    if (!kIsWeb) {
      final location = Location();
      final hasPermissions =
          await location.hasPermission();
      if (hasPermissions !=
          PermissionStatus.granted) {
        await location.requestPermission();
      }
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
            builder: (_) => Scaffold(
                  appBar: AppBar(
                      title: Text(page.title)),
                  body: page,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: ListView.builder(
        itemCount: _allPages.length,
        itemBuilder: (_, int index) => ListTile(
          leading: _allPages[index].leading,
          title: Text(_allPages[index].title),
          onTap: () => _pushPage(
              context,
              <ExamplePage>[
                FullMapPage(position:position),
              ][index]),
        ),
      ),
    );
  }
}
