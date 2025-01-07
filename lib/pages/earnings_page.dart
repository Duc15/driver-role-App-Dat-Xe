import 'package:drivers_app/pages/trips_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
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

  @override
  void initState() {
    super.initState();
    getTotalEarningsOfCurrentDriver();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thu nhập'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Thẻ hiển thị tài khoản và số tiền
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
                      const SizedBox(height: 16),
                      // Các nút
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ElevatedButton(
                          //   onPressed: () {
                          //     // Xử lý khi bấm nút Register
                          //   },
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.blue,
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 32, vertical: 14),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //   ),
                          //   child: const Text(
                          //     "Nút phụ",
                          //     style:
                          //         TextStyle(fontSize: 16, color: Colors.white),
                          //   ),
                          // ),
                          ElevatedButton(
                            onPressed: () {
                              // Xử lý khi bấm nút Visit Stripe
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Nhận thêm chuyến",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Phần Activity

              SafeArea(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Biến động số dư",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Danh sách hoạt động
                        StreamBuilder(
                          // Stream lắng nghe thay đổi từ Firebase
                          stream: completedTripRequestsOfCurrentDriver.onValue,
                          builder: (BuildContext context, snapshotData) {
                            if (snapshotData.hasError) {
                              return const Center(
                                child: Text(
                                  "Có lỗi xảy ra",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            if (!(snapshotData.hasData)) {
                              return const Center(
                                child: Text(
                                  "Không có chuyến đi nào!",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            // Chuyển dữ liệu snapshot thành danh sách các chuyến đi
                            Map dataTrips =
                                snapshotData.data!.snapshot.value as Map;
                            List tripsList = [];
                            dataTrips.forEach((key, value) =>
                                tripsList.add({"key": key, ...value}));
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: 3,
                              itemBuilder: ((context, index) {
                                if (tripsList[index]["status"] != null &&
                                    tripsList[index]["status"] == "ended" &&
                                    tripsList[index]["driverID"] ==
                                        FirebaseAuth
                                            .instance.currentUser!.uid) {
                                  // Lấy thông tin giá vé (fareAmount) và chuyển đổi sang VND
                                  double fareUSD = double.tryParse(
                                          tripsList[index]["fareAmount"]
                                              .toString()) ??
                                      0.0;
                                  double fareVND = fareUSD * exchangeRate;

                                  // Định dạng số tiền
                                  String formattedFareVND =
                                      NumberFormat("#,##0", "en_US")
                                          .format(fareVND);

                                  // Lấy thời gian hoàn thành (endTime) từ Firebase
                                  String? endTime = tripsList[index][
                                      "publishDateTime"]; // Ví dụ: "2024-11-28T15:32:10.123456Z"
                                  String formattedDate = "";
                                  String formattedTime = "";

                                  if (endTime != null) {
                                    // Chuyển đổi định dạng ngày giờ
                                    DateTime parsedDate =
                                        DateTime.parse(endTime).toLocal();
                                    formattedDate = DateFormat("dd/MM/yyyy")
                                        .format(parsedDate);
                                    formattedTime =
                                        DateFormat("HH:mm").format(parsedDate);
                                  }

                                  // Hiển thị mỗi chuyến đi
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                        side: const BorderSide(
                                          color: Colors.blue,
                                          width: 2.0,
                                        ),
                                      ),
                                      color: Colors.white,
                                      elevation: 10,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Thông tin địa chỉ và giá vé
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
                                                    tripsList[index]
                                                            ["pickUpAddress"]
                                                        .toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "+$formattedFareVND VND",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Địa chỉ dropOff
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
                                                    tripsList[index]
                                                            ["dropOffAddress"]
                                                        .toString(),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Thời gian hoàn thành
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Ngày: $formattedDate",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  "Thời gian: $formattedTime",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Container();
                                }
                              }),
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Xử lý khi bấm "See All"
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => TripsHistoryPage()));
                            },
                            child: const Text(
                              "Xem tất cả chuyến",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class PayoutItem extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String amount;

  const PayoutItem({
    Key? key,
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
