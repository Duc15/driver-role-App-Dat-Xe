import 'package:drivers_app/methods/common_methods.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl

class PaymentDialog extends StatefulWidget {
  String fareAmount;

  PaymentDialog({
    super.key,
    required this.fareAmount,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  CommonMethods cMethods = CommonMethods();

  // Tỷ giá USD sang VND (giả sử)
  final double exchangeRate = 24000.0;

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi fareAmount từ String sang double
    double fareAmountUSD = double.tryParse(widget.fareAmount) ?? 0.0;
    // Đổi sang VND
    double fareAmountVND = fareAmountUSD * exchangeRate;

    // Định dạng số theo kiểu tiền tệ VND với dấu phẩy
    String formattedFareAmount = NumberFormat.currency(
      locale: "vi_VN",
      symbol: "", // Không thêm ký hiệu (đã có VND trong chuỗi)
      decimalDigits: 0, // Không có phần thập phân
    ).format(fareAmountVND);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20), // Tăng độ bo góc cho hiện đại hơn
      ),
      backgroundColor: Colors.white, // Màu nền sáng
      child: Container(
        margin: const EdgeInsets.all(20.0), // Cải thiện margin
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Thêm gradient nền sáng
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12, // Bóng nhẹ để nổi bật
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 20,
            ),
            Text(
              "Thu tiền",
              style: TextStyle(
                color: Colors.blue.shade700, // Màu chữ nổi bật hơn
                fontSize: 24,
                fontWeight: FontWeight.bold, // Font đậm
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(
              height: 1.5,
              color: Colors.blueGrey,
              thickness: 1.0,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "$formattedFareAmount VND",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 45, // Tăng kích thước chữ
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Bạn sẽ nhận ( $formattedFareAmount VND ) cho chuyến đi này. Đưa cho khách kiểm tra trước khi thanh toán",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54, // Màu chữ dễ nhìn hơn
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);

                cMethods.turnOnLocationUpdatesForHomePage();

                // Restart.restartApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade400, // Màu nút hiện đại
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Bo góc nút
                ),
                elevation: 5, // Bóng đổ nhẹ
              ),
              child: const Text(
                "Đã nhận tiền",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18, // Tăng kích thước chữ nút
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0, // Khoảng cách giữa các chữ
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
