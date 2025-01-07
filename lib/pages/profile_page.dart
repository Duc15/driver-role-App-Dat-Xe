import 'package:drivers_app/global/global_var.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance
      .ref()
      .child('drivers')
      .child(FirebaseAuth.instance.currentUser!.uid)
      .child('ratings');
  String _ratings = "Loading...";
  String _address = "Loading...";
  String _dob = "Loading...";
  bool isVerified = false; // Track verification status

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController carTextEditingController = TextEditingController();

  String currentDriverTotalTripsCompleted = "0";

  void setDriverInfo() {
    setState(() {
      nameTextEditingController.text = driverName;
      phoneTextEditingController.text = driverPhone;
      emailTextEditingController.text =
          FirebaseAuth.instance.currentUser!.email.toString();
      carTextEditingController.text = "$carNumber - $carColor - $carModel";
    });
  }

  void _fetchRatings() async {
    DatabaseEvent event = await _databaseReference.once();
    setState(() {
      _ratings = event.snapshot.value.toString();
    });
  }

  Future<void> _fetchAddress() async {
    DatabaseReference addressRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("infoPersonal")
        .child("address");

    DatabaseEvent event = await addressRef.once();
    setState(() {
      _address =
          event.snapshot.value?.toString() ?? "Chưa có thông tin địa chỉ";
    });
  }

  Future<void> _fetchDOB() async {
    DatabaseReference dobRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("infoPersonal")
        .child("dob");

    DatabaseEvent event = await dobRef.once();
    setState(() {
      _dob = event.snapshot.value?.toString() ?? "Chưa có thông tin ngày sinh";
    });
  }

  void _fetchVerificationStatus() async {
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid);

    DatabaseEvent event = await userRef.once();
    setState(() {
      isVerified = event.snapshot.child('isVerified').value as bool? ?? false;
    });
  }

  void getCurrentDriverTotalNumberOfTripsCompleted() async {
    DatabaseReference tripRequestsRef =
        FirebaseDatabase.instance.ref().child("tripRequests");

    await tripRequestsRef.once().then((snap) async {
      if (snap.snapshot.value != null) {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value) {
          if (value["status"] != null &&
              value["status"] == "ended" &&
              value["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
            tripsCompletedByCurrentDriver.add(key);
          }
        });

        setState(() {
          currentDriverTotalTripsCompleted =
              tripsCompletedByCurrentDriver.length.toString();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setDriverInfo();
    _fetchRatings();
    _fetchAddress();
    _fetchDOB();
    _fetchVerificationStatus(); // Fetch verification status
    getCurrentDriverTotalNumberOfTripsCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 30),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(driverPhoto),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Tài xế",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                currentDriverTotalTripsCompleted,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Tổng chuyến đã đi",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _ratings.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Đánh giá trung bình",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1.2),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoRow(
                            icon: Icons.phone,
                            text: driverPhone,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.email,
                            text: FirebaseAuth.instance.currentUser!.email
                                .toString(),
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.location_on,
                            text: _address,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.date_range,
                            text: _dob, // Display Date of Birth here
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            icon: Icons.car_crash,
                            text: "$carModel - $carColor",
                          ),
                          const SizedBox(height: 12),
                          // Add a new InfoRow for the verification status
                          InfoRow(
                            icon: Icons.check_circle,
                            text: isVerified ? "Đã xác thực" : "Chưa xác thực",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            overflow: TextOverflow.visible, // Allow text to wrap
          ),
        ),
      ],
    );
  }
}
