import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:gomi_map/take_picture.dart';
import 'package:provider/provider.dart';
import 'package:gomi_map/marker_generator.dart';

// 使用できるカメラのリストを取得
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  //final firstCamera = cameras.first;
  print(cameras);
  runApp(
    // モデルオブジェクトに変更があると、リッスンしているWidget（配下の子Widget）を再構築する
    ChangeNotifierProvider(
        create: (context) => Data(), //モデルオブジェクトを作成する
        child: MaterialApp(
            theme: ThemeData.dark(), home: MyApp(cameras: cameras))),
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
  final picker = ImagePicker();
  LocationData currentLocation;
  // List<Uint8List> markerIcon;
  Uint8List markerIcon;

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

    List<Widget> markerWidgets = new List();
    for (int i = 0; i < 1; i++) {
      markerWidgets.add(
        Container(
          height: 50,
          width: 50,
          padding: EdgeInsets.all(10),
          color: Colors.green,
          child: Image.asset("img/smile_pixel_art_emoticon_emoji_icon_189295.png"),
        ),
      );
    }

    MarkerGenerator(markerWidgets, (bitmaps) {
      setState(() {
        mapBitmapsToMarkers(bitmaps);
      });
    }).generate(context);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png)).buffer.asUint8List();
  }

  void initPlatformState() async {
    LocationData myLocation;
    // List<Uint8List> _markerIcon;
    Uint8List _markerIcon;
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

    // _markerIcon[0] = await getBytesFromAsset('img/smile_pixel_art_emoticon_emoji_icon_189295.png', 100);
    // _markerIcon[1] = await getBytesFromAsset('img/smile_pixel_art_emoticon_emoji_icon_189295.png', 100);
    // _markerIcon[2] = await getBytesFromAsset('img/smile_pixel_art_emoticon_emoji_icon_189295.png', 100);
    _markerIcon = await getBytesFromAsset('img/gomi1.png', 200);


    setState(() {
      print('currentLocation.........$currentLocation');
      currentLocation = myLocation;
      markerIcon = _markerIcon;
    });
  }

  // Completer<GoogleMapController> _googleMapsController = Completer();
  final Completer<GoogleMapController> _googleMapController =
      Completer<GoogleMapController>();

  static const CameraPosition _initCameraPosition =
      CameraPosition(target: LatLng(34.6870728, 135.0490244), zoom: 5.0);

  GoogleMapController mapController;
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  List<Marker> customMarkers = [];

  List<Marker> mapBitmapsToMarkers(List<Uint8List> bitmaps) {
    // bitmaps.asMap().forEach((mid, bmp) {
    //   customMarkers.add(Marker(
    //     markerId: MarkerId("$mid"),
    //     position: LatLng(35.6809591, 139.7673068),
    //     icon: BitmapDescriptor.fromBytes(bmp),
    //   ));
    // });
    customMarkers.add(Marker(
      markerId: MarkerId("1"),
      position: LatLng(37.787571077847666, -122.40369712328372),
      icon: BitmapDescriptor.fromBytes(markerIcon),
    ));
    customMarkers.add(Marker(
      markerId: MarkerId("2"),
      position: LatLng(37.78795463554173, -122.40514211411937),
      icon: BitmapDescriptor.fromBytes(markerIcon),
    ));
    customMarkers.add(Marker(
      markerId: MarkerId("3"),
      position: LatLng(37.786643219920165, -122.40484233040442),
      icon: BitmapDescriptor.fromBytes(markerIcon),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (Provider.of<Data>(context, listen: false).mappingDataList != null &&
        Provider.of<Data>(context, listen: false).mappingDataList.length != 0) {
      // getLatLng(Provider.of<Data>(context, listen: false).imgPathList);
      var data = Provider.of<Data>(context, listen: false);
    }

    if (currentLocation == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          // title: Text(
          //   Provider.of<Data>(context, listen: false).imgPath != null
          //       ? Provider.of<Data>(context, listen: false).imgPath
          //       : 'からぽ',
          // ),
          title: Text(widget.title),
        ),
        body: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentLocation.latitude, currentLocation.longitude),
              zoom: 17.0,
            ),
          markers: customMarkers.toSet(),
          myLocationEnabled: true,
          onMapCreated: _onMapCreated,
        ),
        // GoogleMap(
        //   mapType: MapType.normal,
        //   initialCameraPosition: CameraPosition(
        //     target: LatLng(currentLocation.latitude, currentLocation.longitude),
        //     zoom: 17.0,
        //   ),
        //   myLocationEnabled: true,
        //   onMapCreated: _onMapCreated,
        // ),
        floatingActionButton: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 30.0, bottom: 10.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (context) {
                    //   return TakePictureScreen(camera: widget.cameras.first);
                    // }));

                    // カスタムマーカーのテスト用
                    Provider.of<Data>(context, listen: false).setMappingData(
                        "img/smile_pixel_art_emoticon_emoji_icon_189295.png",
                        "35.6809591, 139.7673068");
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
