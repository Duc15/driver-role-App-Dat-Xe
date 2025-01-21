import 'package:drivers_app/main.dart';
import 'package:drivers_app/pages/dashboard.dart';

import 'package:drivers_app/sinh_trac_hoc/post_cmnd.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final bool isMatch;
  final String similarity;
  final bool isLive;
  final String userId;
  ResultScreen({
    required this.isMatch,
    required this.similarity,
    required this.isLive,
    required this.userId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    // TODO: implement initState
    _updateVerificationStatus(widget.userId);
    super.initState();
  }

  void _updateVerificationStatus(String userId) {
    DatabaseReference usersRef =
        FirebaseDatabase.instance.ref().child("drivers").child(userId);
    usersRef.update({"isVerified": true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả kiểm tra'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.isMatch ? Icons.check_circle : Icons.error,
              size: 100,
              color: widget.isMatch ? Colors.green : Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              widget.isMatch
                  ? "Khuôn mặt trùng khớp!"
                  : "Khuôn mặt không trùng khớp!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isMatch ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              "Độ giống nhau: ${widget.similarity}%",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isLive ? Icons.verified : Icons.warning,
                  color: widget.isLive ? Colors.green : Colors.red,
                  size: 30,
                ),
                SizedBox(width: 8),
                Text(
                  widget.isLive
                      ? "Người thật được xác nhận!"
                      : "Không phát hiện người thật!",
                  style: TextStyle(
                    fontSize: 18,
                    color: widget.isLive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (widget.isMatch) {
                  _updateVerificationStatus(widget.userId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const Dashboard()),
                  );
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => UploadCMNDScreen(
                                userId: widget.userId,
                                cameras: cameras,
                              )));
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                widget.isMatch ? "Tiếp tục sử dụng ứng dụng" : "Thử lại",
                //  "Tiếp tục sử dụng ứng dụng",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
