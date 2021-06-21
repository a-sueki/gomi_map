import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:camera/camera.dart';
import 'package:gomi_map/take_picture.dart';
import 'package:provider/provider.dart';

import 'package:geolocator/geolocator.dart';


// 使用できるカメラのリストを取得
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  //final firstCamera = cameras.first;
  print(cameras);
  runApp(
    // モデルオブジェクトに変更があると、リッスンしているWidget（配下の子Widget）を再構築する
      ChangeNotifierProvider(
        create: (context) => Data(),//モデルオブジェクトを作成する
        child:MaterialApp(theme: ThemeData.dark(), home: MyApp(cameras: cameras))),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key key, @required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gomi Map',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'ゴミマップ', cameras: cameras),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String title;

  const MyHomePage({Key key, this.title, @required this.cameras})
      : super(key: key);


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  final picker = ImagePicker();

  // Future getLatLng(List<String> arguments) async {
  //   for (final filename in arguments) {
  //     print("read $filename ..");
  //
  //     final fileBytes = File(filename).readAsBytesSync();
  //     final data = await readExifFromBytes(fileBytes);
  //     final tags = await readExifFromBytes(await File(filename).readAsBytes());
  //
  //     if (data == null || data.isEmpty) {
  //       return "No EXIF information found";
  //     }
  //
  //     if (data.containsKey('JPEGThumbnail')) {
  //       print('File has JPEG thumbnail');
  //       data.remove('JPEGThumbnail');
  //     }
  //     if (data.containsKey('TIFFThumbnail')) {
  //       print('File has TIFF thumbnail');
  //       data.remove('TIFFThumbnail');
  //     }
  //
  //     print('latitudeRef: ${tags['GPS GPSLatitudeRef']}');
  //     print('latitude: ${tags['GPS GPSLatitude']}');
  //     print('longitudeRef: ${tags['GPS GPSLongitudeRef']}');
  //     print('longitude: ${tags['GPS GPSLongitude']}');
  //
  //     tags.forEach((key, value) {
  //       print('$key --- $value');
  //     });
  //
  //     // for (final entry in data.entries) {
  //       // if (entry.key == 'MakerNote Tag 0x0023'){
  //       //   print("${entry.value}");
  //       // }
  //       // print("${entry.key}: ${entry.value}");
  //     // }
  //   }
  // }

  String _location = "no data";
  Future<void> getLocation() async {
    // 現在の位置を返す
    Position position = await Geolocator.getCurrentPosition();
    // 北緯がプラス。南緯がマイナス
    print("緯度: " + position.latitude.toString());
    // 東経がプラス、西経がマイナス
    print("経度: " + position.longitude.toString());
    // 高度
    print("高度: " + position.altitude.toString());
    // 距離をメートルで返す
    double distanceInMeters =
    Geolocator.distanceBetween(35.68, 139.76, -23.61, -46.40);
    print(distanceInMeters);
    // 方位を返す
    double bearing = Geolocator.bearingBetween(35.68, 139.76, -23.61, -46.40);
    print(bearing);
    setState(() {
      _location = position.toString();
    });
  }

  // Future<Position> _determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   // Test if location services are enabled.
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     // Location services are not enabled don't continue
  //     // accessing the position and request users of the
  //     // App to enable the location services.
  //     return Future.error('Location services are disabled.');
  //   }
  //
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       // Permissions are denied, next time you could try
  //       // requesting permissions again (this is also where
  //       // Android's shouldShowRequestPermissionRationale
  //       // returned true. According to Android guidelines
  //       // your App should show an explanatory UI now.
  //       return Future.error('Location permissions are denied');
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     // Permissions are denied forever, handle appropriately.
  //     return Future.error(
  //         'Location permissions are permanently denied, we cannot request permissions.');
  //   }
  //
  //   // When we reach here, permissions are granted and we can
  //   // continue accessing the position of the device.
  //   return await Geolocator.getCurrentPosition();
  // }


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
    //テスト用
    getLocation();

    if(Provider.of<Data>(context, listen: false).imgPathList != null &&
    Provider.of<Data>(context, listen: false).imgPathList.length != 0) {
      // getLatLng(Provider.of<Data>(context, listen: false).imgPathList);
    }


    if (currentLocation == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            Provider.of<Data>(context, listen: false).imgPath != null
                ? Provider.of<Data>(context, listen: false).imgPath : 'からぽ',
          ),
          // title: Text(widget.title),
        ),
        body:
        GoogleMap(
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
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return TakePictureScreen(camera: widget.cameras.first);
                    }));
                  },
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
