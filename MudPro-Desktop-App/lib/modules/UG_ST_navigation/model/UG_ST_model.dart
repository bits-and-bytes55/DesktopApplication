import 'package:get/get.dart';

const String kCasedHoleTocMarker = '__cased_hole__';

class CasingRow {
  String? dbId;
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
    this.dbId,
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

  Map<String, dynamic> toJson() => {
        'description': description.value,
        'type': type.value,
        'od': od.value,
        'wt': wt.value,
        'id': id.value,
        'top': top.value,
        'shoe': shoe.value,
        'bit': bit.value,
        'toc': toc.value,
      };

  factory CasingRow.fromJson(Map<String, dynamic> json) => CasingRow(
        dbId: json['_id'],
        description: json['description'] ?? '',
        type: json['type'] ?? '',
        od: json['od'] ?? '',
        wt: json['wt'] ?? '',
        id: json['id'] ?? '',
        top: json['top'] ?? '',
        shoe: json['shoe'] ?? '',
        bit: json['bit'] ?? '',
        toc: json['toc'] ?? '',
      );
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
