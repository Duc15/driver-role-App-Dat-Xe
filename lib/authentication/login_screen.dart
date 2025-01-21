import 'package:camera/camera.dart';
import 'package:drivers_app/authentication/signup_screen.dart';
import 'package:drivers_app/pages/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const LoginScreen({super.key, required this.cameras});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;
  bool _isPasswordVisible = false;

  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    if (_formKey.currentState?.validate() ?? false) {
      signInUser();
    }
  }

  signInUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Đang đăng nhập..."),
    );

    final User? userFirebase = (await FirebaseAuth.instance
            .signInWithEmailAndPassword(
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

    if (userFirebase != null) {
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(userFirebase.uid);
      usersRef.once().then((snap) {
        if (snap.snapshot.value != null) {
          if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
            //userName = (snap.snapshot.value as Map)["name"];
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => const Dashboard()));
          } else {
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar(
                "Bạn đã bị chặn. Vui lòng liên hệ admin: pm02duc@gmail.com để được mở chặn",
                context);
          }
        } else {
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar("Hãy đăng ký trước", context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Image.asset("assets/images/uberexec.png", width: 220),

              const SizedBox(height: 30),

              const Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email field
                      TextFormField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: const TextStyle(fontSize: 14),
                          errorText: _emailError,
                          prefixIcon:
                              const Icon(Icons.email, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          } else if (!value.contains("@")) {
                            return 'Nhập 1 email hợp lệ!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // Password field
                      TextFormField(
                        controller: passwordTextEditingController,
                        obscureText: !_isPasswordVisible,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Mật khẩu",
                          labelStyle: const TextStyle(fontSize: 14),
                          errorText: _passwordError,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          } else if (value.trim().length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      ElevatedButton(
                        onPressed: checkIfNetworkIsAvailable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Đăng nhập",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TextButton
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => SignUpScreen(cameras: widget.cameras),
                    ),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Bạn chưa có tài khoản? ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    children: [
                      TextSpan(
                        text: "Đăng ký ngay!",
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
      ),
    );
  }
}
