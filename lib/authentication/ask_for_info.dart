import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:drivers_app/sinh_trac_hoc/post_cmnd.dart';

class SuccessScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String userId;

  const SuccessScreen({
    super.key,
    required this.cameras,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 140),
            const Icon(Icons.check_circle, color: Colors.green, size: 120),
            const SizedBox(height: 24),
            const Text(
              "Đăng ký thành công!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Hãy bắt đầu xác minh danh tính để tiếp tục sử dụng ứng dụng.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadCMNDScreen(
                      userId: userId,
                      cameras: cameras,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                "Bắt đầu xác minh danh tính",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
