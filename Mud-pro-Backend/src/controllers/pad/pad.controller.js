import Pad from "../../modules/pad/pad.model.js";

export const createPad = async (req, res) => {
  try {
    const {
      locationType,
      fieldBlock,
      rig,
      countyParishOffshoreArea,
      stateProvince,
      country,
      stockPoint,
      phone,
      operator,
      operatorRep,
      contractor,
      contractorRep,
      sl,
      airGap,
      waterDepth,
      riserOD,
      riserID,
      chokeLineID,
      killLineID,
      boostLineID,
    } = req.body;

    const pad = await Pad.create({
      locationType: locationType || "Land",
      fieldBlock: fieldBlock || "",
      rig: rig || "",
      countyParishOffshoreArea: countyParishOffshoreArea || "",
      stateProvince: stateProvince || "",
      country: country || "",
      stockPoint: stockPoint || "",
      phone: phone || "",
      operator: operator || "",
      operatorRep: operatorRep || "",
      contractor: contractor || "",
      contractorRep: contractorRep || "",
      sl: sl || "",
      airGap: Number(airGap) || 0,
      waterDepth: Number(waterDepth) || 0,
      riserOD: Number(riserOD) || 0,
      riserID: Number(riserID) || 0,
      chokeLineID: Number(chokeLineID) || 0,
      killLineID: Number(killLineID) || 0,
      boostLineID: Number(boostLineID) || 0,
    });

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