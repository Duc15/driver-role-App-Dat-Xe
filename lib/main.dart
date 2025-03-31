import 'package:camera/camera.dart';
import 'package:drivers_app/pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'authentication/login_screen.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Yêu cầu quyền location
  if (await Permission.locationWhenInUse.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  // Yêu cầu quyền notification
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  try {
    // Lấy danh sách camera trên thiết bị
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Lỗi khi khởi tạo camera: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drivers App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Chờ quá trình đăng nhập hoàn thành
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Kiểm tra người dùng đã đăng nhập hay chưa
          if (snapshot.hasData) {
            return const Dashboard();
          }
          return LoginScreen(
            cameras: cameras,
          );
        },
      ),
    );
  }
}
