import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
//import 'package:google_ml_kit/google_ml_kit.dart';

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
  final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.8);
  ImageLabeler? _imageLabeler;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageLabeler = ImageLabeler(options: options);
  }

  void _getImageAndDetectObjects(ImageSource source) async {
    final PickedFile? pickedImage = await _picker.getImage(source: source);
    if (pickedImage != null) {
      final inputImage = InputImage.fromFilePath(pickedImage.path);
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

      setState(() {
        _imageFile = File(pickedImage.path);
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