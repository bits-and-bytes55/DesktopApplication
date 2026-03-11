// ─────────────────────────────────────────────────────────────────────────────
// unit_system_model.dart
// Pure data models — no Flutter, no GetX, no HTTP
// ─────────────────────────────────────────────────────────────────────────────

// ── Unit system enum (used by the main Options page radio buttons) ────────────
enum UnitSystem { us, si, customized }

// ── Single parameter entry {number, name, unit} ───────────────────────────────
class ParameterUnit {
  final String number; // "1" … "53"
  final String name;   // "Length", "Pressure", …
  String unit;         // "ft", "ppg", … — mutable so popup can update in-place

  ParameterUnit({
    required this.number,
    required this.name,
    required this.unit,
  });

  factory ParameterUnit.fromJson(Map<String, dynamic> j) => ParameterUnit(
        number: (j['number'] ?? '').toString(),
        name:   (j['name']   ?? '').toString(),
        unit:   (j['unit']   ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'name':   name,
        'unit':   unit,
      };

  @override
  String toString() => 'ParameterUnit($number: $name = $unit)';
}

// ── Full unit system document (mirrors MongoDB document) ─────────────────────
class UnitSystemModel {
  final String id;           // MongoDB _id
  String name;               // "Pegasus Default 1", "SI", "US", …
  String baseTemplate;       // "us" | "si"
  List<ParameterUnit> parameters; // ordered list of 53 entries
  int sortOrder;

  UnitSystemModel({
    required this.id,
    required this.name,
    required this.baseTemplate,
    required this.parameters,
    this.sortOrder = 0,
  });

  factory UnitSystemModel.fromJson(Map<String, dynamic> j) => UnitSystemModel(
        id:           (j['_id']          ?? '').toString(),
        name:         (j['name']         ?? '').toString(),
        baseTemplate: (j['baseTemplate'] ?? 'us').toString(),
        sortOrder:    (j['sortOrder']    ?? 0) as int,
        parameters:   (j['parameters'] as List? ?? [])
            .map((p) => ParameterUnit.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  /// Returns the unit for a given parameter number ("1"…"53"), or '' if missing.
  String unitFor(String paramNumber) {
    for (final p in parameters) {
      if (p.number == paramNumber) return p.unit;
    }
    return '';
  }

  @override
  String toString() => 'UnitSystemModel($id, $name, ${parameters.length} params)';
}

// ── Response wrapper ──────────────────────────────────────────────────────────
class UnitSystemListResponse {
  final bool success;
  final List<UnitSystemModel> data;
  final String? message;

  UnitSystemListResponse({
    required this.success,
    required this.data,
    this.message,
  });
}

class UnitSystemResponse {
  final bool success;
  final UnitSystemModel? data;
  final String? message;

  UnitSystemResponse({
    required this.success,
    this.data,
    this.message,
  });
}