

//
// import 'package:face_net_authentication/pages/widgets/signin_form.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:face_net_authentication/locator.dart';
// import 'package:face_net_authentication/pages/models/user.model.dart';
// import 'package:face_net_authentication/pages/widgets/auth_button.dart';
// import 'package:face_net_authentication/pages/widgets/camera_detection_preview.dart';
// import 'package:face_net_authentication/pages/widgets/camera_header.dart';
// import 'package:face_net_authentication/pages/widgets/single_picture.dart';
// import 'package:face_net_authentication/services/camera.service.dart';
// import 'package:face_net_authentication/services/ml_service.dart';
// import 'package:face_net_authentication/services/face_detector_service.dart';
//
// class SignIn extends StatefulWidget {
//   const SignIn({Key? key}) : super(key: key);
//
//   @override
//   SignInState createState() => SignInState();
// }
//
// class SignInState extends State<SignIn> {
//   CameraService _cameraService = locator<CameraService>();
//   FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();
//   MLService _mlService = locator<MLService>();
//
//   GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
//
//   bool _isPictureTaken = false;
//   bool _isInitializing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _start();
//   }
//
//   @override
//   void dispose() {
//     _cameraService.dispose();
//     _mlService.dispose();
//     _faceDetectorService.dispose();
//     super.dispose();
//   }
//
//   Future _start() async {
//     setState(() => _isInitializing = true);
//     await _cameraService.initialize();
//     setState(() => _isInitializing = false);
//     _frameFaces();
//   }
//
//   _frameFaces() async {
//     bool processing = false;
//     _cameraService.cameraController!
//         .startImageStream((CameraImage image) async {
//       if (processing) return; // Prevent unnecessary overprocessing.
//       processing = true;
//       await _predictFacesFromImage(image: image);
//       processing = false;
//     });
//   }
//
//   Future<void> _predictFacesFromImage({@required CameraImage? image}) async {
//     assert(image != null, 'Image is null');
//     await _faceDetectorService.detectFacesFromImage(image!);
//     if (_faceDetectorService.faceDetected) {
//       _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
//       print("Face Matches---------");
//       // Automatically take picture and sign in if face is detected
//       await takePicture();
//     }
//     if (mounted) setState(() {});
//   }
//
//   Future<void> takePicture() async {
//     if (_faceDetectorService.faceDetected) {
//       await _cameraService.takePicture();
//       setState(() => _isPictureTaken = true);
//       // Automatically sign in when picture is taken
//
//       await onTap();
//     } else {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(content: Text('No face detected!')),
//       );
//     }
//   }
//
//   _onBackPressed() {
//     Navigator.of(context).pop();
//   }
//
//   _reload() {
//     if (mounted) setState(() => _isPictureTaken = false);
//     _start();
//   }
//
//   Future<void> onTap() async {
//     if (_faceDetectorService.faceDetected) {
//       User? user = await _mlService.predict();
//       var bottomSheetController = scaffoldKey.currentState!
//           .showBottomSheet((context) => signInSheet(user: user));
//       bottomSheetController.closed.whenComplete(_reload);
//     }
//   }
//
//   Widget getBodyWidget() {
//     if (_isInitializing) return Center(child: CircularProgressIndicator());
//     if (_isPictureTaken)
//       return SinglePicture(imagePath: _cameraService.imagePath!);
//     return CameraDetectionPreview();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Widget header = CameraHeader("LOGIN", onBackPressed: _onBackPressed);
//     Widget body = getBodyWidget();
//     Widget? fab;
//     // if (!_isPictureTaken) fab = AuthButton(onTap: takePicture);
//
//     return Scaffold(
//       key: scaffoldKey,
//       body: Stack(
//         children: [body, header],
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       floatingActionButton: fab,
//     );
//   }
//
//   signInSheet({@required User? user}) => user == null
//       ? Container(
//     width: MediaQuery.of(context).size.width,
//     padding: EdgeInsets.all(20),
//     child: Text(
//       'User not found 😞',
//       style: TextStyle(fontSize: 20),
//     ),
//   )
//       : SignInSheet(user: user);
// }
import 'dart:async';
import 'package:face_net_authentication/pages/widgets/signin_form.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/widgets/auth_button.dart';
import 'package:face_net_authentication/pages/widgets/camera_detection_preview.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/pages/widgets/single_picture.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  CameraService _cameraService = locator<CameraService>();
  FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();
  MLService _mlService = locator<MLService>();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;

  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlService.dispose();
    _faceDetectorService.dispose();
    _timeoutTimer?.cancel(); // Cancel timer to avoid memory leaks
    super.dispose();
  }

  Future _start() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    setState(() => _isInitializing = false);
    _frameFaces();
  }

  _frameFaces() async {
    bool processing = false;
    _cameraService.cameraController!
        .startImageStream((CameraImage image) async {
      if (processing) return; // Prevent unnecessary overprocessing.
      processing = true;
      await _predictFacesFromImage(image: image);
      processing = false;
    });
  }

  Future<void> _predictFacesFromImage({@required CameraImage? image}) async {
    print("---------Image------------$image");
    assert(image != null, 'Image is null');
    await _faceDetectorService.detectFacesFromImage(image!);
    if (_faceDetectorService.faceDetected) {
      _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
      print("");
      // Automatically take picture and sign in if face is detected
      await takePicture();
    }
    if (mounted) setState(() {});
  }

  Future<void> takePicture() async {
    if (_faceDetectorService.faceDetected) {
      await _cameraService.takePicture();
      setState(() => _isPictureTaken = true);
      // Automatically sign in when picture is taken

      await onTap();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(content: Text('No face detected!')),
      );
      // Restart screen and camera after a delay if no face is detected
      _timeoutTimer = Timer(Duration(seconds: 10), ()=>
          showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text('No face detected!')),
          ) );
    }
  }

  void _restartScreenAndCamera() {
    if (mounted) {
      setState(() {
        _isPictureTaken = false;
        _start();
      });
    }
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }
  _reload() {
    if (mounted) setState(() => _isPictureTaken = false);
    _start();
  }
  Future<void> onTap() async {
    if (_faceDetectorService.faceDetected) {
      User? user = await _mlService.predict();
      var bottomSheetController = scaffoldKey.currentState!
          .showBottomSheet((context) => signInSheet(user: user));
      bottomSheetController.closed.whenComplete(_reload);
    }
  }

  Widget getBodyWidget() {
    if (_isInitializing) return Center(child: CircularProgressIndicator());
    if (_isPictureTaken)
      return SinglePicture(imagePath: _cameraService.imagePath!);
    return CameraDetectionPreview();
  }

  @override
  Widget build(BuildContext context) {
    Widget header = CameraHeader("LOGIN", onBackPressed: _onBackPressed);
    Widget body = getBodyWidget();
    Widget? fab;
    // if (!_isPictureTaken) fab = AuthButton(onTap: takePicture);

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [body, header],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: fab,
    );
  }

  signInSheet({@required User? user}) => user == null
      ? Container(
    width: MediaQuery.of(context).size.width,
    padding: EdgeInsets.all(20),
    child: Text(
      'User not found 😞',
      style: TextStyle(fontSize: 20),
    ),
  )
      : SignInSheet(user: user);
}
