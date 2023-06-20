import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'dart:io' as io;
import 'package:flutter/services.dart';

//import 'package:google_ml_kit/google_ml_kit.dart';


Future<String> _getModel(String assetPath) async {
  if (io.Platform.isAndroid) {
    return 'flutter_assets/$assetPath';
  }
  final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
  await io.Directory(dirname(path)).create(recursive: true);
  final file = io.File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(assetPath);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ObjectDetection(),
    );
  }
}

class ObjectDetection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  File? _imageFile;
  String? _result;
  String? modelPath;
  ImageLabeler? _imageLabeler;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getModelAndStartImageLabeler();
  }

  void _getModelAndStartImageLabeler() async {
    modelPath = await _getModel('assets/model.tflite');
    if (modelPath != null) {
      final options = LocalLabelerOptions(modelPath: modelPath!, confidenceThreshold: 0.7);
      _imageLabeler = ImageLabeler(options: options);
    }
  }

  void _getImageAndDetectObjects(ImageSource source) async {
    final PickedFile? pickedImage = await _picker.getImage(source: source);
    if (pickedImage != null) {
      // 元の画像ファイルを保存
      File originalImageFile = File(pickedImage.path);

      // 画像をリサイズ
      final Uint8List? compressedImage = await FlutterImageCompress.compressWithFile(
        pickedImage.path,
        minWidth: 400,
        minHeight: 300,
      );

      // リサイズした画像を一時的なファイルに保存
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/temp.jpg';
      File file = File(path)..writeAsBytesSync(compressedImage!);

      // 一時的なファイルのパスを使用して入力画像を作成
      final inputImage = InputImage.fromFilePath(file.path);
      final List<ImageLabel> labels = await _imageLabeler?.processImage(inputImage) ?? [];

      ImageLabel? highestConfidenceLabel;
      for (final label in labels) {
        if (label.confidence > 0.7 && (highestConfidenceLabel == null || label.confidence > highestConfidenceLabel.confidence)) {
          highestConfidenceLabel = label;
        }
      }

      String result;
      if (highestConfidenceLabel != null) {
        final confidenceInPercent = (highestConfidenceLabel.confidence * 100).toStringAsFixed(1);
        result = 'Label: ${highestConfidenceLabel.label}, Confidence: $confidenceInPercent%';
      } else {
        result = "Can't detect";
      }

      // 結果の更新
      setState(() {
        _imageFile = originalImageFile;  // 元の画像を使用
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Object Detection'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _imageFile == null
                ? Container()
                : Image.file(_imageFile!),
            SizedBox(height: 10),
            _result == null
                ? Container()
                : Text('Detected Objects:\n$_result'),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              onPressed:(){_getImageAndDetectObjects(ImageSource.gallery);} ,
              tooltip: "Select Image",
              child: Icon(Icons.add_photo_alternate),
            ),
            Padding(padding: EdgeInsets.all(10.0)),
            FloatingActionButton(
              onPressed:(){_getImageAndDetectObjects(ImageSource.camera);} ,
              tooltip: "Take Photo",
              child: Icon(Icons.add_a_photo),
            ),
          ],
        )
    );
  }

  @override
  void dispose() {
    _imageLabeler?.close();
    super.dispose();
  }
}
