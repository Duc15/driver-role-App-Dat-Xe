import 'package:flutter/material.dart';

class CMNDDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> cmndData;

  CMNDDetailsScreen({required this.cmndData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông Tin CMND'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tên: ${cmndData['name']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ngày sinh: ${cmndData['dob']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Giới tính: ${cmndData['sex']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Quốc gia: ${cmndData['nationality']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Quay lại màn trước
              },
              child: Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}
