import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:drivers_app/sinh_trac_hoc/quet_cmnd/cmnd_details.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class CMNDRecognitionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CMNDRecognitionScreen({super.key, required this.cameras});

  @override
  _CMNDRecognitionScreenState createState() => _CMNDRecognitionScreenState();
}

class _CMNDRecognitionScreenState extends State<CMNDRecognitionScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
    );

    _cameraController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    });
  }

  Future<void> _captureImage() async {
    try {
      final image = await _cameraController.takePicture();
      setState(() => _capturedImage = File(image.path));

      // Tự động quét CMND sau khi chụp ảnh
      await _scanCMND();
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _scanCMND() async {
    if (_capturedImage == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.fpt.ai/vision/idr/vnm'),
    );
    request.headers['api-key'] = 'zJgN86n7LhUxANXif1XtGpTLCIXpLFLy';
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _capturedImage!.path,
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

        if (jsonResponse['errorCode'] == 0 && jsonResponse['data'] != null) {
          final Map<String, dynamic> cmndData = jsonResponse['data'][0];

          // Điều hướng đến màn hình mới với thông tin CMND
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CMNDDetailsScreen(
                cmndData: cmndData,
              ),
            ),
          );
        } else {
          print('Không tìm thấy dữ liệu hợp lệ.');
        }
      } else {
        print('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét CMND'),
      ),
      body: Column(
        children: [
          if (_isCameraInitialized)
            AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          if (_capturedImage != null)
            Image.file(
              _capturedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _captureImage,
                child: const Text('Chụp Ảnh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
