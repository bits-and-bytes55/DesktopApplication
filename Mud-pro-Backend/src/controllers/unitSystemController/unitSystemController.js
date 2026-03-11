import UnitSystem from "../../modules/unitSystem/unitSystemModel.js";

// ─── SEED DATA ────────────────────────────────────────────────────────────────
// Full 53-parameter list with US Oil Field defaults.
// Used when creating a new system from the "us" base template.
const US_PARAMETERS = [
  { number: "1",  name: "Length",                                  unit: "ft" },
  { number: "2",  name: "Pipe diameter",                           unit: "in" },
  { number: "3",  name: "Cross section",                           unit: "in²" },
  { number: "4",  name: "Fluid volume",                            unit: "bbl" },
  { number: "5",  name: "Velocity",                                unit: "ft/min" },
  { number: "6",  name: "Pressure",                                unit: "psi" },
  { number: "7",  name: "Mass rate",                               unit: "lb/min" },
  { number: "8",  name: "Line density",                            unit: "lb/ft" },
  { number: "9",  name: "Density",                                 unit: "lb/ft³" },
  { number: "10", name: "Mud weight",                              unit: "ppg" },
  { number: "11", name: "ECD",                                     unit: "ppg" },
  { number: "12", name: "Temperature",                             unit: "°F" },
  { number: "13", name: "Temperature gradient",                    unit: "°F/100ft" },
  { number: "14", name: "Dogleg",                                  unit: "°/100ft" },
  { number: "15", name: "Spacer additive concentration - solid",   unit: "lb/bbl" },
  { number: "16", name: "Mass - volume ratio",                     unit: "lb/bbl" },
  { number: "17", name: "Volume - volume ratio",                   unit: "gal/bbl" },
  { number: "18", name: "Sack of Cement",                          unit: "sk" },
  { number: "19", name: "Cement/solid additive Wt/sk",             unit: "lb/sk" },
  { number: "20", name: "Spacer additive concentration - liquid",  unit: "gal/bbl" },
  { number: "21", name: "Cement slurry yield",                     unit: "ft³/sk" },
  { number: "22", name: "Cement liquid additive/water requirement", unit: "gal/sk" },
  { number: "23", name: "Leasing Fee",                             unit: "$/bbl" },
  { number: "24", name: "Sea current",                             unit: "mph" },
  { number: "25", name: "Heat Capacity",                           unit: "Btu/lb/°F" },
  { number: "26", name: "Temperature change",                      unit: "°F" },
  { number: "27", name: "Thermal conductivity",                    unit: "Btu/hr/ft/°F" },
  { number: "28", name: "Thermal expansion",                       unit: "10⁻⁶/°F" },
  { number: "29", name: "Elasticity",                              unit: "Mpa" },
  { number: "30", name: "Liquid volume",                           unit: "gal" },
  { number: "31", name: "Funnel viscosity",                        unit: "sec/qt" },
  { number: "32", name: "Revolution",                              unit: "rev" },
  { number: "33", name: "ROP",                                     unit: "ft/day" },
  { number: "34", name: "Cutting transport rate",                  unit: "US ton/h" },
  { number: "35", name: "Parameter 35",                            unit: "(rpm)" },
  { number: "36", name: "Parameter 36",                            unit: "(lbf)" },
  { number: "37", name: "Parameter 37",                            unit: "(N)" },
  { number: "38", name: "Parameter 38",                            unit: "(fbf/ft)" },
  { number: "39", name: "Parameter 39",                            unit: "(N/m)" },
  { number: "40", name: "Parameter 40",                            unit: "(ft-lb)" },
  { number: "41", name: "Parameter 41",                            unit: "(f13)" },
  { number: "42", name: "Parameter 42",                            unit: "(n3)" },
  { number: "43", name: "Parameter 43",                            unit: "(bbl./aik)" },
  { number: "44", name: "Parameter 44",                            unit: "(acf)" },
  { number: "45", name: "Parameter 45",                            unit: "(f1/min)" },
  { number: "46", name: "Parameter 46",                            unit: "(f1/a)" },
  { number: "47", name: "Parameter 47",                            unit: "(f1/hr)" },
  { number: "48", name: "Parameter 48",                            unit: "(rpm)" },
  { number: "49", name: "Parameter 49",                            unit: "(lbf)" },
  { number: "50", name: "Parameter 50",                            unit: "(fbf/ft)" },
  { number: "51", name: "Parameter 51",                            unit: "(ft-lb)" },
  { number: "52", name: "Parameter 52",                            unit: "(psi)" },
  { number: "53", name: "Parameter 53",                            unit: "(psi/ft)" },
];

const SI_PARAMETERS = US_PARAMETERS.map((p) => {
  const siMap = {
    "ft": "m", "in": "mm", "in²": "mm²", "bbl": "m³",
    "ft/min": "m/min", "psi": "kPa", "lb/min": "kg/min",
    "lb/ft": "kg/m", "lb/ft³": "kg/m³", "ppg": "kg/m³",
    "°F": "°C", "°F/100ft": "°C/100m", "°/100ft": "°/100m",
    "lb/bbl": "L/m³", "gal/bbl": "L/m³", "sk": "bag",
    "lb/sk": "kg/bag", "ft³/sk": "m³/bag", "gal/sk": "L/bag",
    "$/bbl": "$/m³", "mph": "km/h", "Btu/lb/°F": "J/kg/°C",
    "Btu/hr/ft/°F": "W/m/K", "10⁻⁶/°F": "10⁻⁶/°C",
    "gal": "L", "sec/qt": "sec/L", "ft/day": "m/day",
    "US ton/h": "tonne/h",
  };
  return { ...p, unit: siMap[p.unit] ?? p.unit };
});

function seedParameters(baseTemplate) {
  return baseTemplate === "si"
    ? SI_PARAMETERS.map((p) => ({ ...p }))
    : US_PARAMETERS.map((p) => ({ ...p }));
}

// ═══════════════════════════════════════════════════════════════════════════════
// GET /api/unit-systems
// Returns all unit systems (for left panel list)
// ═══════════════════════════════════════════════════════════════════════════════
export const getAllUnitSystems = async (req, res) => {
  try {
    const systems = await UnitSystem.find().sort({ sortOrder: 1, createdAt: 1 });
    return res.status(200).json({ success: true, data: systems });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// GET /api/unit-systems/:id
// Returns one unit system with all parameters (for right panel)
// ═══════════════════════════════════════════════════════════════════════════════
export const getUnitSystemById = async (req, res) => {
  try {
    const system = await UnitSystem.findById(req.params.id);
    if (!system) {
      return res.status(404).json({ success: false, message: "Unit system not found" });
    }
    return res.status(200).json({ success: true, data: system });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// POST /api/unit-systems
// Create a new unit system. Seeds 53 parameters from baseTemplate.
// Body: { name, baseTemplate }   ("us" | "si")
// ═══════════════════════════════════════════════════════════════════════════════
export const createUnitSystem = async (req, res) => {
  try {
    const { name, baseTemplate = "us" } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: "Name is required" });
    }

    // Get next sort order
    const count = await UnitSystem.countDocuments();

    const system = await UnitSystem.create({
      name:         name.trim(),
      baseTemplate: baseTemplate === "si" ? "si" : "us",
      parameters:   seedParameters(baseTemplate),
      sortOrder:    count,
    });

    return res.status(201).json({ success: true, message: "Unit system created", data: system });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// PUT /api/unit-systems/:id
// Full update — replaces all parameters at once (used by Save Changes button)
// Body: { name?, baseTemplate?, parameters: [ { number, name, unit }, ... ] }
// ═══════════════════════════════════════════════════════════════════════════════
export const updateUnitSystem = async (req, res) => {
  try {
    const { name, baseTemplate, parameters } = req.body;

    const update = {};
    if (name)         update.name         = name.trim();
    if (baseTemplate) update.baseTemplate = baseTemplate;
    if (parameters)   update.parameters   = parameters;

    const updated = await UnitSystem.findByIdAndUpdate(
      req.params.id,
      { $set: update },
      { new: true, runValidators: true }
    );

    if (!updated) {
      return res.status(404).json({ success: false, message: "Unit system not found" });
    }

    return res.status(200).json({ success: true, message: "Unit system updated", data: updated });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// PATCH /api/unit-systems/:id/parameter/:number
// Update a SINGLE parameter's unit — auto-called on every dropdown change
// Body: { unit }
// ═══════════════════════════════════════════════════════════════════════════════
export const updateSingleParameterUnit = async (req, res) => {
  try {
    const { id, number } = req.params;
    const { unit } = req.body;

    if (!unit) {
      return res.status(400).json({ success: false, message: "unit is required" });
    }

    // Use positional operator to update only the matching array element
    const updated = await UnitSystem.findOneAndUpdate(
      { _id: id, "parameters.number": number },
      { $set: { "parameters.$.unit": unit } },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({
        success: false,
        message: `Unit system or parameter #${number} not found`,
      });
    }

    return res.status(200).json({
      success: true,
      message: `Parameter #${number} unit updated to "${unit}"`,
      data: updated,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE /api/unit-systems/:id
// ═══════════════════════════════════════════════════════════════════════════════
export const deleteUnitSystem = async (req, res) => {
  try {
    const deleted = await UnitSystem.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ success: false, message: "Unit system not found" });
    }
    return res.status(200).json({ success: true, message: "Unit system deleted" });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ═══════════════════════════════════════════════════════════════════════════════
// POST /api/unit-systems/seed
// One-time endpoint to seed default systems (Pegasus Default 1, SI, US).
// Call once from Postman/startup. Safe to call multiple times (checks first).
// ═══════════════════════════════════════════════════════════════════════════════
export const seedDefaultSystems = async (req, res) => {
  try {
    const existing = await UnitSystem.countDocuments();
    if (existing > 0) {
      return res.status(200).json({
        success: true,
        message: `Already seeded (${existing} systems exist). No changes made.`,
      });
    }

    const defaults = [
      { name: "Pegasus Default 1", baseTemplate: "us", sortOrder: 0 },
      { name: "SI",                baseTemplate: "si", sortOrder: 1 },
      { name: "US",                baseTemplate: "us", sortOrder: 2 },
    ];

    const created = await UnitSystem.insertMany(
      defaults.map((d) => ({
        ...d,
        parameters: seedParameters(d.baseTemplate),
      }))
    );

    return res.status(201).json({
      success: true,
      message: `${created.length} default unit systems seeded`,
      data: created,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};