import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ReportManagerController extends GetxController {
  /// 🔒 Lock state
  final isLocked = true.obs;

  /// Selected row index
  final selectedRowIndex = RxnInt();

  /// Toggle lock
  void toggleLock() {
    isLocked.value = !isLocked.value;
  }

  /// Clear selection on lock
  void lockAndReset() {
    isLocked.value = true;
    selectedRowIndex.value = null;
  }
}
