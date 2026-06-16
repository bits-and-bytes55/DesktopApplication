import 'package:get/get.dart';

String _blankZero(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  final number = double.tryParse(text.replaceAll(',', ''));
  if (number != null && number == 0) return '';
  return text;
}

class FormationRow {
  RxString description;
  RxString tvd;

  // -------- PORE --------
  RxString porePpg;
  RxString poreGrad;
  RxString porePsi;

  // -------- FRACTURE --------
  RxString fracPpg;
  RxString fracGrad;
  RxString fracPsi;
  RxString lithology;

  FormationRow({
    String description = '',
    String tvd = '',
    String porePpg = '',
    String poreGrad = '',
    String porePsi = '',
    String fracPpg = '',
    String fracGrad = '',
    String fracPsi = '',
    String lithology = '',
  }) : description = description.obs,
       tvd = tvd.obs,
       porePpg = porePpg.obs,
       poreGrad = poreGrad.obs,
       porePsi = porePsi.obs,
       fracPpg = fracPpg.obs,
       fracGrad = fracGrad.obs,
       fracPsi = fracPsi.obs,
       lithology = lithology.obs;

  factory FormationRow.fromJson(Map<String, dynamic> json) {
    return FormationRow(
      description: (json['description'] ?? '').toString(),
      tvd: _blankZero(json['tvd']),
      porePpg: _blankZero(json['porePpg']),
      poreGrad: _blankZero(json['poreGrad']),
      porePsi: _blankZero(json['porePsi']),
      fracPpg: _blankZero(json['fracPpg']),
      fracGrad: _blankZero(json['fracGrad']),
      fracPsi: _blankZero(json['fracPsi']),
      lithology: (json['lithology'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description.value.trim(),
    'tvd': tvd.value.trim(),
    'porePpg': porePpg.value.trim(),
    'poreGrad': poreGrad.value.trim(),
    'porePsi': porePsi.value.trim(),
    'fracPpg': fracPpg.value.trim(),
    'fracGrad': fracGrad.value.trim(),
    'fracPsi': fracPsi.value.trim(),
    'lithology': lithology.value.trim(),
  };

  FormationRow clone() {
    return FormationRow(
      description: description.value,
      tvd: tvd.value,
      porePpg: porePpg.value,
      poreGrad: poreGrad.value,
      porePsi: porePsi.value,
      fracPpg: fracPpg.value,
      fracGrad: fracGrad.value,
      fracPsi: fracPsi.value,
      lithology: lithology.value,
    );
  }

  bool get hasData {
    return description.value.trim().isNotEmpty ||
        tvd.value.trim().isNotEmpty ||
        porePpg.value.trim().isNotEmpty ||
        poreGrad.value.trim().isNotEmpty ||
        porePsi.value.trim().isNotEmpty ||
        fracPpg.value.trim().isNotEmpty ||
        fracGrad.value.trim().isNotEmpty ||
        fracPsi.value.trim().isNotEmpty ||
        lithology.value.trim().isNotEmpty;
  }

  void clearRetainingReadOnlyDefaults() {
    description.value = '';
    tvd.value = '';
    porePpg.value = '';
    poreGrad.value = '';
    porePsi.value = '';
    fracPpg.value = '';
    fracGrad.value = '';
    fracPsi.value = '';
    lithology.value = '';
  }
}
