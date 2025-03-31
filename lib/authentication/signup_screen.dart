import 'dart:io';
import 'package:camera/camera.dart';
import 'package:drivers_app/authentication/ask_for_info.dart';
import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SignUpScreen({super.key, required this.cameras});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController =
      TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController vehicleModelTextEditingController =
      TextEditingController();
  TextEditingController vehicleColorTextEditingController =
      TextEditingController();
  TextEditingController vehicleNumberTextEditingController =
      TextEditingController();
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";
  bool _isPasswordVisible = false; // For password visibility toggle

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);

    if (_formKey.currentState!.validate() && imageFile != null) {
      uploadImageToStorage();
    } else {
      cMethods.displaySnackBar("Bạn quên chọn hình ảnh rồi!.", context);
    }
  }

  signUpFormValidation() {
    if (userNameTextEditingController.text.trim().length < 3) {
      return "Tên của bạn phải có ít nhất 4 ký tự";
    } else if (userPhoneTextEditingController.text.trim().length < 9) {
      return "Số điện thoại phải có ít nhất 10 ký tự!";
    } else if (!emailTextEditingController.text.contains("@")) {
      return "Hãy điền 1 email hợp lệ!";
    } else if (passwordTextEditingController.text.trim().length < 5) {
      return "Mật khẩu phải có ít nhất 6 ký tự!";
    } else if (vehicleModelTextEditingController.text.trim().isEmpty) {
      return "Điền thông tin xe của bạn!";
    } else if (vehicleColorTextEditingController.text.trim().isEmpty) {
      return "Điền màu xe!!!";
    } else if (vehicleNumberTextEditingController.text.isEmpty) {
      return "Điền mã số xe!!!";
    }
    return null;
  }

  uploadImageToStorage() async {
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage =
        FirebaseStorage.instance.ref().child("Images").child(imageIDName);

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path));
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() {
      urlOfUploadedImage;
    });

    registerNewDriver();
  }

  registerNewDriver() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Đăng ký tài khoản"),
    );

    final User? userFirebase = (await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
      email: emailTextEditingController.text.trim(),
      password: passwordTextEditingController.text.trim(),
    )
            .catchError((errorMsg) {
      Navigator.pop(context);
      cMethods.displaySnackBar(errorMsg.toString(), context);
    }))
        .user;

    if (!context.mounted) return;
    Navigator.pop(context);

    DatabaseReference usersRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(userFirebase!.uid);

    Map driverCarInfo = {
      "carColor": vehicleColorTextEditingController.text.trim(),
      "carModel": vehicleModelTextEditingController.text.trim(),
      "carNumber": vehicleNumberTextEditingController.text.trim(),
    };

    Map driverDataMap = {
      "photo": urlOfUploadedImage,
      "car_details": driverCarInfo,
      "name": userNameTextEditingController.text.trim(),
      "email": emailTextEditingController.text.trim(),
      "phone": userPhoneTextEditingController.text.trim(),
      "id": userFirebase.uid,
      "blockStatus": "no",
      "ratings": "0.0",
      "isVerified": false, // Thêm trạng thái xác thực
    };

    usersRef.set(driverDataMap);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => SuccessScreen(
          cameras: widget.cameras,
          userId: userFirebase.uid, // Pass user ID to SuccessScreen
        ),
      ),
    );
  }

  chooseImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                imageFile == null
                    ? const CircleAvatar(
                        radius: 86,
                        backgroundImage:
                            AssetImage("assets/images/avatarman.png"),
                      )
                    : Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                          image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            image: FileImage(File(imageFile!.path)),
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: chooseImageFromGallery,
                  child: const Text(
                    "Chọn ảnh",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      // User Name Field
                      TextFormField(
                        controller: userNameTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Tên của bạn",
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.person, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 3) {
                            return "Tên của bạn phải có ít nhất 4 ký tự";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Phone Number Field
                      TextFormField(
                        controller: userPhoneTextEditingController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Số điện thoại",
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.phone, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 10) {
                            return "Số điện thoại phải có ít nhất 10 ký tự";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email Field
                      TextFormField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains("@")) {
                            return "Hãy điền 1 email hợp lệ!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password Field
                      TextFormField(
                        controller: passwordTextEditingController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Mật khẩu",
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 6) {
                            return "Mật khẩu phải có ít nhất 6 ký tự!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Vehicle Model Field
                      TextFormField(
                        controller: vehicleModelTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Mẫu xe của bạn",
                          labelStyle: const TextStyle(fontSize: 14),
                          hintText: "BMW-i8",
                          prefixIcon: const Icon(Icons.directions_car,
                              color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Điền thông tin xe của bạn!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Vehicle Color Field
                      TextFormField(
                        controller: vehicleColorTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Màu xe",
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.color_lens, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Điền màu xe!!!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Vehicle Number Field
                      TextFormField(
                        controller: vehicleNumberTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Biển số xe",
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.numbers, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Điền mã số xe!!!";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Register Button
                      ElevatedButton(
                        onPressed: checkIfNetworkIsAvailable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Đăng ký",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (c) => LoginScreen(
                                      cameras: cameras,
                                    )),
                          );
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: "Bạn đã có tài khoản? ",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            children: [
                              TextSpan(
                                text: "Đăng nhập ngay!",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
