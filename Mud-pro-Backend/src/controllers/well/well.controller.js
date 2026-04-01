import Pad from "../../modules/pad/pad.model.js";
import Well from "../../modules/well/well.model.js";

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
      wellNameNo: wellNameNo.trim(),
      apiWellNo: apiWellNo || "",
      spudDate: spudDate || "",
      sectionTownshipRange: sectionTownshipRange || "",
      longitude: longitude || "",
      latitude: latitude || "",
      kop: Number(kop) || 0,
      lp: Number(lp) || 0,
      bulkTankSetupFee: Number(bulkTankSetupFee) || 0,
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
    } = req.body;

    const updatedWell = await Well.findByIdAndUpdate(
      id,
      {
        ...(wellNameNo !== undefined && { wellNameNo: wellNameNo.trim() }),
        ...(apiWellNo !== undefined && { apiWellNo }),
        ...(spudDate !== undefined && { spudDate }),
        ...(sectionTownshipRange !== undefined && { sectionTownshipRange }),
        ...(longitude !== undefined && { longitude }),
        ...(latitude !== undefined && { latitude }),
        ...(kop !== undefined && { kop: Number(kop) || 0 }),
        ...(lp !== undefined && { lp: Number(lp) || 0 }),
        ...(bulkTankSetupFee !== undefined && {
          bulkTankSetupFee: Number(bulkTankSetupFee) || 0,
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