import 'package:get/get.dart';

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

  FormationRow({
    String description = '',
    String tvd = '',
    String porePpg = '',
    String poreGrad = '',
    String porePsi = '',
    String fracPpg = '',
    String fracGrad = '',
    String fracPsi = '',
  })  : description = description.obs,
        tvd = tvd.obs,
        porePpg = porePpg.obs,
        poreGrad = poreGrad.obs,
        porePsi = porePsi.obs,
        fracPpg = fracPpg.obs,
        fracGrad = fracGrad.obs,
        fracPsi = fracPsi.obs;
}
