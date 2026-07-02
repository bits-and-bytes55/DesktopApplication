import UnitSystem from "../../modules/unitSystem/unitSystemModel.js";

const PARAMETER_NAMES = [
  "Length",
  "Pipe diameter",
  "Nozzle diameter",
  "Surface area",
  "Cross section",
  "Fluid volume",
  "Pipe capacity (volume/length)",
  "Pipe capacity (length/volume)",
  "Solid volume",
  "Small volume",
  "Stroke displacement",
  "Gas volume",
  "Velocity",
  "Nozzle velocity",
  "ROP",
  "Rotation",
  "Liquid flow rate for drilling",
  "Liquid flow rate for cementing",
  "Stroke rate",
  "Force",
  "Torque",
  "Pressure",
  "Pressure gradient",
  "Stress",
  "Yield point",
  "Power",
  "Viscosity",
  "Consistency",
  "Weight",
  "Mass rate",
  "Line density",
  "Density",
  "Mud weight",
  "Temperature",
  "Temperature gradient",
  "Schedule time",
  "Dogleg",
  "Degree",
  "Mass - volume ratio",
  "Volume - volume ratio",
  "Cement/solid additive Wt/sk",
  "Cement slurry yield",
  "Cement liquid additive/water requirement",
  "Concentration",
  "Conductivity",
  "Heat Capacity",
  "Heat transfer coefficient",
  "Temperature Drop",
  "Funnel viscosity",
];

const buildParameters = (units) =>
  PARAMETER_NAMES.map((name, index) => ({
    number: String(index + 1),
    name,
    unit: units[index],
  }));

const US_PARAMETERS = buildParameters([
  "ft",
  "in",
  "1/32in",
  "ft2",
  "in2",
  "bbl",
  "bbl/ft",
  "ft/bbl",
  "ft3",
  "in3",
  "bbl/stk",
  "scf",
  "ft/min",
  "ft/s",
  "ft/hr",
  "rpm",
  "gpm",
  "bpm",
  "stk/min",
  "lbf",
  "ft-lb",
  "psi",
  "psi/ft",
  "psi",
  "lbf/100ft2",
  "HP",
  "cP",
  "lbf-s^n/100ft2",
  "lbm",
  "lbm/min",
  "lb/ft",
  "lb/ft3",
  "ppg",
  "°F",
  "°F/100ft",
  "min",
  "°/100ft",
  "°",
  "lb/bbl",
  "gal/bbl",
  "lb/sk",
  "ft3/sk",
  "gal/sk",
  "mg/L",
  "Btu/hr/ft/°F",
  "Btu/lbm/°F",
  "Btu/hr/ft2/°F",
  "°F",
  "sec/qt",
]);

const SI_PARAMETERS = buildParameters([
  "m",
  "mm",
  "mm",
  "m2",
  "mm2",
  "m3",
  "m3/m",
  "m/m3",
  "m3",
  "L",
  "m3/stk",
  "m3",
  "m/min",
  "m/s",
  "m/hr",
  "rpm",
  "m3/min",
  "m3/min",
  "stk/min",
  "N",
  "N-m",
  "kPa",
  "kPa/m",
  "kPa",
  "Pa",
  "KW",
  "cP",
  "Pa-s^n",
  "kg",
  "kg/min",
  "kg/m",
  "kg/m3",
  "kg/m3",
  "°C",
  "°C/100m",
  "min",
  "°/30m",
  "°",
  "kg/m3",
  "L/m3",
  "kg/sk",
  "m3/sk",
  "m3/sk",
  "mg/L",
  "W/m/K",
  "KJ/kg/K",
  "W/m2/K",
  "°C",
  "sec/L",
]);

const PEGASUS_DEFAULT_1_PARAMETERS = buildParameters([
  "ft",
  "mm",
  "1/32in",
  "ft2",
  "in2",
  "bbl",
  "bbl/ft",
  "ft/bbl",
  "ft3",
  "in3",
  "bbl/stk",
  "scf",
  "ft/min",
  "ft/s",
  "ft/hr",
  "rpm",
  "gpm",
  "bpm",
  "stk/min",
  "lbf",
  "ft-lb",
  "psi",
  "psi/ft",
  "psi",
  "lbf/100ft2",
  "HP",
  "cP",
  "lbf-s^n/100ft2",
  "lbm",
  "lbm/min",
  "lb/ft",
  "lb/ft3",
  "ppg",
  "°F",
  "°F/100ft",
  "min",
  "°/100ft",
  "°",
  "lb/bbl",
  "gal/bbl",
  "lb/sk",
  "ft3/sk",
  "gal/sk",
  "mg/L",
  "Btu/hr/ft/°F",
  "Btu/lbm/°F",
  "Btu/hr/ft2/°F",
  "°F",
  "sec/qt",
]);

function seedParameters(baseTemplate, systemName = "") {
  const normalizedName = systemName.trim().toLowerCase();
  if (normalizedName === "pegasus default 1") {
    return PEGASUS_DEFAULT_1_PARAMETERS.map((parameter) => ({ ...parameter }));
  }
  if (baseTemplate === "si") {
    return SI_PARAMETERS.map((parameter) => ({ ...parameter }));
  }
  return US_PARAMETERS.map((parameter) => ({ ...parameter }));
}

export const getAllUnitSystems = async (req, res) => {
  try {
    const systems = await UnitSystem.find().sort({ sortOrder: 1, createdAt: 1 });
    return res.status(200).json({ success: true, data: systems });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

export const getUnitSystemById = async (req, res) => {
  try {
    const system = await UnitSystem.findById(req.params.id);
    if (!system) {
      return res
        .status(404)
        .json({ success: false, message: "Unit system not found" });
    }
    return res.status(200).json({ success: true, data: system });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

export const createUnitSystem = async (req, res) => {
  try {
    const { name, baseTemplate = "us" } = req.body;

    if (!name || !name.trim()) {
      return res
        .status(400)
        .json({ success: false, message: "Name is required" });
    }

    const count = await UnitSystem.countDocuments();
    const normalizedBaseTemplate = baseTemplate === "si" ? "si" : "us";

    const system = await UnitSystem.create({
      name: name.trim(),
      baseTemplate: normalizedBaseTemplate,
      parameters: seedParameters(normalizedBaseTemplate),
      sortOrder: count,
    });

    return res.status(201).json({
      success: true,
      message: "Unit system created",
      data: system,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

export const updateUnitSystem = async (req, res) => {
  try {
    const { name, baseTemplate, parameters } = req.body;

    const update = {};
    if (name) update.name = name.trim();
    if (baseTemplate) update.baseTemplate = baseTemplate;
    if (parameters) update.parameters = parameters;

    const updated = await UnitSystem.findByIdAndUpdate(
      req.params.id,
      { $set: update },
      { returnDocument: "after", runValidators: true }
    );

    if (!updated) {
      return res
        .status(404)
        .json({ success: false, message: "Unit system not found" });
    }

    return res.status(200).json({
      success: true,
      message: "Unit system updated",
      data: updated,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

export const updateSingleParameterUnit = async (req, res) => {
  try {
    const { id, number } = req.params;
    const { unit } = req.body;

    if (!unit) {
      return res
        .status(400)
        .json({ success: false, message: "unit is required" });
    }

    const updated = await UnitSystem.findOneAndUpdate(
      { _id: id, "parameters.number": number },
      { $set: { "parameters.$.unit": unit } },
      { returnDocument: "after" }
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

export const deleteUnitSystem = async (req, res) => {
  try {
    const deleted = await UnitSystem.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res
        .status(404)
        .json({ success: false, message: "Unit system not found" });
    }
    return res
      .status(200)
      .json({ success: true, message: "Unit system deleted" });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

export const seedDefaultSystems = async (req, res) => {
  try {
    const existingSystems = await UnitSystem.find().sort({
      sortOrder: 1,
      createdAt: 1,
    });

    if (existingSystems.length > 0) {
      return res.status(200).json({
        success: true,
        message: `Already seeded (${existingSystems.length} systems exist). No changes made.`,
        data: existingSystems,
      });
    }

    const defaults = [
      {
        name: "Pegasus Default 1",
        baseTemplate: "us",
        sortOrder: 0,
        parameters: seedParameters("us", "Pegasus Default 1"),
      },
      {
        name: "SI",
        baseTemplate: "si",
        sortOrder: 1,
        parameters: seedParameters("si", "SI"),
      },
      {
        name: "US",
        baseTemplate: "us",
        sortOrder: 2,
        parameters: seedParameters("us", "US"),
      },
    ];

    const created = await UnitSystem.insertMany(defaults);

    return res.status(201).json({
      success: true,
      message: `${created.length} default unit systems seeded`,
      data: created,
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};
