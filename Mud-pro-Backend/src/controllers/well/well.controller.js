import mongoose from "mongoose";
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

export const createWell = async (req, res) => {
  try {
    const {
      padId,
      wellNameNo,
      apiWellNo,
      spudDate,
      sectionTownshipRange,
      longitude,
      latitude,
      kop,
      lp,
      bulkTankSetupFee,
    } = req.body;

    if (!padId || !wellNameNo) {
      return res.status(400).json({
        success: false,
        message: "padId and wellNameNo are required",
      });
    }

    const padExists = await Pad.findById(padId);
    if (!padExists) {
      return res.status(404).json({
        success: false,
        message: "Pad not found",
      });
    }

    const well = await Well.create({
      padId,
      wellNameNo: toText(wellNameNo),
      apiWellNo: toText(apiWellNo),
      spudDate: toText(spudDate),
      sectionTownshipRange: toText(sectionTownshipRange),
      longitude: toText(longitude),
      latitude: toText(latitude),
      kop: toNumber(kop),
      lp: toNumber(lp),
      bulkTankSetupFee: toNumber(bulkTankSetupFee),
    });

    return res.status(201).json({
      success: true,
      message: "Well created successfully",
      data: well,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create well",
      error: error.message,
    });
  }
};

export const getAllWells = async (req, res) => {
  try {
    const { padId = "", search = "", includePad = "false" } = req.query;
    const filter = {};

    if (padId) {
      if (!mongoose.Types.ObjectId.isValid(padId)) {
        return res.status(400).json({
          success: false,
          message: "Invalid padId",
        });
      }
      filter.padId = padId;
    }

    const trimmedSearch = String(search).trim();
    if (trimmedSearch) {
      const regex = { $regex: escapeRegex(trimmedSearch), $options: "i" };
      filter.$or = [
        { wellNameNo: regex },
        { apiWellNo: regex },
        { sectionTownshipRange: regex },
      ];
    }

    let query = Well.find(filter).sort({ createdAt: -1 });
    if (includePad === "true") {
      query = query.populate("padId");
    }

    const wells = await query;

    return res.status(200).json({
      success: true,
      count: wells.length,
      data: wells,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch wells",
      error: error.message,
    });
  }
};

export const getWellsByPad = async (req, res) => {
  try {
    const { padId } = req.params;

    const wells = await Well.find({ padId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: wells,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch wells",
      error: error.message,
    });
  }
};

export const getWellById = async (req, res) => {
  try {
    const { id } = req.params;

    const well = await Well.findById(id).populate("padId");

    if (!well) {
      return res.status(404).json({
        success: false,
        message: "Well not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: well,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch well",
      error: error.message,
    });
  }
};

export const updateWell = async (req, res) => {
  try {
    const { id } = req.params;

    const {
      wellNameNo,
      apiWellNo,
      spudDate,
      sectionTownshipRange,
      longitude,
      latitude,
      kop,
      lp,
      bulkTankSetupFee,
      padId,
    } = req.body;

    if (padId !== undefined) {
      if (!mongoose.Types.ObjectId.isValid(padId)) {
        return res.status(400).json({
          success: false,
          message: "Invalid padId",
        });
      }

      const padExists = await Pad.findById(padId);
      if (!padExists) {
        return res.status(404).json({
          success: false,
          message: "Pad not found",
        });
      }
    }

    const updatedWell = await Well.findByIdAndUpdate(
      id,
      {
        ...(padId !== undefined && { padId }),
        ...(wellNameNo !== undefined && { wellNameNo: toText(wellNameNo) }),
        ...(apiWellNo !== undefined && { apiWellNo: toText(apiWellNo) }),
        ...(spudDate !== undefined && { spudDate: toText(spudDate) }),
        ...(sectionTownshipRange !== undefined && {
          sectionTownshipRange: toText(sectionTownshipRange),
        }),
        ...(longitude !== undefined && { longitude: toText(longitude) }),
        ...(latitude !== undefined && { latitude: toText(latitude) }),
        ...(kop !== undefined && { kop: toNumber(kop) }),
        ...(lp !== undefined && { lp: toNumber(lp) }),
        ...(bulkTankSetupFee !== undefined && {
          bulkTankSetupFee: toNumber(bulkTankSetupFee),
        }),
      },
      { new: true }
    );

    if (!updatedWell) {
      return res.status(404).json({
        success: false,
        message: "Well not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Well updated successfully",
      data: updatedWell,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update well",
      error: error.message,
    });
  }
};

export const deleteWell = async (req, res) => {
  try {
    const { id } = req.params;

    const deletedWell = await Well.findByIdAndDelete(id);

    if (!deletedWell) {
      return res.status(404).json({
        success: false,
        message: "Well not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Well deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete well",
      error: error.message,
    });
  }
};
