import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_tracking_example/constants.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Live tracking Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _completer = Completer();
  static const LatLng sourceLocation = LatLng(30.9196, 29.852);
  static const LatLng destination = LatLng(30.9329, 29.84238);
  LocationData? currentLocation;
  List<LatLng> polyLineCoordinates = [];
  BitmapDescriptor currentLocIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor sourceLocIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destLocIcon = BitmapDescriptor.defaultMarker;
  Uint8List? markerIcon;
  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    debugPrint('1.....................................');

    PolylineResult result = await polylinePoints
        .getRouteBetweenCoordinates(googleApiKey, PointLatLng(sourceLocation.latitude, sourceLocation.longitude), PointLatLng(destination.latitude, destination.longitude))
        .catchError((error) {
      debugPrint('This is how is Error.....................................');
      debugPrint(error.toString());
    });

    if (result.points.isNotEmpty) {
      debugPrint('This is how is done.....................................');
      result.points.forEach((element) {
        polyLineCoordinates.add(LatLng(element.latitude, element.longitude));
      });
      setState(() {});
    } else {
      debugPrint('Empty.....................................');
      debugPrint(result.status);
    }
  }

  void getLocation() async {
    Location location = Location();
    debugPrint('Begining');
    location.getLocation().then((value) {
      debugPrint('${value.longitude}   ..........');
      currentLocation = value;
      setState(() {
        debugPrint(currentLocation!.latitude.toString());
      });
    }).catchError((error) {
      debugPrint('$error   New Error2');
    });
    GoogleMapController googleMapController = await _completer.future.catchError((error) {
      debugPrint('$error   New Error');
    });

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      googleMapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(zoom: 16, target: LatLng(newLoc.latitude!, newLoc.longitude!))));
      setState(() {});
    });
  }

  void setCustomIcons() async {
    // currentLocIcon = await BitmapDescriptor.fromAssetImage(
    //     const ImageConfiguration(devicePixelRatio: 2.0),
    //     'assets/images/userAvatar.png');
    markerIcon = await getBytesFromAsset('assets/images/abdo2.png', 70);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  @override
  void initState() {
    setCustomIcons();
    getPolyPoints();
    getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: currentLocation != null && markerIcon != null
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                  zoom: 16,
                ),
                polylines: {Polyline(polylineId: const PolylineId('route'), points: polyLineCoordinates, color: Colors.red, width: 6)},
                markers: {
                  const Marker(markerId: MarkerId('MomHome'), position: sourceLocation),
                  const Marker(markerId: MarkerId('Fasel'), position: destination),
                  Marker(
                      markerId: const MarkerId('CurrentLocation'),
                      visible: true,
                      icon: BitmapDescriptor.fromBytes(markerIcon!),
                      position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!)),
                },
                onMapCreated: (con) {
                  _completer.complete(con);
                },
              )
            : const Text('Loading.........'),
      ),
    );
  }
}
