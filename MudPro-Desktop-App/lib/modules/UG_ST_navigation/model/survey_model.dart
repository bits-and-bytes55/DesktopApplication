import 'package:flutter/material.dart';

class SurveyStationRow {
  SurveyStationRow({
    String md = '',
    String inc = '',
    String azi = '',
    String tvd = '',
    String vsec = '',
    String northSouth = '',
    String eastWest = '',
    String dogleg = '',
  }) : md = md,
       inc = inc,
       azi = azi,
       tvd = tvd,
       vsec = vsec,
       northSouth = northSouth,
       eastWest = eastWest,
       dogleg = dogleg,
       mdController = TextEditingController(text: md),
       incController = TextEditingController(text: inc),
       aziController = TextEditingController(text: azi);

  String md;
  String inc;
  String azi;
  String tvd;
  String vsec;
  String northSouth;
  String eastWest;
  String dogleg;

  final TextEditingController mdController;
  final TextEditingController incController;
  final TextEditingController aziController;

  factory SurveyStationRow.blank() => SurveyStationRow();

  factory SurveyStationRow.fromJson(Map<String, dynamic> json) {
    return SurveyStationRow(
      md: (json['md'] ?? '').toString(),
      inc: (json['inc'] ?? '').toString(),
      azi: (json['azi'] ?? '').toString(),
      tvd: (json['tvd'] ?? '').toString(),
      vsec: (json['vsec'] ?? '').toString(),
      northSouth: (json['northSouth'] ?? '').toString(),
      eastWest: (json['eastWest'] ?? '').toString(),
      dogleg: (json['dogleg'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'md': md.trim(),
    'inc': inc.trim(),
    'azi': azi.trim(),
    'tvd': tvd.trim(),
    'vsec': vsec.trim(),
    'northSouth': northSouth.trim(),
    'eastWest': eastWest.trim(),
    'dogleg': dogleg.trim(),
  };

  SurveyStationRow clone() {
    return SurveyStationRow(
      md: md,
      inc: inc,
      azi: azi,
      tvd: tvd,
      vsec: vsec,
      northSouth: northSouth,
      eastWest: eastWest,
      dogleg: dogleg,
    );
  }

  bool get hasEditableData =>
      md.trim().isNotEmpty || inc.trim().isNotEmpty || azi.trim().isNotEmpty;

  bool get hasAnyData =>
      hasEditableData ||
      tvd.trim().isNotEmpty ||
      vsec.trim().isNotEmpty ||
      northSouth.trim().isNotEmpty ||
      eastWest.trim().isNotEmpty ||
      dogleg.trim().isNotEmpty;

  void syncEditableControllers() {
    if (mdController.text != md) {
      mdController.value = mdController.value.copyWith(
        text: md,
        selection: TextSelection.collapsed(offset: md.length),
      );
    }
    if (incController.text != inc) {
      incController.value = incController.value.copyWith(
        text: inc,
        selection: TextSelection.collapsed(offset: inc.length),
      );
    }
    if (aziController.text != azi) {
      aziController.value = aziController.value.copyWith(
        text: azi,
        selection: TextSelection.collapsed(offset: azi.length),
      );
    }
  }

  void dispose() {
    mdController.dispose();
    incController.dispose();
    aziController.dispose();
  }
}

class SurveyAnnotationRow {
  SurveyAnnotationRow({
    String md = '',
    String annotation = '',
    String symbol = 'square',
  }) : md = md,
       annotation = annotation,
       symbol = symbol,
       mdController = TextEditingController(text: md),
       annotationController = TextEditingController(text: annotation);

  String md;
  String annotation;
  String symbol;

  final TextEditingController mdController;
  final TextEditingController annotationController;

  factory SurveyAnnotationRow.blank() => SurveyAnnotationRow(symbol: '');

  factory SurveyAnnotationRow.fromJson(Map<String, dynamic> json) {
    return SurveyAnnotationRow(
      md: (json['md'] ?? '').toString(),
      annotation: (json['annotation'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'md': md.trim(),
    'annotation': annotation.trim(),
    'symbol': symbol.trim(),
  };

  SurveyAnnotationRow clone() {
    return SurveyAnnotationRow(md: md, annotation: annotation, symbol: symbol);
  }

  bool get hasData =>
      md.trim().isNotEmpty ||
      annotation.trim().isNotEmpty ||
      symbol.trim().isNotEmpty;

  void syncEditableControllers() {
    if (mdController.text != md) {
      mdController.value = mdController.value.copyWith(
        text: md,
        selection: TextSelection.collapsed(offset: md.length),
      );
    }
    if (annotationController.text != annotation) {
      annotationController.value = annotationController.value.copyWith(
        text: annotation,
        selection: TextSelection.collapsed(offset: annotation.length),
      );
    }
  }

  void dispose() {
    mdController.dispose();
    annotationController.dispose();
  }
}

class SurveyPlotPoint {
  const SurveyPlotPoint({
    required this.md,
    required this.inc,
    required this.azi,
    required this.tvd,
    required this.vsec,
    required this.northSouth,
    required this.eastWest,
    required this.dogleg,
  });

  final double md;
  final double inc;
  final double azi;
  final double tvd;
  final double vsec;
  final double northSouth;
  final double eastWest;
  final double dogleg;
}

class SurveyAnnotationMarker {
  const SurveyAnnotationMarker({
    required this.md,
    required this.label,
    required this.symbol,
  });

  final double md;
  final String label;
  final String symbol;
}
