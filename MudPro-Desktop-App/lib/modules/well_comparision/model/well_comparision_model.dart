import 'package:get/get.dart';

class PadModel {
  final String padName;
  final RxList<ReportModel> reports;

  PadModel({
    required this.padName,
    required this.reports,
  });
}

class ReportModel {
  final String wellName;
  final String operator;
  final String fieldBlock;
  final String api;
  final String rig;
  final String spudDate;
  final String status;

  RxBool isSelected = false.obs;

  ReportModel({
    required this.wellName,
    required this.operator,
    required this.fieldBlock,
    required this.api,
    required this.rig,
    required this.spudDate,
    required this.status,
  });
}
