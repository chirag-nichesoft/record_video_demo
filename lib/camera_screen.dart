import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;


class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  List<CameraDescription> _cameras;
  CameraController _controller;
  int _cameraIndex;
  bool _isRecording = false;
  String _filePath;
  static int filename = 0;
  Timer timer;
  String foldername;

  @override
  Future<void> initState() {
    super.initState();
    print("------------------------------------------------------------------------->initState 25");
    availableCameras().then((cameras) {
      _cameras = cameras;
      if (_cameras.length != 0) {
        _cameraIndex = 0;
        _initCamera(_cameras[_cameraIndex]);
      }
    });
    findFolderName();
  }
  Future<void> findFolderName() async
  {
    String _foldername = await folderName();
    setState(() {
      foldername =_foldername;
    });
    print("*************************$foldername");

  }
  /*@override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }*/

  _initCamera(CameraDescription camera) async {
    print("------------------------------------------------------------------------->init camera 39");
    if (_controller != null) await _controller.dispose();
    _controller = CameraController(camera, ResolutionPreset.high);
    _controller.addListener(() => this.setState(() {}));
    _controller.initialize();
  }

  Widget _buildCamera() {
    print("------------------------------------------------------------------------->buildCamera 47");
    if (_controller == null || !_controller.value.isInitialized)
      return Center(child: Text('Loading...'));
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: CameraPreview(_controller),
    );
  }

  Widget _buildControls() {
    print("------------------------------------------------------------------------->build controlles 57");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(_getCameraIcon(_cameras[_cameraIndex].lensDirection)),
          onPressed: _onSwitchCamera,
        ),
        IconButton(
          icon: Icon(Icons.radio_button_checked),
          // onPressed: _isRecording ? null : _onRecord,
          onPressed: _onPrepareForRecord,
        ),
        IconButton(
          icon: Icon(Icons.stop),
          onPressed: _isRecording ? _onStop : null,
        ),
        IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: _isRecording ? null : _onPlay,
        ),
      ],
    );
  }

  void _onPlay() => OpenFile.open(_filePath);

  Future<void> _onStop() async {
    print("------------------------------------------------------------------------->onStop 84");
    await _controller.stopVideoRecording();
    int uploadFileIndex=filename-1;
    var directory = await getExternalStorageDirectory();
    String _filePath = directory.path + '/'+uploadFileIndex.toString()+'.mp4';
    //timer.cancel();
    setState(() => _isRecording = false);
    uploadFileFromGallery(_filePath);
  }
  _onPrepareForRecord()
  {
    timer = Timer.periodic(Duration(seconds: 15), (Timer t) => _onRecord());
    Timer.periodic(Duration(seconds: 15), (Timer t) => _onStop());
  }

  Future<void> _onRecord() async {
    print("------------------------------------------------------------------------->onRecord 90");
    // timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _onRecord());
    var directory = await getExternalStorageDirectory();
    // _filePath = directory.path + '/chirag/${DateTime.now()}.mp4';
    // _filePath = directory.path + '/${DateTime.now()}.mp4';
    _filePath = directory.path + '/'+filename.toString()+'.mp4';
    setState(() {
      filename++;
    });
    //String s = await _getPathToDownload();
    // _filePath =  s + '/${DateTime.now()}.mp4';
    print("file path is -> $_filePath");
    //print("file path is -> ${directory.absolute} ");
    _controller.startVideoRecording(_filePath);
    setState(() => _isRecording = true);

    print("-----------after recording----------");


    /*sleep1();
    _onRecord();*/


  }

  IconData _getCameraIcon(CameraLensDirection lensDirection) {
    print("------------------------------------------------------------------------->Icon data 113");
    return lensDirection == CameraLensDirection.back
        ? Icons.camera_front
        : Icons.camera_rear;
  }

  void _onSwitchCamera() {
    print("------------------------------------------------------------------------->SwitchCamera 120");
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % 2;
    _initCamera(_cameras[_cameraIndex]);
  }

  Future sleep1() {
    return new Future.delayed(const Duration(seconds: 10), () => "1");
  }

  Future<Response> uploadFileFromGallery(String path) async {
    String key = foldername+'/'+filename.toString()+".mp4";
    var url = 'https://ace-upload-sessionvideo.s3.ap-south-1.amazonaws.com/';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('file', path));
    request.fields.addAll({'key': key, 'acl': 'public-read'});
    print("key name is ====================================================== $key");
    var response = await request.send();
    if (response.statusCode == 200) {
      print('Uploaded!' + response.toString());
    }
    print('not Uploaded!  ' + response.reasonPhrase);
  }

  Future<String> folderName() async {
    String url = 'http://15.207.69.157:8080/ace/session/create/emailId1@email.one';
    Map mapJson = {
      "id": null,
      "title": "title9",
      "playerName": "player9",
      "opponentName": "player2",
      "matchType": "SINGLES",
      "surfaceType": "GRASS",
      "sport": "TENNIS"
    };
    var body = json.encode(mapJson);
    http.Response response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: body
    );
    if (response.statusCode != 200) {
      return null;
    }
    Map<String,dynamic> strResponse = convert.jsonDecode(response.body);
    String folderName = strResponse['id'];
    return folderName;
  }

  @override
  Widget build(BuildContext context) {
    print("------------------------------------------------------------------------->weidgrtBuild 130");
    return Scaffold(
      appBar: AppBar(title: Text('Video recording with Flutter')),
      body: Column(children: [
        Container(height: 500, child: Center(child: _buildCamera())),
        _buildControls(),
      ]),
    );
  }
}
