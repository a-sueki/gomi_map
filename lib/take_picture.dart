import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

// カメラのリストと、イメージを保存するディレクトリーを取り入れるスクリーン。
class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // カメラからの情報を表示させるためのCameraControllerを生成
    _controller = CameraController(
      // main()で取得した特定のカメラを引数にとる。
      widget.camera,
      // 解像度を指定(low, medium, high, veryHigh, ultraHigh, max)
      ResolutionPreset.medium,
    );

    // cameracontrollerを初期化。Futureが返ってくる。
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Take a picture")),
      // カメラのプレビューを表示させる前にカメラコントローラーの初期化が完了するのを待たなければならない。
      // FutureBuilderを使用することで、コントローラの初期化が完了するまでローディング中のスピナーを表示させる。
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            //初期化が完了してない場合は、ローディングスピナーを表示させる。
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Center(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                // margin: EdgeInsets.only(left: 30.0, bottom: 10.0),
                child: FloatingActionButton.extended(
                  label: Text('撮影'),
                  tooltip: '撮影',
                  icon: Icon(Icons.camera),
                  onPressed: () async {
                    try {
                      // Controllerが初期化されていることを保証するための処理
                      await _initializeControllerFuture;

                      // 撮影
                      final image = await _controller.takePicture();

                      // 現在地を取得
                      await getLocation();

                      // ③画像を表示する画面に遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayPictureScreen(
                            // Pass the automatically generated path to
                            // the DisplayPictureScreen widget.
                            tmpImagePath: image.path,
                            location : _location,
                          ),
                        ),
                      );
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
              ),
            ]),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String tmpImagePath;
  final String location;

  const DisplayPictureScreen({Key key, @required this.tmpImagePath, this.location})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: Image.file(File(tmpImagePath)),
        floatingActionButton: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
              Container(
                  // margin: EdgeInsets.only(left: 30.0, bottom: 10.0),
                  child: FloatingActionButton.extended(
                label: Text('これでOK'),
                tooltip: 'OK',
                onPressed: () async{
                  // pathパッケージを使ってイメージが保存されるパスを構成する
                  final imagePath = join(
                      (await getApplicationDocumentsDirectory()).path,
                  '${DateTime.now()}.png',
                  );
                  // ローカルに保存
                  await File(imagePath).writeAsBytes(await File(tmpImagePath).readAsBytes());
                  print('imagePath============= $imagePath');

                  // 変数を格納
                  Provider.of<Data>(context, listen: false).setMappingData(imagePath,location);

                  //ふたつ前の画面に戻る
                  int count = 0;
                  Navigator.popUntil(context, (_) => count++ >= 2);

                },
              ))
            ])));
  }
}

class Data with ChangeNotifier {
  List<Map> mappingDataList = [];
  String imgPath = '';
  String location = '';
  String id;

  void setMappingData(path,location){

    this.imgPath = path;
    this.location = location;
    this.id = 'test';

    var mappingData = Map();

    mappingData['loc'] = this.location;
    mappingData['imgPath'] = this.imgPath;

    notifyListeners(); // 全てのリスナーに自身を再構築するよう通知する
  }


}



