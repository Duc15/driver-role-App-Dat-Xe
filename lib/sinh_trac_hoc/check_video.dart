import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart'; // Đảm bảo đã thêm firebase_database vào pubspec.yaml
import 'package:drivers_app/main.dart';
import 'package:drivers_app/sinh_trac_hoc/result.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LiveVideoCheck extends StatelessWidget {
  final String imagePath; // Đường dẫn ảnh CMND đã chọn
  final String userId;
  final Map<String, dynamic> cmndData;
  const LiveVideoCheck(
      {super.key,
      required this.imagePath,
      required this.userId,
      required this.cmndData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Liveness Check',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FaceVerificationScreen(
        imagePath: imagePath,
        userId: userId,
        cmndData: cmndData,
      ),
    );
  }
}

class FaceVerificationScreen extends StatefulWidget {
  final String imagePath; // Nhận đường dẫn ảnh CMND
  final String userId;
  final Map<String, dynamic> cmndData;
  const FaceVerificationScreen(
      {super.key,
      required this.imagePath,
      required this.userId,
      required this.cmndData});

  @override
  _FaceVerificationScreenState createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  File? _recordedVideo;
  bool _isLoading = false;
  int _timerSeconds = 5; // Số giây đếm ngược
  Timer? _timer; // Để điều khiển bộ đếm giây

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print("Đang khởi tạo camera...");
    _cameraController = CameraController(
      cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
    );

    await _cameraController?.initialize();
    print("Camera đã được khởi tạo.");
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (_cameraController?.value.isInitialized ?? false) {
      print("Bắt đầu quay video...");
      final directory = await getTemporaryDirectory();
      final videoPath = '${directory.path}/video.mp4';

      await _cameraController?.startVideoRecording();
      print("Đang quay video: $videoPath");

      _startTimer(); // Bắt đầu bộ đếm giây khi quay video

      await Future.delayed(Duration(seconds: 5)); // Quay video trong 5 giây
      final videoFile = await _cameraController?.stopVideoRecording();
      if (videoFile != null) {
        setState(() {
          _recordedVideo = File(videoFile.path);
        });
        print("Video đã được lưu tại: ${_recordedVideo!.path}");
        // Hiển thị thông báo sau khi quay xong
        _showVideoCapturedDialog();
      }
    }
  }

  void _startTimer() {
    // Bắt đầu bộ đếm giây
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
        });
      } else {
        _timer?.cancel(); // Dừng bộ đếm khi hết thời gian
      }
    });
  }

  Future<void> _sendToApi() async {
    if (_recordedVideo != null) {
      setState(() {
        _isLoading = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.fpt.ai/dmp/liveness/v3'),
      );

      request.headers['api-key'] = '9t8Eixst0BZpJWv20nbRWR6P8Q8fiFMO';
      request.files.add(
          await http.MultipartFile.fromPath('video', _recordedVideo!.path));
      request.files.add(await http.MultipartFile.fromPath(
          'cmnd', widget.imagePath)); // Sử dụng ảnh CMND đã chọn từ bộ nhớ đệm

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print("Kết quả API: $responseData");

        // Parse JSON và xử lý kết quả
        final result = jsonDecode(responseData);
        final isMatch = result['face_match']['isMatch'] == 'true';
        final similarity = result['face_match']['similarity'];
        final isLive = result['liveness']['is_live'] == 'true';

        if (isMatch) {
          // Điều hướng tới màn hình Success
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                similarity: similarity,
                isMatch: isMatch,
                isLive: isLive,
                userId: widget.userId,
              ),
            ),
          );

          // Cập nhật thông tin người dùng lên Firebase
          _uploadUserInfoToFirebase();
        } else {
          // Hiển thị lỗi nếu không khớp
          _showDialog(
            context,
            "Xác thực không thành công",
            "Khuôn mặt không khớp. Vui lòng thử lại.",
          );
        }
      } else {
        _showDialog(
          context,
          "Lỗi",
          "Không thể gửi dữ liệu. Vui lòng thử lại.",
        );
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      _showDialog(
        context,
        "Thiếu dữ liệu",
        "Vui lòng quay video.",
      );
    }
  }

  // Hàm cập nhật thông tin lên Firebase
  Future<void> _uploadUserInfoToFirebase() async {
    // Thêm thông tin người dùng vào Firebase
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(widget.userId)
        .child('infoPersonal');

    // Tạo đối tượng thông tin người dùng
    Map<String, dynamic> userInfo = {
      'name': widget.cmndData['name'], // Thay bằng dữ liệu thực tế
      'dob': widget.cmndData['dob'], // Thay bằng dữ liệu thực tế
      'id': widget.cmndData['id'], // Thay bằng dữ liệu thực tế
      'address': widget.cmndData['address'], // Thay bằng dữ liệu thực tế
      'nationality':
          widget.cmndData['nationality'], // Thay bằng dữ liệu thực tế
      'sex': widget.cmndData['sex'],
      'expiry_date':
          widget.cmndData['expiry_date'], // Thay bằng dữ liệu thực tế
    };

    // Đẩy dữ liệu lên Firebase
    await userRef.set(userInfo).then((_) {
      print("Thông tin người dùng đã được cập nhật lên Firebase.");
    }).catchError((error) {
      print("Lỗi khi cập nhật thông tin người dùng: $error");
    });
  }

  void _showVideoCapturedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quay video thành công"),
        content: const Text(
            "Video đã được lưu tại: /var/mobile/Containers/Data/Application/ \n Để tiếp tục hãy chọn Xác minh hoặc Quay lại để quay lại video"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Có thể quay lại quay video mới nếu muốn
              _startRecording(); // Hoặc xử lý khác
            },
            child: const Text("Quay lại"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Tiến hành xác minh
              _sendToApi();
            },
            child: const Text("Xác minh"),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel(); // Dừng bộ đếm khi dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác minh khuôn mặt"),
        centerTitle: true,
        leading:
            IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              if (_cameraController?.value.isInitialized ?? false)
                CameraPreview(_cameraController!),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              Positioned(
                top: 150, // Đặt bộ đếm giây ở giữa màn hình
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$_timerSeconds s',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _startRecording,
            child: const Text("Quay video"),
          ),
          ElevatedButton(
            onPressed: _sendToApi,
            child: const Text("Xác minh khuôn mặt"),
          ),
        ],
      ),
    );
  }
}
