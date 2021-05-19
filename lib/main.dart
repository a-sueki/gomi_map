import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gomi Map',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'ゴミマップ'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
      print(_image.toString());
    });
  }

  Future getLatLng(List<String> arguments) async {
    for (final filename in arguments) {
      print("read $filename ..");

      final fileBytes = File(filename).readAsBytesSync();
      final data = await readExifFromBytes(fileBytes);

      if (data == null || data.isEmpty) {
        return "No EXIF information found";
      }

      if (data.containsKey('JPEGThumbnail')) {
        print('File has JPEG thumbnail');
        data.remove('JPEGThumbnail');
      }
      if (data.containsKey('TIFFThumbnail')) {
        print('File has TIFF thumbnail');
        data.remove('TIFFThumbnail');
      }

      for (final entry in data.entries) {
        print("${entry.key}: ${entry.value}");
      }
    }
  }


  LocationData currentLocation;

  // StreamSubscription<LocationData> locationSubscription;

  Location _locationService = new Location();
  String error;

  @override
  void initState() {
    super.initState();

    initPlatformState();
    _locationService.onLocationChanged.listen((LocationData result) async {
      setState(() {
        currentLocation = result;
      });
    });
  }

  void initPlatformState() async {
    LocationData myLocation;
    try {
      myLocation = await _locationService.getLocation();
      error = "";
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENITED')
        error = 'Permission denited';
      else if (e.code == 'PERMISSION_DENITED_NEVER_ASK')
        error =
            'Permission denited - please ask the user to enable it from the app settings';
      myLocation = null;
    }
    setState(() {
      currentLocation = myLocation;
    });
  }

  Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 17.0,
          ),
          myLocationEnabled: true,
        ),
        floatingActionButton: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 30.0, bottom: 10.0),
                child: FloatingActionButton.extended(
                  onPressed: getImage,
                  label: Text('ゴミみっけ'),
                  tooltip: '撮影',
                  icon: Icon(Icons.camera_alt),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
