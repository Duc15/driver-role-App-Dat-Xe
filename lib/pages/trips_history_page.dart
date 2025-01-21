import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl

class TripsHistoryPage extends StatefulWidget {
  const TripsHistoryPage({super.key});

  @override
  State<TripsHistoryPage> createState() => _TripsHistoryPageState();
}

class _TripsHistoryPageState extends State<TripsHistoryPage> {
  final completedTripRequestsOfCurrentDriver =
      FirebaseDatabase.instance.ref().child("tripRequests");

  // Tỷ giá USD sang VND (giả sử)
  final double exchangeRate = 24000.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Lịch sử chuyến',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
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

          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips
              .forEach((key, value) => tripsList.add({"key": key, ...value}));

          return ListView.builder(
            shrinkWrap: true,
            itemCount: tripsList.length,
            itemBuilder: ((context, index) {
              if (tripsList[index]["status"] != null &&
                  tripsList[index]["status"] == "ended" &&
                  tripsList[index]["driverID"] ==
                      FirebaseAuth.instance.currentUser!.uid) {
                // Chuyển đổi giá trị fareAmount từ USD sang VND
                double fareUSD = double.tryParse(
                        tripsList[index]["fareAmount"].toString()) ??
                    0.0;
                double fareVND = fareUSD * exchangeRate;

                // Định dạng số tiền với dấu phẩy
                String formattedFareVND =
                    NumberFormat("#,##0", "en_US").format(fareVND);

                // Lấy thời gian kết thúc chuyến đi
                String paymentStartTime =
                    tripsList[index]["paymentStartTime"] ?? "";
                DateTime? endDateTime;
                if (paymentStartTime.isNotEmpty) {
                  endDateTime = DateTime.tryParse(paymentStartTime);
                }
                String formattedEndTime = endDateTime != null
                    ? DateFormat("dd/MM/yyyy HH:mm").format(endDateTime)
                    : "";

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15.0), // Adjust the border radius as needed
                      side: const BorderSide(
                        color: Colors.blue, // Set the border color here
                        width: 2.0, // Set the border width here
                      ),
                    ),
                    color: Colors.white,
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //pickup - fare amount
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/initial.png',
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(
                                width: 18,
                              ),
                              Expanded(
                                child: Text(
                                  tripsList[index]["pickUpAddress"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines:
                                      2, // Allowing two lines for pick-up address
                                  softWrap:
                                      true, // Enabling soft wrap for text overflow
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Row for displaying fare amount

                          const SizedBox(
                            height: 8,
                          ),

                          //dropoff - in a separate row
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/final.png',
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(
                                width: 18,
                              ),
                              Expanded(
                                child: Text(
                                  tripsList[index]["dropOffAddress"].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines:
                                      2, // Allowing two lines for drop-off address
                                  softWrap:
                                      true, // Enabling soft wrap for text overflow
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // Thêm thời gian kết thúc
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Thời gian kết thúc: $formattedEndTime",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 30), // To align fare
                              Text(
                                "+$formattedFareVND VND",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
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
    );
  }
}
