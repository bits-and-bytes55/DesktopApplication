import UnitSystem from "../../modules/unitSystem/unitSystemModel.js";

// ─── SEED DATA ────────────────────────────────────────────────────────────────
// Full 53-parameter list with US Oil Field defaults.
// Used when creating a new system from the "us" base template.
const US_PARAMETERS = [
  { number: "1",  name: "Length",                                  unit: "ft" },
  { number: "2",  name: "Pipe diameter",                           unit: "in" },
  { number: "3",  name: "Nozzle diameter",                         unit: "in" },
  { number: "4",  name: "Surface area",                            unit: "ft²" },
  { number: "5",  name: "Cross section",                           unit: "in²" },
  { number: "6",  name: "Fluid volume",                            unit: "bbl" },
  { number: "7",  name: "Pipe capacity (volume/length)",           unit: "bbl/ft" },
  { number: "8",  name: "Pipe capacity (length/volume)",           unit: "ft/bbl" },
  { number: "9",  name: "Solid volume",                            unit: "ft³" },
  { number: "10", name: "Small volume",                            unit: "in³" },
  { number: "11", name: "Stroke displacement",                    unit: "bbl/stk" },
  { number: "12", name: "Gas volume",                              unit: "scf" },
  { number: "13", name: "Velocity",                                unit: "ft/min" },
  { number: "14", name: "Nozzle velocity",                        unit: "ft/s" },
  { number: "15", name: "ROP",                                     unit: "ft/hr" },
  { number: "16", name: "Rotation",                                unit: "rpm" },
  { number: "17", name: "Liquid flow rate for drilling",           unit: "gpm" },
  { number: "18", name: "Liquid flow rate for cementing",          unit: "bpm" },
  { number: "19", name: "Stroke rate",                             unit: "stk/min" },
  { number: "20", name: "Force",                                    unit: "lbf" },
  { number: "21", name: "Torque",                                   unit: "ft-lb" },
  { number: "22", name: "Pressure",                                unit: "psi" },
  { number: "23", name: "Pressure gradient",                       unit: "psi/ft" },
  { number: "24", name: "Stress",                                  unit: "kPa" },
  { number: "25", name: "Yield point",                             unit: "lbf/100ft²" },
  { number: "26", name: "Power",                                    unit: "HP" },
  { number: "27", name: "Viscosity",                               unit: "cP" },
  { number: "28", name: "Consistency",                             unit: "lbf-s^n/100ft²" },
  { number: "29", name: "Weight",                                   unit: "lbm" },
  { number: "30", name: "Mass rate",                               unit: "lbm/min" },
  { number: "31", name: "Line density",                            unit: "lb/ft" },
  { number: "32", name: "Density",                                 unit: "lb/ft³" },
  { number: "33", name: "Mud weight",                              unit: "ppg" },
  { number: "34", name: "Temperature",                             unit: "°F" },
  { number: "35", name: "Temperature gradient",                    unit: "°C/100m" },
  { number: "36", name: "Schedule time",                           unit: "min" },
  { number: "37", name: "Dogleg",                                  unit: "°/100ft" },
  { number: "38", name: "Degree",                                  unit: "°" },
  { number: "39", name: "Mass - volume ratio",                     unit: "lb/bbl" },
  { number: "40", name: "Volume - volume ratio",                   unit: "gal/bbl" },
  { number: "41", name: "Cement/solid additive Wt/sk",             unit: "lb/sk" },
  { number: "42", name: "Cement slurry yield",                     unit: "ft³/sk" },
  { number: "43", name: "Cement liquid additive/water requirement", unit: "gal/sk" },
  { number: "44", name: "Concentration",                           unit: "mg/L" },
  { number: "45", name: "Conductivity",                            unit: "Btu/hr/ft/°F" },
  { number: "46", name: "Heat Capacity",                           unit: "Btu/lbm/°F" },
  { number: "47", name: "Heat transfer coefficient",              unit: "Btu/hr/ft²/°F" },
  { number: "48", name: "Temperature Drop",                        unit: "°F" },
  { number: "49", name: "Funnel viscosity",                        unit: "sec/qt" },
];

const SI_PARAMETERS = [
  { number: "1",  name: "Length",                                  unit: "m" },
  { number: "2",  name: "Pipe diameter",                           unit: "mm" },
  { number: "3",  name: "Nozzle diameter",                         unit: "mm" },
  { number: "4",  name: "Surface area",                            unit: "m²" },
  { number: "5",  name: "Cross section",                           unit: "mm²" },
  { number: "6",  name: "Fluid volume",                            unit: "m³" },
  { number: "7",  name: "Pipe capacity (volume/length)",           unit: "m³/m" },
  { number: "8",  name: "Pipe capacity (length/volume)",           unit: "m/m³" },
  { number: "9",  name: "Solid volume",                            unit: "m³" },
  { number: "10", name: "Small volume",                            unit: "L" },
  { number: "11", name: "Stroke displacement",                    unit: "m³/stk" },
  { number: "12", name: "Gas volume",                              unit: "m³" },
  { number: "13", name: "Velocity",                                unit: "m/min" },
  { number: "14", name: "Nozzle velocity",                        unit: "m/s" },
  { number: "15", name: "ROP",                                     unit: "m/hr" },
  { number: "16", name: "Rotation",                                unit: "rpm" },
  { number: "17", name: "Liquid flow rate for drilling",           unit: "m³/min" },
  { number: "18", name: "Liquid flow rate for cementing",          unit: "m³/min" },
  { number: "19", name: "Stroke rate",                             unit: "stk/min" },
  { number: "20", name: "Force",                                    unit: "N" },
  { number: "21", name: "Torque",                                   unit: "N-m" },
  { number: "22", name: "Pressure",                                unit: "kPa" },
  { number: "23", name: "Pressure gradient",                       unit: "kPa/m" },
  { number: "24", name: "Stress",                                  unit: "kPa" },
  { number: "25", name: "Yield point",                             unit: "Pa" },
  { number: "26", name: "Power",                                    unit: "KW" },
  { number: "27", name: "Viscosity",                               unit: "cP" },
  { number: "28", name: "Consistency",                             unit: "Pa-s^n" },
  { number: "29", name: "Weight",                                   unit: "kg" },
  { number: "30", name: "Mass rate",                               unit: "kg/min" },
  { number: "31", name: "Line density",                            unit: "kg/m" },
  { number: "32", name: "Density",                                 unit: "kg/m³" },
  { number: "33", name: "Mud weight",                              unit: "kg/m³" },
  { number: "34", name: "Temperature",                             unit: "°C" },
  { number: "35", name: "Temperature gradient",                    unit: "°C/100m" },
  { number: "36", name: "Schedule time",                           unit: "min" },
  { number: "37", name: "Dogleg",                                  unit: "°/30m" },
  { number: "38", name: "Degree",                                  unit: "°" },
  { number: "39", name: "Mass - volume ratio",                     unit: "kg/m³" },
  { number: "40", name: "Volume - volume ratio",                   unit: "gal/bbl" },
  { number: "41", name: "Cement/solid additive Wt/sk",             unit: "kg/sk" },
  { number: "42", name: "Cement slurry yield",                     unit: "m³/sk" },
  { number: "43", name: "Cement liquid additive/water requirement", unit: "m³/sk" },
  { number: "44", name: "Concentration",                           unit: "mg/L" },
  { number: "45", name: "Conductivity",                            unit: "W/m/K" },
  { number: "46", name: "Heat Capacity",                           unit: "J/kg/°C" },
  { number: "47", name: "Heat transfer coefficient",              unit: "W/m²/K" },
  { number: "48", name: "Temperature Drop",                        unit: "°C" },
  { number: "49", name: "Funnel viscosity",                        unit: "sec/L" },
];

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