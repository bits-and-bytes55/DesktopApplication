import 'package:get/get.dart';

class CasingRow {
  RxString description = ''.obs;
  RxString type = ''.obs;
  RxString od = ''.obs;
  RxString wt = ''.obs;
  RxString id = ''.obs;
  RxString top = ''.obs;
  RxString shoe = ''.obs;
  RxString bit = ''.obs;
  RxString toc = ''.obs;

  CasingRow({
    String description = '',
    String type = '',
    String od = '',
    String wt = '',
    String id = '',
    String top = '',
    String shoe = '',
    String bit = '',
    String toc = '',
  }) {
    this.description.value = description;
    this.type.value = type;
    this.od.value = od;
    this.wt.value = wt;
    this.id.value = id;
    this.top.value = top;
    this.shoe.value = shoe;
    this.bit.value = bit;
    this.toc.value = toc;
  }
}


class SectionPoint {
  final double tvd;      // vertical depth (ft)
  final double hd;       // horizontal displacement (ft)

  SectionPoint(this.tvd, this.hd);
}


class PlanPoint {
  final double ew; // East(+)/West(-)
  final double ns; // North(+)/South(-)

  PlanPoint(this.ew, this.ns);
}

class DoglegPoint {
  final double md;       // Measured Depth (ft)
  final double dogleg;   // Dogleg Severity (°/100ft)

  DoglegPoint(this.md, this.dogleg);
}


class Well3DPoint {
  final double x; // E/W
  final double y; // N/S
  final double z; // TVD

  Well3DPoint(this.x, this.y, this.z);
}
