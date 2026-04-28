import Pad from "../../modules/pad/pad.model.js";
import Well from "../../modules/well/well.model.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const toText = (value) => String(value ?? "").trim();

const escapeRegex = (value) =>
  String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const buildPadPayload = (body = {}) => ({
  locationType: body.locationType === "Offshore" ? "Offshore" : "Land",
  fieldBlock: toText(body.fieldBlock),
  rig: toText(body.rig),
  countyParishOffshoreArea: toText(body.countyParishOffshoreArea),
  stateProvince: toText(body.stateProvince),
  country: toText(body.country),
  stockPoint: toText(body.stockPoint),
  phone: toText(body.phone),
  operator: toText(body.operator),
  operatorRep: toText(body.operatorRep),
  contractor: toText(body.contractor),
  contractorRep: toText(body.contractorRep),
  sl: toText(body.sl),
  airGap: toNumber(body.airGap),
  waterDepth: toNumber(body.waterDepth),
  riserOD: toNumber(body.riserOD),
  riserID: toNumber(body.riserID),
  chokeLineID: toNumber(body.chokeLineID),
  killLineID: toNumber(body.killLineID),
  boostLineID: toNumber(body.boostLineID),
  memo: toText(body.memo),
});

const buildPadUpdate = (body = {}) => {
  const update = {};
  const numberFields = [
    "airGap",
    "waterDepth",
    "riserOD",
    "riserID",
    "chokeLineID",
    "killLineID",
    "boostLineID",
  ];
  const textFields = [
    "fieldBlock",
    "rig",
    "countyParishOffshoreArea",
    "stateProvince",
    "country",
    "stockPoint",
    "phone",
    "operator",
    "operatorRep",
    "contractor",
    "contractorRep",
    "sl",
    "memo",
  ];

  if (body.locationType !== undefined) {
    update.locationType = body.locationType === "Offshore" ? "Offshore" : "Land";
  }

  for (const field of textFields) {
    if (body[field] !== undefined) {
      update[field] = toText(body[field]);
    }
  }

  for (const field of numberFields) {
    if (body[field] !== undefined) {
      update[field] = toNumber(body[field]);
    }
  }

  return update;
};

export const createPad = async (req, res) => {
  try {
    const pad = await Pad.create(buildPadPayload(req.body));

    return res.status(201).json({
      success: true,
      message: "Pad created successfully",
      data: pad,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create pad",
      error: error.message,
    });
  }
};

export const getPads = async (req, res) => {
  try {
    const { search = "", operator = "", country = "", includeWells = "false" } =
      req.query;
    const filter = {};

    if (operator) {
      filter.operator = { $regex: escapeRegex(operator), $options: "i" };
    }

    if (country) {
      filter.country = { $regex: escapeRegex(country), $options: "i" };
    }

    const trimmedSearch = String(search).trim();
    if (trimmedSearch) {
      const regex = { $regex: escapeRegex(trimmedSearch), $options: "i" };
      filter.$or = [
        { fieldBlock: regex },
        { rig: regex },
        { operator: regex },
        { stockPoint: regex },
      ];
    }

    const pads = await Pad.find(filter).sort({ createdAt: -1 }).lean();
    let data = pads;

    if (includeWells === "true" && pads.length) {
      const wells = await Well.find({ padId: { $in: pads.map((pad) => pad._id) } })
        .sort({ createdAt: -1 })
        .lean();

      const wellsByPadId = wells.reduce((acc, well) => {
        const key = String(well.padId);
        if (!acc[key]) acc[key] = [];
        acc[key].push(well);
        return acc;
      }, {});

      data = pads.map((pad) => ({
        ...pad,
        wells: wellsByPadId[String(pad._id)] || [],
      }));
    }

    return res.status(200).json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch pads",
      error: error.message,
    });
  }
};

export const getPadById = async (req, res) => {
  try {
    const { id } = req.params;
    const { includeWells = "false" } = req.query;

    const pad = await Pad.findById(id).lean();

    if (!pad) {
      return res.status(404).json({
        success: false,
        message: "Pad not found",
      });
    }

    let data = pad;
    if (includeWells === "true") {
      const wells = await Well.find({ padId: id }).sort({ createdAt: -1 }).lean();
      data = { ...pad, wells };
    }

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch pad",
      error: error.message,
    });
  }
};

export const updatePad = async (req, res) => {
  try {
    const { id } = req.params;
    const update = buildPadUpdate(req.body);

    if (Object.keys(update).length === 0) {
      return res.status(400).json({
        success: false,
        message: "No valid pad fields provided for update",
      });
    }

    const updatedPad = await Pad.findByIdAndUpdate(
      id,
      { $set: update },
      { new: true, runValidators: true }
    );

    if (!updatedPad) {
      return res.status(404).json({
        success: false,
        message: "Pad not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Pad updated successfully",
      data: updatedPad,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update pad",
      error: error.message,
    });
  }
};

export const deletePad = async (req, res) => {
  try {
    const { id } = req.params;

    const linkedWellCount = await Well.countDocuments({ padId: id });
    if (linkedWellCount > 0) {
      return res.status(409).json({
        success: false,
        message: "Cannot delete pad while wells are still linked to it",
        linkedWellCount,
      });
    }

    const deletedPad = await Pad.findByIdAndDelete(id);

    if (!deletedPad) {
      return res.status(404).json({
        success: false,
        message: "Pad not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Pad deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete pad",
      error: error.message,
    });
  }
};
