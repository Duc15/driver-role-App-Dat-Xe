import 'package:drivers_app/pages/trips_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
  final completedTripRequestsOfCurrentDriver =
      FirebaseDatabase.instance.ref().child("tripRequests");

  // Tỷ giá USD sang VND (giả sử)
  final double exchangeRate = 24000.0;
  String driverEarningsUSD = "";
  String driverEarningsVND = "";

  // Tỷ giá USD sang VND (giả sử)

  getTotalEarningsOfCurrentDriver() async {
    DatabaseReference driversRef =
        FirebaseDatabase.instance.ref().child("drivers");

    await driversRef
        .child(FirebaseAuth.instance.currentUser!.uid)
        .once()
        .then((snap) {
      if ((snap.snapshot.value as Map)["earnings"] != null) {
        setState(() {
          // Lấy giá trị earnings từ cơ sở dữ liệu (USD)
          driverEarningsUSD =
              ((snap.snapshot.value as Map)["earnings"]).toString();

          // Chuyển đổi sang VND
          double earningsUSD = double.tryParse(driverEarningsUSD) ?? 0.0;
          double earningsVND = earningsUSD * exchangeRate;

          // Định dạng số tiền với dấu phẩy
          driverEarningsVND =
              NumberFormat("#,##0", "en_US").format(earningsVND);
        });
      }
    });
  }

  String currentDriverTotalTripsCompleted = "";

  getCurrentDriverTotalNumberOfTripsCompleted() async {
    DatabaseReference tripRequestsRef =
        FirebaseDatabase.instance.ref().child("tripRequests");

    await tripRequestsRef.once().then((snap) async {
      if (snap.snapshot.value != null) {
        Map<dynamic, dynamic> allTripsMap = snap.snapshot.value as Map;
        int allTripsLength = allTripsMap.length;

        List<String> tripsCompletedByCurrentDriver = [];

        allTripsMap.forEach((key, value) {
          if (value["status"] != null) {
            if (value["status"] == "ended") {
              if (value["driverID"] == FirebaseAuth.instance.currentUser!.uid) {
                tripsCompletedByCurrentDriver.add(key);
              }
            }
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
    getTotalEarningsOfCurrentDriver();
    getCurrentDriverTotalNumberOfTripsCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom padding to avoid bottom navigation bar overlap
    double bottomPadding = MediaQuery.of(context).viewInsets.bottom > 0
        ? MediaQuery.of(context).viewInsets.bottom
        : 16.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with the city name
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Việt Nam",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text(
                        "Hà Nội",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.expand_more, size: 28, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            // Background image
            Expanded(
              child: Stack(
                children: [
                  // Background image
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/hanoi.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 250,
                      padding: EdgeInsets.only(
                        top: 16,
                        right: 16,
                        left: 16,
                        bottom: bottomPadding, // Adjust bottom padding
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Total Trips Card
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TripsHistoryPage(),
                                ),
                              );
                            },
                            child: _buildInfoCard(
                              "Tổng số chuyến",
                              currentDriverTotalTripsCompleted,
                              Icons.sunny,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Total Earnings Card
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TripsHistoryPage(),
                                ),
                              );
                            },
                            child: _buildInfoCard(
                              "Tổng thu nhập",
                              "$driverEarningsVND đ",
                              Icons.car_repair,
                              Colors.green,
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
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
        ],
      ),
    );
  }
}
