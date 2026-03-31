import WellGeneral from "../../modules/wellGeneral/wellGeneralModel.js";
import Casing from "../../modules/casing/casing.model.js";
import Pit from "../../modules/pit/pit.model.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const calculateHoleVolume = (idInInches, mdInFeet) => {
  const id = toNumber(idInInches);
  const md = toNumber(mdInFeet);

  if (id <= 0 || md <= 0) return 0;

  return Number(((id * id * md) / 1029.4).toFixed(2));
};

// ------------------ SAVE WELL GENERAL ------------------
export const createWellGeneral = async (req, res) => {
  try {
    const {
      wellId,
      reportNo,
      userReportNo,
      date,
      time,
      engineer,
      engineer2,
      operatorRep,
      contractorRep,
      activity,
      md,
      tvd,
      inc,
      azi,
      wob,
      rotWt,
      soWt,
      puWt,
      rpm,
      rop,
      offBottomTq,
      onBottomTq,
      suctionT,
      bottomT,
      interval,
      fit,
      formation,
      additionalFootage,
      nptTime,
      nptCost,
      depthDrilled,
    } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const item = await WellGeneral.create({
      wellId: String(wellId).trim(),
      reportNo: reportNo || "",
      userReportNo: userReportNo || "",
      date: date || "",
      time: time || "",
      engineer: engineer || "",
      engineer2: engineer2 || "",
      operatorRep: operatorRep || "",
      contractorRep: contractorRep || "",
      activity: activity || "",
      md: Number(md) || 0,
      tvd: Number(tvd) || 0,
      inc: Number(inc) || 0,
      azi: Number(azi) || 0,
      wob: Number(wob) || 0,
      rotWt: Number(rotWt) || 0,
      soWt: Number(soWt) || 0,
      puWt: Number(puWt) || 0,
      rpm: Number(rpm) || 0,
      rop: Number(rop) || 0,
      offBottomTq: Number(offBottomTq) || 0,
      onBottomTq: Number(onBottomTq) || 0,
      suctionT: Number(suctionT) || 0,
      bottomT: Number(bottomT) || 0,
      interval: interval || "",
      fit: fit || "",
      formation: formation || "",
      additionalFootage: Number(additionalFootage) || 0,
      nptTime: Number(nptTime) || 0,
      nptCost: Number(nptCost) || 0,
      depthDrilled: Number(depthDrilled) || 0,
    });

    return res.status(201).json({
      success: true,
      message: "Well general saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ SAVE CASING ------------------
export const createCasing = async (req, res) => {
  try {
    const {
      wellId,
      description,
      type,
      od,
      wt,
      id,
      top,
      shoe,
      bit,
      toc,
    } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const item = await Casing.create({
      wellId: String(wellId).trim(),
      description: description || "",
      type: type || "",
      od: od || "",
      wt: wt || "",
      id: id || "",
      top: top || "",
      shoe: shoe || "",
      bit: bit || "",
      toc: toc || "",
    });

    return res.status(201).json({
      success: true,
      message: "Casing saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ SAVE PIT ------------------
export const createPit = async (req, res) => {
  try {
    const {
      wellId,
      pitName,
      capacity,
      initialActive,
      volume,
      density,
      fluidType,
      reportId,
      isLocked,
    } = req.body;

    if (!wellId || !pitName) {
      return res.status(400).json({
        success: false,
        message: "wellId and pitName are required",
      });
    }

    const item = await Pit.create({
      wellId: String(wellId).trim(),
      pitName: pitName.trim(),
      capacity: Number(capacity) || 0,
      initialActive: initialActive === true || initialActive === "true",
      volume: Number(volume) || 0,
      density: Number(density) || 0,
      fluidType: fluidType || "",
      reportId: reportId || "",
      isLocked: isLocked === true || isLocked === "true",
    });

    return res.status(201).json({
      success: true,
      message: "Pit saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ SAVE CONSUME PRODUCT ------------------
export const createConsumeProduct = async (req, res) => {
  try {
    const {
      wellId,
      product,
      code,
      sg,
      unit,
      price,
      initial,
      adjust,
      used,
      final,
      cost,
      volumeBbl,
    } = req.body;

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const item = await ConsumeProduct.create({
      wellId: String(wellId).trim(),
      product: product || "",
      code: code || "",
      sg: sg === null || sg === undefined || sg === "" ? null : Number(sg),
      unit: unit || "",
      price: Number(price) || 0,
      initial: Number(initial) || 0,
      adjust: Number(adjust) || 0,
      used: Number(used) || 0,
      final: Number(final) || 0,
      cost: Number(cost) || 0,
      volumeBbl: Number(volumeBbl) || 0,
    });

    return res.status(201).json({
      success: true,
      message: "Consume product saved successfully",
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ------------------ GET VOLUME NAME ------------------
export const getVolumeNameCalculation = async (req, res) => {
  try {
    const wellId = String(req.params.wellId).trim();

    if (!wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const wellGeneral = await WellGeneral.findOne({ wellId }).sort({ createdAt: -1 });
    const casings = await Casing.find({ wellId }).sort({ createdAt: 1 });
    const pits = await Pit.find({ wellId }).sort({ createdAt: 1 });
    const consumeProducts = await ConsumeProduct.find({ wellId }).sort({ createdAt: 1 });

    const md = toNumber(wellGeneral?.md);

    const validCasings = casings.filter((row) => toNumber(row.id) > 0);
    const latestCasing = validCasings.length
      ? validCasings[validCasings.length - 1]
      : null;

    const casingId = toNumber(latestCasing?.id);
    const hole = calculateHoleVolume(casingId, md);

    const activePitsList = pits.filter((pit) => pit.initialActive === true);
    const storagePitsList = pits.filter((pit) => pit.initialActive === false);

    let activePits = Number(
  activePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
);

const totalStorage = Number(
  storagePitsList.reduce((sum, pit) => sum + toNumber(pit.volume), 0).toFixed(2)
);

let activeSystem = Number((activePits + hole).toFixed(2));
let endVol = Number((activeSystem - totalStorage).toFixed(2));
let endVolMinusActiveSystem = Number((endVol - activeSystem).toFixed(2));

// ✅ agar negative aaye to utna activePits me add karo
if (endVolMinusActiveSystem < 0) {
  const adjustment = Math.abs(endVolMinusActiveSystem);

  activePits = Number((activePits + adjustment).toFixed(2));
  activeSystem = Number((activePits + hole).toFixed(2));
  endVol = Number((activeSystem - totalStorage).toFixed(2));

  // tumhari requirement ke hisaab se final 0 fix kar diya
  endVolMinusActiveSystem = 0;
}

    const totalOnLocation = Number(
      consumeProducts.reduce((sum, item) => sum + toNumber(item.volumeBbl), 0).toFixed(2)
    );

    const heldVolDifference = Number((totalOnLocation - activeSystem).toFixed(2));

    return res.status(200).json({
      success: true,
      message: "Volume Name calculation fetched successfully",
      data: {
        wellId,
        general: {
          md,
        },
        casing: {
          id: casingId,
          description: latestCasing?.description || "",
        },
        volumeName: {
          heldVolDifference,
          hole,
          activePits,
          activeSystem,
          endVol,
          endVolMinusActiveSystem,
          totalStorage,
          totalOnLocation,
        },
        activePitsTable: activePitsList.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
          measuredVol: toNumber(pit.volume),
          mw: toNumber(pit.density),
          mud: pit.fluidType || "",
        })),
        storageTable: storagePitsList.map((pit) => ({
          _id: pit._id,
          pitName: pit.pitName,
          calculatedVol: 0,
          measuredVol: toNumber(pit.volume),
          mw: toNumber(pit.density),
          fluidType: pit.fluidType || "",
        })),
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to calculate volume name data",
      error: error.message,
    });
  }
};