import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final DatabaseReference tripRequestsRef =
      FirebaseDatabase.instance.ref().child("tripRequests");
  final DatabaseReference driversRef =
      FirebaseDatabase.instance.ref().child("drivers");

  final double exchangeRate = 24000.0; // Tỷ giá USD sang VND
  String driverEarningsUSD = "";
  String driverEarningsVND = "";
  List<Map<String, dynamic>> recentTrips = [];

  DateTime? startDate;
  DateTime? endDate;
  double filteredEarningsUSD = 0.0;

  // Lấy tổng thu nhập của tài xế
  Future<void> getTotalEarningsOfCurrentDriver() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await driversRef.child(uid).once().then((snap) {
      if (snap.snapshot.value != null) {
        final data = snap.snapshot.value as Map<dynamic, dynamic>;
        if (data["earnings"] != null) {
          setState(() {
            driverEarningsUSD = data["earnings"].toString();
            double earningsUSD = double.tryParse(driverEarningsUSD) ?? 0.0;
            driverEarningsVND = NumberFormat("#,##0", "en_US")
                .format(earningsUSD * exchangeRate);
          });
        }
      }
    }).catchError((error) {
      print("Error fetching earnings: $error");
    });
  }

  // Lọc chuyến đi theo ngày
  void filterTripsByDate() async {
    if (startDate == null || endDate == null) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await tripRequestsRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        final data = snap.snapshot.value as Map;
        final tripsList = data.entries
            .map((entry) => {"key": entry.key, ...entry.value})
            .toList();

        final filteredTrips = tripsList
            .where((trip) =>
                trip["status"] == "ended" &&
                trip["driverID"] == uid &&
                DateTime.parse(trip["publishDateTime"])
                    .isAfter(startDate!.subtract(const Duration(days: 1))) &&
                DateTime.parse(trip["publishDateTime"])
                    .isBefore(endDate!.add(const Duration(days: 1))))
            .toList();

        double totalEarnings = 0.0;
        for (var trip in filteredTrips) {
          double fareUSD =
              double.tryParse(trip["fareAmount"].toString()) ?? 0.0;
          totalEarnings += fareUSD;
        }

        setState(() {
          filteredEarningsUSD = totalEarnings;
        });
      }
    }).catchError((error) {
      print("Error fetching trips: $error");
    });
  }

  // Lấy 3 giao dịch gần nhất
  Future<void> fetchRecentTrips() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await tripRequestsRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        final data = snap.snapshot.value as Map<dynamic, dynamic>;

        // Lọc các chuyến đi hoàn thành của tài xế
        final trips = data.entries
            .where((entry) =>
                entry.value["status"] == "ended" &&
                entry.value["driverID"] == uid)
            .map((entry) => {"key": entry.key, ...entry.value})
            .toList();

        // Sắp xếp theo ngày (mới nhất đến cũ nhất)
        trips.sort((a, b) {
          DateTime dateA = DateTime.parse(a["publishDateTime"]);
          DateTime dateB = DateTime.parse(b["publishDateTime"]);
          return dateB.compareTo(dateA);
        });

        // Lấy 3 chuyến đi gần nhất
        setState(() {
          recentTrips = trips
              .take(3)
              .map((trip) => trip.cast<String, dynamic>())
              .toList();
        });
      }
    }).catchError((error) {
      print("Error fetching trips: $error");
    });
  }

  @override
  void initState() {
    super.initState();
    getTotalEarningsOfCurrentDriver();
    fetchRecentTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu nhập'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tổng thu nhập
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tài khoản và số tài khoản
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Số tiền thu được",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "0112345678", // Số tài khoản
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Số tiền và phần trăm thay đổi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$driverEarningsVND VND", // Số tiền
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: const Text(
                              "+5.21%", // Tăng trưởng
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Lọc chuyến đi theo ngày
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
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    startDate = pickedDate;
                                  });
                                }
                              },
                              child: Text(
                                startDate == null
                                    ? "Chọn ngày bắt đầu"
                                    : DateFormat("dd/MM/yyyy")
                                        .format(startDate!),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    endDate = pickedDate;
                                  });
                                }
                              },
                              child: Text(
                                endDate == null
                                    ? "Chọn ngày kết thúc"
                                    : DateFormat("dd/MM/yyyy").format(endDate!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: filterTripsByDate,
                        child: const Text("Lọc chuyến đi"),
                      ),
                      Text(
                        "Tổng thu nhập (lọc): ${NumberFormat("#,##0", "en_US").format(filteredEarningsUSD * exchangeRate)} VND",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3 giao dịch gần nhất
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "3 giao dịch gần nhất",
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      if (recentTrips.isEmpty)
                        const Text(
                          "Không có giao dịch gần đây.",
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentTrips.length,
                          itemBuilder: (context, index) {
                            final trip = recentTrips[index];
                            double fareUSD = double.tryParse(
                                    trip["fareAmount"].toString()) ??
                                0.0;
                            double fareVND = fareUSD * exchangeRate;
                            String formattedFareVND =
                                NumberFormat("#,##0", "en_US").format(fareVND);

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                side: const BorderSide(
                                  color: Colors.blue,
                                  width: 2.0,
                                ),
                              ),
                              color: Colors.white,
                              elevation: 10,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/initial.png',
                                          height: 16,
                                          width: 16,
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Text(
                                            trip["pickUpAddress"].toString(),
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        Text(
                                          "$formattedFareVND VND",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/final.png',
                                          height: 16,
                                          width: 16,
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Text(
                                            trip["dropOffAddress"].toString(),
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
