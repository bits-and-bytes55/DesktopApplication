import Premixed from "../../modules/inventory/premixed.model.js";
import ReceiveMud from "../../modules/receivemud/ReceiveMud.js";
import { buildScopedFilter, readReportId } from "../../utils/reportScope.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(n) ? n : 0;
};

const round2 = (num) => Number(num.toFixed(2));
const getWellId = (req) => String(req.params.wellId || "").trim();

const findPremixedMud = async (wellId, premixedMud) => {
  return await Premixed.findOne({
    wellId,
    description: { $regex: `^${String(premixedMud).trim()}$`, $options: "i" },
  });
};

const applyVolumeToPit = async ({
  wellId,
  reportId,
  to,
  netVolume,
  mw,
  mudType,
}) => {
  return;
};

const revertVolumeFromPit = async ({ wellId, reportId, to, netVolume }) => {
  return;
};

const prepareReceiveMudData = async (wellId, reportId, payload) => {
  const {
    bolNo,
    premixedMud,
    mw,
    mudType,
    leasingFee,
    from,
    to,
    volume,
    leased,
    lossVolume,
    operationInstanceKey,
  } = payload;

  if (!wellId || !premixedMud || !to || volume === undefined || volume === null) {
    throw new Error("wellId, premixedMud, to and volume are required");
  }

  const grossVolume = round2(toNumber(volume));
  const loss = round2(toNumber(lossVolume));
  const netVolume = round2(grossVolume - loss);

  if (grossVolume < 0) {
    throw new Error("Volume cannot be negative");
  }

  if (loss < 0 || loss > grossVolume) {
    throw new Error("Loss Volume must be between 0 and volume");
  }

  const premixed = await findPremixedMud(wellId, premixedMud);

  if (!premixed) {
    throw new Error(`Premixed mud '${premixedMud}' not found for this well`);
  }

  const finalMw =
    mw !== undefined && mw !== null && mw !== ""
      ? round2(toNumber(mw))
      : round2(toNumber(premixed.mw));

  const finalMudType =
    mudType !== undefined && mudType !== null && mudType !== ""
      ? mudType
      : premixed.mudType || "";

  const finalLeasingFee =
    leasingFee !== undefined && leasingFee !== null && leasingFee !== ""
      ? round2(toNumber(leasingFee))
      : round2(toNumber(premixed.leasingFee));

  return {
    wellId,
    reportId,
    bolNo: bolNo || "",
    premixedMud: String(premixedMud).trim(),
    mw: finalMw,
    mudType: finalMudType,
    leasingFee: finalLeasingFee,
    from: from || "",
    to: String(to).trim(),
    volume: grossVolume,
    leased: leased === true || leased === "true",
    lossVolume: loss,
    operationInstanceKey: String(operationInstanceKey || "").trim(),
    netVolume,
  };
};

export const createReceiveMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Receive Mud",
      });
    }
    const payloads = Array.isArray(req.body) ? req.body : [req.body];

    if (!payloads.length) {
      return res.status(400).json({
        success: false,
        message: "Request body is empty",
      });
    }

    const createdItems = [];

    for (const payload of payloads) {
      const prepared = await prepareReceiveMudData(wellId, reportId, payload);

      await applyVolumeToPit({
        wellId,
        reportId,
        to: prepared.to,
        netVolume: prepared.netVolume,
        mw: prepared.mw,
        mudType: prepared.mudType,
      });

      const item = await ReceiveMud.create(prepared);
      createdItems.push(item);
    }

    return res.status(201).json({
      success: true,
      message:
        createdItems.length === 1
          ? "Receive Mud saved successfully"
          : "Multiple Receive Mud records saved successfully",
      count: createdItems.length,
      data: createdItems,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to save Receive Mud",
      error: error.message,
    });
  }
};

export const getReceiveMudList = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: [],
      });
    }

    const items = await ReceiveMud.find(
      buildScopedFilter(wellId, reportId)
    ).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      count: items.length,
      data: items,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Receive Mud records",
      error: error.message,
    });
  }
};

export const getReceiveMudById = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Receive Mud",
      });
    }
    const { id } = req.params;

    const item = await ReceiveMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: "Receive Mud record not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: item,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch Receive Mud record",
      error: error.message,
    });
  }
};

export const updateReceiveMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Receive Mud",
      });
    }
    const { id } = req.params;

    const existing = await ReceiveMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Mud record not found",
      });
    }

    await revertVolumeFromPit({
      wellId,
      reportId,
      to: existing.to,
      netVolume: toNumber(existing.netVolume),
    });

    const mergedPayload = {
      bolNo: req.body.bolNo ?? existing.bolNo,
      premixedMud: req.body.premixedMud ?? existing.premixedMud,
      mw: req.body.mw ?? existing.mw,
      mudType: req.body.mudType ?? existing.mudType,
      leasingFee: req.body.leasingFee ?? existing.leasingFee,
      from: req.body.from ?? existing.from,
      to: req.body.to ?? existing.to,
      volume: req.body.volume ?? existing.volume,
      leased: req.body.leased ?? existing.leased,
      lossVolume: req.body.lossVolume ?? existing.lossVolume,
      operationInstanceKey:
        req.body.operationInstanceKey ?? existing.operationInstanceKey ?? "",
    };

    const prepared = await prepareReceiveMudData(wellId, reportId, mergedPayload);

    await applyVolumeToPit({
      wellId,
      reportId,
      to: prepared.to,
      netVolume: prepared.netVolume,
      mw: prepared.mw,
      mudType: prepared.mudType,
    });

    existing.bolNo = prepared.bolNo;
    existing.premixedMud = prepared.premixedMud;
    existing.mw = prepared.mw;
    existing.mudType = prepared.mudType;
    existing.leasingFee = prepared.leasingFee;
    existing.from = prepared.from;
    existing.to = prepared.to;
    existing.volume = prepared.volume;
    existing.leased = prepared.leased;
    existing.lossVolume = prepared.lossVolume;
    existing.netVolume = prepared.netVolume;
    existing.reportId = prepared.reportId;
    existing.operationInstanceKey = prepared.operationInstanceKey;

    await existing.save();

    return res.status(200).json({
      success: true,
      message: "Receive Mud updated successfully",
      data: existing,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update Receive Mud",
      error: error.message,
    });
  }
};

export const deleteReceiveMud = async (req, res) => {
  try {
    const wellId = getWellId(req);
    const reportId = readReportId(req);
    if (!reportId) {
      return res.status(400).json({
        success: false,
        message: "reportId is required for Receive Mud",
      });
    }
    const { id } = req.params;

    const existing = await ReceiveMud.findOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Receive Mud record not found",
      });
    }

    await revertVolumeFromPit({
      wellId,
      reportId,
      to: existing.to,
      netVolume: toNumber(existing.netVolume),
    });

    await ReceiveMud.deleteOne({
      _id: id,
      ...buildScopedFilter(wellId, reportId),
    });

    return res.status(200).json({
      success: true,
      message: "Receive Mud deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to delete Receive Mud",
      error: error.message,
    });
  }
};
