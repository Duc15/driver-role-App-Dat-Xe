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

  // Get the total earnings of the current driver
  Future<void> getTotalEarningsOfCurrentDriver() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await driversRef.child(uid).once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        if (data["earnings"] != null) {
          setState(() {
            driverEarningsUSD = data["earnings"].toString();
            double earningsUSD = double.tryParse(driverEarningsUSD) ?? 0.0;
            driverEarningsVND = NumberFormat("#,##0", "en_US")
                .format(earningsUSD * exchangeRate);
          });
        }
      }
    } catch (error) {
      print("Error fetching earnings: $error");
    }
  }

  // Filter trips by date range
  void filterTripsByDate() async {
    if (startDate == null || endDate == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await tripRequestsRef.once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final tripsList = data.entries
            .map((entry) => {"key": entry.key, ...entry.value})
            .toList();

        final filteredTrips = tripsList.where((trip) {
          DateTime tripDate = DateTime.parse(trip["publishDateTime"]);
          return trip["status"] == "ended" &&
              trip["driverID"] == uid &&
              tripDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              tripDate.isBefore(endDate!.add(const Duration(days: 1)));
        }).toList();

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
    } catch (error) {
      print("Error fetching trips: $error");
    }
  }

  // Fetch the 3 most recent trips
  Future<void> fetchRecentTrips() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await tripRequestsRef.once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final trips = data.entries
            .where((entry) =>
                entry.value["status"] == "ended" &&
                entry.value["driverID"] == uid)
            .map((entry) => {"key": entry.key, ...entry.value})
            .toList();

        // Sort trips by publish time (latest first)
        trips.sort((a, b) {
          DateTime dateA = DateTime.parse(a["publishDateTime"]);
          DateTime dateB = DateTime.parse(b["publishDateTime"]);
          return dateB.compareTo(dateA);
        });

        // Get the 3 most recent trips
        setState(() {
          recentTrips = trips
              .take(3)
              .map((trip) => trip.cast<String, dynamic>())
              .toList();
        });
      }
    } catch (error) {
      print("Error fetching trips: $error");
    }
  }

  // Show transaction details popup
  void showTransactionDetailDialog(
      BuildContext context, Map<String, dynamic> trip) {
    double fareUSD = double.tryParse(trip["fareAmount"].toString()) ?? 0.0;
    double fareVND = fareUSD * exchangeRate;
    String formattedFareVND = NumberFormat("#,##0", "en_US").format(fareVND);
    DateTime paymentStartTime = DateTime.parse(trip["paymentStartTime"]);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bo tròn góc
          ),
          // elevation: 5,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.blueAccent,
                  Colors.cyan
                ], // Màu gradient cho popup
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề
                const Text(
                  "Chi tiết chuyến đi",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Địa chỉ đón
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Địa chỉ đón: ${trip["pickUpAddress"]}",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Địa chỉ trả
                Row(
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Địa chỉ trả: ${trip["dropOffAddress"]}",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Số tiền
                Row(
                  children: [
                    const Icon(
                      Icons.money,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Số tiền: $formattedFareVND VND",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Thời gian kết thúc
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Thời gian kết thúc: ${DateFormat("dd/MM/yyyy HH:mm").format(paymentStartTime)}",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Mã giao dịch
                Text(
                  "Mã chuyến đi: ${trip["key"]}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Nút đóng
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: Colors.blueAccent, // Màu nút
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  child: const Text(
                    "Đóng",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      backgroundColor: Colors.blue[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tổng thu nhập
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                //elevation: 5,
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
                //elevation: 5,
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
                // elevation: 5,
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

                            DateTime paymentStartTime =
                                DateTime.parse(trip["paymentStartTime"]);

                            return GestureDetector(
                              onTap: () {
                                // Hiển thị popup khi nhấn vào một giao dịch
                                showTransactionDetailDialog(context, trip);
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                  side: const BorderSide(
                                    color: Colors.blue,
                                    width: 2.0,
                                  ),
                                ),
                                color: Colors.white,
                                //  elevation: 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 8),
                                      Text(
                                        "Kết thúc vào: ${DateFormat("dd/MM/yyyy HH:mm").format(paymentStartTime)}",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
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
