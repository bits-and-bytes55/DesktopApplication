import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import { legacyReportScope, readReportId } from "../../utils/reportScope.js";

const toNumber = (value, fallback = 0) => {
  const numericValue = Number(value);
  return Number.isFinite(numericValue) ? numericValue : fallback;
};

const round = (value, digits = 3) => {
  if (!Number.isFinite(value)) return 0;
  return Number(value.toFixed(digits));
};

const parseUnitValue = (unitValue = "") => {
  if (unitValue && typeof unitValue === "object") {
    const num = unitValue.Num ?? unitValue.num ?? "";
    const unitClass = unitValue.Class ?? unitValue.class ?? "";
    unitValue = `${num} ${unitClass}`.trim();
  }

  const rawValue = String(unitValue ?? "").trim();
  const match = rawValue.match(/^([0-9]*\.?[0-9]+)\s*([a-zA-Z]+)/);

  return {
    amount: match ? Math.max(toNumber(match[1], 1), 1) : 1,
    unitClass: (match?.[2] ?? rawValue).trim().toLowerCase(),
  };
};

const calculateVolumeBbl = ({ used = 0, unit = "", sg = 0 }) => {
  const quantity = toNumber(used);
  const density = toNumber(sg);

  if (quantity <= 0) return 0;

  const { amount, unitClass } = parseUnitValue(unit);
  const totalUnits = quantity * amount;

  if (unitClass.includes("gal")) {
    return totalUnits / 42;
  }

  if (unitClass.includes("bbl")) {
    return totalUnits;
  }

  if (unitClass.includes("kg")) {
    return density > 0 ? totalUnits / (density * 158.987) : 0;
  }

  if (
    unitClass === "lb" ||
    unitClass === "lbs" ||
    unitClass === "lbm" ||
    unitClass.includes("pound")
  ) {
    return density > 0 ? totalUnits / (density * 350) : 0;
  }

  if (
    unitClass === "ton" ||
    unitClass === "tons" ||
    unitClass === "tonne" ||
    unitClass === "tonnes" ||
    unitClass === "mt"
  ) {
    return density > 0 ? (totalUnits * 2000) / (density * 350) : 0;
  }

  if (
    unitClass === "l" ||
    unitClass === "ltr" ||
    unitClass === "liter" ||
    unitClass === "liters" ||
    unitClass === "litre" ||
    unitClass === "litres"
  ) {
    return totalUnits / 158.987;
  }

  if (unitClass === "ml") {
    return totalUnits / 158987;
  }

  if (unitClass === "m3" || unitClass === "m^3") {
    return totalUnits * 6.28981;
  }

  return density > 0 ? totalUnits / (density * 158.987) : 0;
};

const buildConsumeProductPayload = (payload = {}, existing = {}) => {
  const unit = payload.unit ?? payload.productUnit ?? existing.unit ?? "";
  const initial = toNumber(payload.initial ?? existing.initial);
  const adjust = toNumber(payload.adjust ?? existing.adjust);
  const used = toNumber(payload.used ?? existing.used);
  const price = toNumber(payload.price ?? existing.price);
  const sg = toNumber(payload.sg ?? existing.sg, 1);

  return {
    wellId: String(payload.wellId ?? existing.wellId ?? "").trim(),
    reportId: String(payload.reportId ?? existing.reportId ?? "").trim(),
    product: String(payload.product ?? existing.product ?? "").trim(),
    code: String(payload.code ?? existing.code ?? "").trim(),
    sg,
    unit: String(unit ?? "").trim(),
    price,
    initial,
    adjust,
    used,
    final: round(initial - adjust - used),
    cost: round(used * price),
    volumeBbl: round(calculateVolumeBbl({ used, unit, sg })),
  };
};

/**
 * @desc    Create Consume Product (With Auto Calculation)
 */
export const createConsumeProduct = async (req, res) => {
  try {
    const consumeProductPayload = buildConsumeProductPayload({
      ...req.body,
      reportId: req.body.reportId ?? readReportId(req),
    });

    if (!consumeProductPayload.wellId) {
      return res.status(400).json({
        success: false,
        message: "wellId is required",
      });
    }

    const consumeProduct = await ConsumeProduct.create({
      ...consumeProductPayload,
    });

    res.status(201).json({
      success: true,
      message: "Consume Product created successfully",
      data: consumeProduct
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


/**
 * @desc    Get All Consume Products
 * ✅ FIX: populate() hata diya — product ab String hai, ObjectId ref nahi
 */
export const getAllConsumeProducts = async (req, res) => {
  try {
    const filter = {};
    const wellId = String(req.query.wellId ?? "").trim();
    const reportId = String(req.query.reportId ?? "").trim();

    if (wellId) {
      filter.wellId = wellId;
    }
    if (reportId) {
      filter.reportId = reportId;
    }

    let products;

    if (wellId && reportId) {
      products = await ConsumeProduct.find({ wellId, reportId }).sort({
        createdAt: 1,
        _id: 1,
      });

      if (products.length === 0) {
        products = await ConsumeProduct.find({
          wellId,
          ...legacyReportScope(),
        }).sort({
          createdAt: 1,
          _id: 1,
        });
      }
    } else {
      products = await ConsumeProduct.find(filter).sort({
        createdAt: 1,
        _id: 1,
      });
    }

    res.status(200).json({
      success: true,
      count: products.length,
      data: products,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};


/**
 * @desc    Get Single Consume Product
 */
export const getConsumeProductById = async (req, res) => {
  try {
    const product = await ConsumeProduct.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: "Consume Product not found" });
    }

    res.status(200).json({ success: true, data: product });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};


/**
 * @desc    Update Consume Product (With Recalculation)
 */
export const updateConsumeProduct = async (req, res) => {
  try {
    const existing = await ConsumeProduct.findById(req.params.id);

    if (!existing) {
      return res.status(404).json({ success: false, message: "Consume Product not found" });
    }

    const updatedPayload = buildConsumeProductPayload(
      {
        ...req.body,
        reportId: req.body.reportId ?? readReportId(req),
      },
      existing
    );

    if (!updatedPayload.wellId) {
      updatedPayload.wellId = String(existing.wellId ?? "").trim();
    }

    const updatedProduct = await ConsumeProduct.findByIdAndUpdate(
      req.params.id,
      {
        ...updatedPayload,
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Consume Product updated successfully",
      data: updatedProduct,
    });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};


/**
 * @desc    Delete Consume Product
 */
export const deleteConsumeProduct = async (req, res) => {
  try {
    const product = await ConsumeProduct.findByIdAndDelete(req.params.id);

    if (!product) {
      return res.status(404).json({ success: false, message: "Consume Product not found" });
    }

    res.status(200).json({ success: true, message: "Consume Product deleted successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
