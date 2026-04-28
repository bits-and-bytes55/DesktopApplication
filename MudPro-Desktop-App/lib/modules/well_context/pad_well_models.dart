class AppPad {
  final String id;
  final String locationType;
  final String fieldBlock;
  final String rig;
  final String countyParishOffshoreArea;
  final String stateProvince;
  final String country;
  final String stockPoint;
  final String phone;
  final String operator;
  final String operatorRep;
  final String contractor;
  final String contractorRep;
  final String sl;
  final String airGap;
  final String waterDepth;
  final String riserOD;
  final String riserID;
  final String chokeLineID;
  final String killLineID;
  final String boostLineID;
  final String memo;
  final List<AppWell> wells;

  const AppPad({
    required this.id,
    required this.locationType,
    required this.fieldBlock,
    required this.rig,
    required this.countyParishOffshoreArea,
    required this.stateProvince,
    required this.country,
    required this.stockPoint,
    required this.phone,
    required this.operator,
    required this.operatorRep,
    required this.contractor,
    required this.contractorRep,
    required this.sl,
    required this.airGap,
    required this.waterDepth,
    required this.riserOD,
    required this.riserID,
    required this.chokeLineID,
    required this.killLineID,
    required this.boostLineID,
    required this.memo,
    required this.wells,
  });

  factory AppPad.fromJson(Map<String, dynamic> json) {
    final id = _text(json['_id'] ?? json['id']);
    final wellsJson = json['wells'];

    return AppPad(
      id: id,
      locationType: _text(json['locationType']),
      fieldBlock: _text(json['fieldBlock']),
      rig: _text(json['rig']),
      countyParishOffshoreArea: _text(json['countyParishOffshoreArea']),
      stateProvince: _text(json['stateProvince']),
      country: _text(json['country']),
      stockPoint: _text(json['stockPoint']),
      phone: _text(json['phone']),
      operator: _text(json['operator']),
      operatorRep: _text(json['operatorRep']),
      contractor: _text(json['contractor']),
      contractorRep: _text(json['contractorRep']),
      sl: _text(json['sl']),
      airGap: _text(json['airGap']),
      waterDepth: _text(json['waterDepth']),
      riserOD: _text(json['riserOD']),
      riserID: _text(json['riserID']),
      chokeLineID: _text(json['chokeLineID']),
      killLineID: _text(json['killLineID']),
      boostLineID: _text(json['boostLineID']),
      memo: _text(json['memo']),
      wells: wellsJson is List
          ? wellsJson
                .whereType<Map>()
                .map(
                  (well) => AppWell.fromJson(
                    Map<String, dynamic>.from(well),
                    fallbackPadId: id,
                  ),
                )
                .toList()
          : const <AppWell>[],
    );
  }

  String get displayName {
    if (fieldBlock.isNotEmpty) return fieldBlock;
    if (rig.isNotEmpty) return 'Rig $rig';
    if (operator.isNotEmpty) return operator;
    if (country.isNotEmpty) return country;
    if (id.length >= 6) return 'Pad ${id.substring(id.length - 6)}';
    return id.isEmpty ? 'Unnamed Pad' : 'Pad $id';
  }

  AppPad copyWith({List<AppWell>? wells}) => AppPad(
    id: id,
    locationType: locationType,
    fieldBlock: fieldBlock,
    rig: rig,
    countyParishOffshoreArea: countyParishOffshoreArea,
    stateProvince: stateProvince,
    country: country,
    stockPoint: stockPoint,
    phone: phone,
    operator: operator,
    operatorRep: operatorRep,
    contractor: contractor,
    contractorRep: contractorRep,
    sl: sl,
    airGap: airGap,
    waterDepth: waterDepth,
    riserOD: riserOD,
    riserID: riserID,
    chokeLineID: chokeLineID,
    killLineID: killLineID,
    boostLineID: boostLineID,
    memo: memo,
    wells: wells ?? this.wells,
  );
}

class AppWell {
  final String id;
  final String padId;
  final AppPadRef? pad;
  final String wellNameNo;
  final String apiWellNo;
  final String spudDate;
  final String sectionTownshipRange;
  final String longitude;
  final String latitude;
  final String kop;
  final String lp;
  final String bulkTankSetupFee;

  const AppWell({
    required this.id,
    required this.padId,
    required this.pad,
    required this.wellNameNo,
    required this.apiWellNo,
    required this.spudDate,
    required this.sectionTownshipRange,
    required this.longitude,
    required this.latitude,
    required this.kop,
    required this.lp,
    required this.bulkTankSetupFee,
  });

  factory AppWell.fromJson(
    Map<String, dynamic> json, {
    String fallbackPadId = '',
  }) {
    final rawPad = json['padId'];
    String resolvedPadId = fallbackPadId;
    AppPadRef? pad;

    if (rawPad is Map) {
      final padMap = Map<String, dynamic>.from(rawPad);
      resolvedPadId = _text(padMap['_id'] ?? padMap['id']);
      pad = AppPadRef.fromJson(padMap);
    } else if (_text(rawPad).isNotEmpty) {
      resolvedPadId = _text(rawPad);
    }

    return AppWell(
      id: _text(json['_id'] ?? json['id']),
      padId: resolvedPadId,
      pad: pad,
      wellNameNo: _text(json['wellNameNo']),
      apiWellNo: _text(json['apiWellNo']),
      spudDate: _text(json['spudDate']),
      sectionTownshipRange: _text(json['sectionTownshipRange']),
      longitude: _text(json['longitude']),
      latitude: _text(json['latitude']),
      kop: _text(json['kop']),
      lp: _text(json['lp']),
      bulkTankSetupFee: _text(json['bulkTankSetupFee']),
    );
  }

  String get displayName {
    if (wellNameNo.isNotEmpty) return wellNameNo;
    if (apiWellNo.isNotEmpty) return apiWellNo;
    if (id.length >= 6) return 'Well ${id.substring(id.length - 6)}';
    return id.isEmpty ? 'Unnamed Well' : 'Well $id';
  }
}

class AppPadRef {
  final String id;
  final String fieldBlock;
  final String rig;
  final String operator;
  final String country;

  const AppPadRef({
    required this.id,
    required this.fieldBlock,
    required this.rig,
    required this.operator,
    required this.country,
  });

  factory AppPadRef.fromJson(Map<String, dynamic> json) => AppPadRef(
    id: _text(json['_id'] ?? json['id']),
    fieldBlock: _text(json['fieldBlock']),
    rig: _text(json['rig']),
    operator: _text(json['operator']),
    country: _text(json['country']),
  );
}

String _text(dynamic value) => value?.toString().trim() ?? '';
