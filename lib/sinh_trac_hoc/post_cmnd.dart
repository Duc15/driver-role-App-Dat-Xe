// import 'dart:convert';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:drivers_app/sinh_trac_hoc/check_video.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;

// class UploadCMNDScreen extends StatefulWidget {
//   final String userId;
//   final List<CameraDescription> cameras;

//   const UploadCMNDScreen({
//     Key? key,
//     required this.userId,
//     required this.cameras,
//   }) : super(key: key);

//   @override
//   _UploadCMNDScreenState createState() => _UploadCMNDScreenState();
// }

// class _UploadCMNDScreenState extends State<UploadCMNDScreen> {
//   File? _selectedImage;
//   Map<String, dynamic>? _cmndData;
//   bool _isLoading = false; // Flag to track loading state

//   Future<void> _pickImage() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _selectedImage = File(result.files.single.path!);
//       });

//       final directory = await getTemporaryDirectory();
//       final tempPath = '${directory.path}/temp_cmnd.jpg';
//       await _selectedImage?.copy(tempPath);

//       print("Ảnh CMND đã lưu tạm tại: $tempPath");
//     } else {
//       _showErrorDialog("Không có ảnh được chọn.");
//     }
//   }

//   Future<void> _scanCMND() async {
//     if (_selectedImage == null) {
//       _showErrorDialog("Vui lòng chọn ảnh CMND.");
//       return;
//     }

//     // Show loading dialog with a message
//     setState(() {
//       _isLoading = true; // Set loading state to true
//     });
//     _showLoadingDialog();

//     final request = http.MultipartRequest(
//       'POST',
//       Uri.parse('https://api.fpt.ai/vision/idr/vnm'),
//     );
//     request.headers['api-key'] = 'zJgN86n7LhUxANXif1XtGpTLCIXpLFLy';
//     request.files.add(await http.MultipartFile.fromPath(
//       'image',
//       _selectedImage!.path,
//     ));

//     try {
//       final response = await request.send();
//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

//         if (jsonResponse['errorCode'] == 0 && jsonResponse['data'] != null) {
//           setState(() {
//             _cmndData = jsonResponse['data'][0];
//           });
//           print('Dữ liệu CMND: $_cmndData');
//         } else {
//           _showErrorDialog('Không tìm thấy dữ liệu hợp lệ.');
//         }
//       } else {
//         _showErrorDialog('Lỗi API: ${response.statusCode}');
//       }
//     } catch (e) {
//       _showErrorDialog('Lỗi kết nối: $e');
//     } finally {
//       // Dismiss loading dialog
//       if (mounted) {
//         setState(() {
//           _isLoading = false; // Set loading state to false
//         });
//         Navigator.of(context).pop(); // Close the loading dialog
//       }
//     }
//   }

//   void _goToLiveVideoCheck() async {
//     if (_selectedImage != null) {
//       await _scanCMND();
//       if (_cmndData != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => LiveVideoCheck(
//               imagePath: _selectedImage!.path,
//               userId: widget.userId,
//               cmndData: _cmndData!,
//             ),
//           ),
//         );
//       } else {
//         _showErrorDialog("Vui lòng tải lên ảnh chứng minh nhân dân hợp lệ !");
//       }
//     } else {
//       _showErrorDialog("Vui lòng chọn ảnh CMND trước.");
//     }
//   }

//   // Function to show error dialog
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Lỗi"),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               child: const Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 // Dismiss the loading dialog if it is still showing
//                 if (_isLoading) {
//                   Navigator.of(context).pop();
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to show loading dialog with a message
//   void _showLoadingDialog() {
//     if (_isLoading) {
//       // Only show the loading dialog if it's loading
//       showDialog(
//         context: context,
//         barrierDismissible:
//             false, // Prevent dismissing the dialog by tapping outside
//         builder: (BuildContext context) {
//           return Dialog(
//             backgroundColor: Colors.transparent,
//             child: Center(
//               child: Container(
//                 padding: const EdgeInsets.all(20.0),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(), // Add spinning circle for progress
//                     SizedBox(height: 15),
//                     Text("Đang kiểm tra ảnh chứng minh nhân dân",
//                         style: TextStyle(fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Chọn ảnh CMND")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (_selectedImage != null)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 20.0),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8.0),
//                     child: Image.file(_selectedImage!),
//                   ),
//                 ),
//               ElevatedButton(
//                 onPressed: _pickImage,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.blueAccent,
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child:
//                     const Text("Chọn ảnh CMND", style: TextStyle(fontSize: 16)),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _goToLiveVideoCheck,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: Colors.greenAccent,
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text("Bắt đầu xác minh",
//                     style: TextStyle(fontSize: 16)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:drivers_app/sinh_trac_hoc/check_video.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class UploadCMNDScreen extends StatefulWidget {
  final String userId;
  final List<CameraDescription> cameras;

  const UploadCMNDScreen({
    Key? key,
    required this.userId,
    required this.cameras,
  }) : super(key: key);

  @override
  _UploadCMNDScreenState createState() => _UploadCMNDScreenState();
}

class _UploadCMNDScreenState extends State<UploadCMNDScreen> {
  File? _selectedImageFront; // Ảnh mặt trước CMND
  File? _selectedImageBack; // Ảnh mặt sau CMND
  Map<String, dynamic>? _cmndData;
  bool _isLoading = false;

  Future<void> _pickImageFront() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImageFront = File(result.files.single.path!);
      });

      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/temp_cmnd_front.jpg';
      await _selectedImageFront?.copy(tempPath);

      print("Ảnh CMND mặt trước đã lưu tạm tại: $tempPath");
    } else {
      _showErrorDialog("Không có ảnh được chọn.");
    }
  }

  Future<void> _pickImageBack() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImageBack = File(result.files.single.path!);
      });

      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/temp_cmnd_back.jpg';
      await _selectedImageBack?.copy(tempPath);

      print("Ảnh CMND mặt sau đã lưu tạm tại: $tempPath");
    } else {
      _showErrorDialog("Không có ảnh được chọn.");
    }
  }

  Future<void> _scanCMND() async {
    if (_selectedImageFront == null) {
      _showErrorDialog("Vui lòng chọn ảnh CMND mặt trước.");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _showLoadingDialog();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.fpt.ai/vision/idr/vnm'),
    );
    request.headers['api-key'] = '9t8Eixst0BZpJWv20nbRWR6P8Q8fiFMO';
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _selectedImageFront!.path,
    ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

        if (jsonResponse['errorCode'] == 0 && jsonResponse['data'] != null) {
          setState(() {
            _cmndData = jsonResponse['data'][0];
          });
          print('Dữ liệu CMND: $_cmndData');
        } else {
          _showErrorDialog('Không tìm thấy dữ liệu hợp lệ.');
        }
      } else {
        _showErrorDialog('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Lỗi kết nối: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  void _goToLiveVideoCheck() async {
    if (_selectedImageFront != null) {
      await _scanCMND();
      if (_cmndData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveVideoCheck(
              imagePath: _selectedImageFront!.path,
              userId: widget.userId,
              cmndData: _cmndData!,
            ),
          ),
        );
      } else {
        _showErrorDialog("Vui lòng tải lên ảnh CMND mặt trước hợp lệ!");
      }
    } else {
      _showErrorDialog("Vui lòng chọn ảnh CMND trước.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Lỗi"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                if (_isLoading) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 15),
                  const Text(
                    "Đang kiểm tra ảnh chứng minh nhân dân...",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = false;
                      });
                      Navigator.of(context).pop(); // Đóng hộp thoại
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Hủy bỏ"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tải lên ảnh CMND")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_selectedImageFront != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(_selectedImageFront!),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _pickImageFront,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Chọn ảnh CMND mặt trước",
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
                if (_selectedImageBack != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(_selectedImageBack!),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _pickImageBack,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Chọn ảnh CMND mặt sau",
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _goToLiveVideoCheck,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Bắt đầu xác minh",
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
