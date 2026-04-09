import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AlertService {
  static void show(String message, {bool isSuccess = true, BuildContext? context}) {
    // GetSnackBar is the most reliable way in GetX to show a premium alert on Desktop
    Get.showSnackbar(GetSnackBar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(top: 80, right: 20, left: 20),
      maxWidth: 350,
      duration: const Duration(seconds: 3),
      borderRadius: 10,
      padding: EdgeInsets.zero,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 5),
        )
      ],
      animationDuration: const Duration(milliseconds: 400),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSuccess
                ? [const Color(0xff38B2AC), const Color(0xff319795)]
                : [const Color(0xffFC8181), const Color(0xffF56565)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.lock,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(Icons.close, size: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    ));
  }
}
