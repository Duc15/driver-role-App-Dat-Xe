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

  final double exchangeRate = 24000.0; // USD to VND rate
  String driverEarningsVND = "";
  double filteredEarningsUSD = 0.0;
  List<Map<String, dynamic>> recentTrips = [];

  DateTime? startDate;
  DateTime? endDate;

  // Fetch the total earnings for the current driver
  Future<void> fetchEarnings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await driversRef.child(uid).once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        if (data["earnings"] != null) {
          double earningsUSD =
              double.tryParse(data["earnings"].toString()) ?? 0.0;
          setState(() {
            driverEarningsVND = NumberFormat("#,##0", "en_US")
                .format(earningsUSD * exchangeRate);
          });
        }
      }
    } catch (error) {
      print("Error fetching earnings: $error");
    }
  }

  // Filter trips based on the date range
  void filterTrips() async {
    if (startDate == null || endDate == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await tripRequestsRef.once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final tripsList = data.entries
            .map((entry) => {"key": entry.key, ...entry.value})
            .where((trip) {
          DateTime tripDate = DateTime.parse(trip["publishDateTime"]);
          return trip["status"] == "ended" &&
              trip["driverID"] == uid &&
              tripDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              tripDate.isBefore(endDate!.add(const Duration(days: 1)));
        }).toList();

        double totalEarnings = 0.0;
        for (var trip in tripsList) {
          totalEarnings +=
              double.tryParse(trip["fareAmount"].toString()) ?? 0.0;
        }

        setState(() {
          filteredEarningsUSD = totalEarnings;
        });
      }
    } catch (error) {
      print("Error fetching trips: $error");
    }
  }

  // Fetch recent trips (last 3)
  Future<void> fetchRecentTrips() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final snapshot = await tripRequestsRef.once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        final trips = data.entries
            .where((entry) =>
                entry.value["status"] == "ended" &&
                entry.value["driverID"] == uid)
            .map((entry) => {"key": entry.key, ...entry.value})
            .toList();

        trips.sort((a, b) => DateTime.parse(b["publishDateTime"])
            .compareTo(DateTime.parse(a["publishDateTime"])));

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chi tiết chuyến đi",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                    Icons.location_on, "Địa chỉ đón: ${trip["pickUpAddress"]}"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_off,
                    "Địa chỉ trả: ${trip["dropOffAddress"]}"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.money, "Số tiền: $formattedFareVND VND"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.access_time,
                    "Thời gian kết thúc: ${DateFormat("dd/MM/yyyy HH:mm").format(paymentStartTime)}"),
                const SizedBox(height: 20),
                Text("Mã chuyến đi: ${trip["key"]}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  child: const Text("Đóng",
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build row for transaction details
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    fetchEarnings();
    fetchRecentTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Thu nhập'), backgroundColor: Colors.blue),
      backgroundColor: Colors.blue[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildEarningsCard(),
              const SizedBox(height: 20),
              _buildDateRangeFilter(),
              const SizedBox(height: 20),
              _buildRecentTransactionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Earnings card widget
  Widget _buildEarningsCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Số tiền thu được",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                Text("0112345678",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$driverEarningsVND VND",
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Text("+5.21%",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Date range filter widget
  Widget _buildDateRangeFilter() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildDatePicker("Chọn ngày bắt đầu", startDate, (pickedDate) {
                  setState(() {
                    startDate = pickedDate;
                  });
                }),
                _buildDatePicker("Chọn ngày kết thúc", endDate, (pickedDate) {
                  setState(() {
                    endDate = pickedDate;
                  });
                }),
              ],
            ),
            ElevatedButton(
                onPressed: filterTrips, child: const Text("Lọc thu nhập")),
            Text(
              "Tổng thu nhập (lọc): ${NumberFormat("#,##0", "en_US").format(filteredEarningsUSD * exchangeRate)} VND",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  // Date picker button helper
  Widget _buildDatePicker(
      String label, DateTime? selectedDate, Function(DateTime?) onDatePicked) {
    return Expanded(
      child: TextButton(
        onPressed: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          onDatePicked(pickedDate);
        },
        child: Text(selectedDate == null
            ? label
            : DateFormat("dd/MM/yyyy").format(selectedDate!)),
      ),
    );
  }

  // Recent transactions card widget
  Widget _buildRecentTransactionsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("3 giao dịch gần nhất",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: recentTrips.map((trip) {
                double fareUSD =
                    double.tryParse(trip["fareAmount"].toString()) ?? 0.0;
                double fareVND = fareUSD * exchangeRate;
                String formattedFareVND =
                    NumberFormat("#,##0", "en_US").format(fareVND);

                DateTime tripDate = DateTime.parse(trip["paymentStartTime"]);

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        showTransactionDetailDialog(context, trip);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/initial.png',
                                    height: 16, width: 16),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    trip["pickUpAddress"].toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Image.asset('assets/images/final.png',
                                    height: 16, width: 16),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    trip["dropOffAddress"].toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  "Thời gian: ${DateFormat("dd/MM/yyyy HH:mm").format(tripDate)}",
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  " + $formattedFareVND VND",
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
