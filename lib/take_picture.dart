import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

                      // ③画像を表示する画面に遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayPictureScreen(
                            // Pass the automatically generated path to
                            // the DisplayPictureScreen widget.
                            tmpImagePath: image.path,
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

  const DisplayPictureScreen({Key key, @required this.tmpImagePath})
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

                  //ふたつ前の画面に戻る
                  int count = 0;
                  Navigator.popUntil(context, (_) => count++ >= 2);

                },
              ))
            ])));
  }
}
