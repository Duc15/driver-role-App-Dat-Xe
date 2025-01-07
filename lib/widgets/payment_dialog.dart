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
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 21,
            ),
            const Text(
              "Thu tiền",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 21,
            ),
            const Divider(
              height: 1.5,
              color: Colors.white70,
              thickness: 1.0,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "$formattedFareAmount VND",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Bạn sẽ nhận ( $formattedFareAmount VND ) cho chuyến đi này. Đưa cho khách kiểm tra trước khi thanh toán",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(
              height: 31,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);

                cMethods.turnOnLocationUpdatesForHomePage();

                // Restart.restartApp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                "Nhận tiền",
              ),
            ),
            const SizedBox(
              height: 41,
            )
          ],
        ),
      ),
    );
  }
}
