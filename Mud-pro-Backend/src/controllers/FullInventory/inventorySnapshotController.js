import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveProduct from "../../modules/ReceiveProduct/Product/ReceiveProduct.js";
import ReturnProduct from "../../modules/ReturnProduct/Product/ReturnProduct.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import Package from "../../modules/ConsumeServices/Package/Package.js";
import ReceivePackage from "../../modules/ReceiveProduct/Package/ReceivePackage.js";
import ReturnPackage from "../../modules/ReturnProduct/Package/ReturnPackage.js";
import UgInventorySnapshot from "../../modules/ugInventory/ugInventoryProductModel.js";
import Well from "../../modules/well/well.model.js";

const toNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const parsed = Number(String(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(parsed) ? parsed : 0;
};

const round2 = (value) => Number(toNumber(value).toFixed(2));

const normalizeText = (value) => String(value || "").trim().toLowerCase();

const keyFromCodeOrName = (code, name, fallback) => {
  const cleanCode = normalizeText(code);
  if (cleanCode) return `code:${cleanCode}`;

  const cleanName = normalizeText(name);
  if (cleanName) return `name:${cleanName}`;

  return fallback;
};

const readWellId = (req) =>
  String(req.query.wellId || req.body?.wellId || "").trim();

const summaryFromRows = (rows = []) => {
  const first = rows[0] || {};
  return {
    subtotal: round2(rows.reduce((sum, row) => sum + toNumber(row.subtotal), 0)),
    taxRate: round2(first.taxRate),
    taxAmount: round2(first.taxAmount),
    dailyTotal: round2(first.dailyTotal || first.totalDollar),
    prevTotal: round2(first.prevTotal),
    cumTotal: round2(first.cumTotal || first.totalDollar),
    intervalTotal: round2(first.intervalTotal),
    stockBalance: round2(first.stockBalance),
    bulkTankSetupFee: round2(first.bulkTankSetupFee),
  };
};

const isVolumeNameWaterHelper = (item) =>
  normalizeText(item.product) === "water" &&
  normalizeText(item.code) === "" &&
  normalizeText(item.unit) === "" &&
  toNumber(item.price) === 0 &&
  toNumber(item.initial) === 0 &&
  toNumber(item.adjust) === 0 &&
  toNumber(item.used) === 0 &&
  toNumber(item.final) === 0 &&
  toNumber(item.cost) === 0 &&
  toNumber(item.volumeBbl) > 0;

export const generateInventorySnapshot = async (req, res) => {
  try {
    const wellId = readWellId(req);
    console.log(
      `[BACKEND] Starting generateInventorySnapshot for wellId=${wellId || "global"}`
    );

    const consumeFilter = wellId ? { wellId } : {};
    const rawConsumes = await ConsumeProduct.find(consumeFilter).lean();
    const consumes = rawConsumes.filter((item) => !isVolumeNameWaterHelper(item));

    const receives = await ReceiveProduct.find().lean();
    const returns = await ReturnProduct.find().lean();
    const services = await Service.find().lean();
    const engineering = await Engineering.find().lean();
    const packages = await Package.find().lean();
    const packageReceives = await ReceivePackage.find().lean();
    const packageReturns = await ReturnPackage.find().lean();

    const existingRows = await InventorySnapshot.find(
      wellId ? { wellId } : {}
    ).sort({ createdAt: -1 });
    const previousDailyTotal = round2(existingRows[0]?.dailyTotal || 0);

    const inventoryConfig = wellId
      ? await UgInventorySnapshot.findOne({ wellId }).sort({ updatedAt: -1 }).lean()
      : null;
    const wellConfig = wellId ? await Well.findById(wellId).lean() : null;

    const taxRate = round2(inventoryConfig?.taxRate);
    const bulkTankSetupFee = round2(
      inventoryConfig?.bulkTankSetupFee || wellConfig?.bulkTankSetupFee
    );

    let snapshotData = [];

    const productKeys = [
      ...new Set([
        ...receives.map((row, index) =>
          keyFromCodeOrName(row.code, row.productName, `receive:${index}`)
        ),
        ...consumes.map((row, index) =>
          keyFromCodeOrName(row.code, row.product, `consume:${index}`)
        ),
        ...returns.map((row, index) =>
          keyFromCodeOrName(row.code, row.productName, `return:${index}`)
        ),
      ]),
    ];

    for (const key of productKeys) {
      const productReceives = receives.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.productName, `receive:${index}`) === key
      );
      const productConsumes = consumes.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.product, `consume:${index}`) === key
      );
      const productReturns = returns.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.productName, `return:${index}`) === key
      );

      const cumulativeRec = round2(
        productReceives.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeUsed = round2(
        productConsumes.reduce((sum, row) => sum + toNumber(row.used), 0)
      );
      const cumulativeRet = round2(
        productReturns.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeAdj = round2(
        productConsumes.reduce((sum, row) => sum + toNumber(row.adjust), 0)
      );

      const price = round2(productConsumes[0]?.price);
      const initial = round2(productConsumes[0]?.initial);

      const itemName =
        productReceives[0]?.productName ||
        productConsumes[0]?.product ||
        productReturns[0]?.productName ||
        "";

      const code =
        productReceives[0]?.code ||
        productConsumes[0]?.code ||
        productReturns[0]?.code ||
        "";

      const unit =
        productReceives[0]?.unit ||
        productConsumes[0]?.unit ||
        productReturns[0]?.unit ||
        "";

      const finalVal = round2(
        initial + cumulativeRec - cumulativeRet - cumulativeUsed + cumulativeAdj
      );
      const subtotal = round2(cumulativeUsed * price);

      snapshotData.push({
        wellId,
        category: "Product",
        itemName,
        code,
        unit,
        price,
        cumulativeRec,
        cumulativeRet,
        cumulativeUsed,
        initial,
        rec: cumulativeRec,
        ret: cumulativeRet,
        adj: cumulativeAdj,
        used: cumulativeUsed,
        final: finalVal,
        subtotal,
        costDollar: subtotal,
      });
    }

    for (const srv of services) {
      const subtotal = round2(toNumber(srv.price) * toNumber(srv.usage));
      snapshotData.push({
        wellId,
        category: "Service",
        itemName: srv.serviceName || "",
        code: srv.code || "",
        unit: srv.unit || "",
        price: round2(srv.price),
        cumulativeUsed: round2(srv.usage),
        used: round2(srv.usage),
        final: 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    for (const eng of engineering) {
      const subtotal = round2(toNumber(eng.price) * toNumber(eng.usage));
      snapshotData.push({
        wellId,
        category: "Engineering",
        itemName: eng.engineeringName || "",
        code: eng.code || "",
        unit: eng.unit || "",
        price: round2(eng.price),
        cumulativeUsed: round2(eng.usage),
        used: round2(eng.usage),
        final: 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    const packageKeys = [
      ...new Set([
        ...packageReceives.map((row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-receive:${index}`)
        ),
        ...packages.map((row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-consume:${index}`)
        ),
        ...packageReturns.map((row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-return:${index}`)
        ),
      ]),
    ];

    for (const key of packageKeys) {
      const rec = packageReceives.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-receive:${index}`) ===
          key
      );
      const cons = packages.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-consume:${index}`) ===
          key
      );
      const ret = packageReturns.filter(
        (row, index) =>
          keyFromCodeOrName(row.code, row.packageName, `pkg-return:${index}`) ===
          key
      );

      const cumulativeRec = round2(
        rec.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeUsed = round2(
        cons.reduce((sum, row) => sum + toNumber(row.used), 0)
      );
      const cumulativeRet = round2(
        ret.reduce((sum, row) => sum + toNumber(row.amount), 0)
      );
      const cumulativeAdj = round2(
        cons.reduce((sum, row) => sum + toNumber(row.adjust), 0)
      );

      const initial = round2(cons[0]?.initial);
      const price = round2(cons[0]?.price);
      const subtotal = round2(cumulativeUsed * price);
      const finalVal = round2(
        initial + cumulativeRec - cumulativeRet - cumulativeUsed + cumulativeAdj
      );

      snapshotData.push({
        wellId,
        category: "Package",
        itemName: cons[0]?.packageName || rec[0]?.packageName || "",
        code: cons[0]?.code || rec[0]?.code || ret[0]?.code || "",
        unit: cons[0]?.unit || rec[0]?.unit || ret[0]?.unit || "",
        price,
        cumulativeRec,
        cumulativeUsed,
        cumulativeRet,
        initial,
        rec: cumulativeRec,
        ret: cumulativeRet,
        adj: cumulativeAdj,
        used: cumulativeUsed,
        final: finalVal,
        subtotal,
        costDollar: subtotal,
      });
    }

    const subtotal = round2(
      snapshotData.reduce((sum, item) => sum + toNumber(item.subtotal), 0)
    );
    const taxAmount = round2(subtotal * (taxRate / 100));
    const dailyTotal = round2(subtotal + taxAmount);
    const prevTotal = previousDailyTotal;
    const cumTotal = round2(prevTotal + dailyTotal);
    const intervalTotal = dailyTotal;
    const stockBalance = round2(
      snapshotData.reduce(
        (sum, item) => sum + toNumber(item.final) * toNumber(item.price),
        0
      )
    );

    snapshotData = snapshotData.map((item) => ({
      ...item,
      totalDollar: dailyTotal,
      taxRate,
      taxAmount,
      dailyTotal,
      prevTotal,
      cumTotal,
      intervalTotal,
      stockBalance,
      bulkTankSetupFee,
    }));

    await InventorySnapshot.deleteMany(wellId ? { wellId } : {});
    if (snapshotData.length) {
      await InventorySnapshot.insertMany(snapshotData);
    }

    return res.status(200).json({
      success: true,
      message: "Inventory Snapshot Generated Successfully",
      count: snapshotData.length,
      data: snapshotData,
      summary: {
        subtotal,
        taxRate,
        taxAmount,
        dailyTotal,
        prevTotal,
        cumTotal,
        intervalTotal,
        stockBalance,
        bulkTankSetupFee,
      },
    });
  } catch (error) {
    console.error("generateInventorySnapshot error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getInventorySnapshot = async (req, res) => {
  try {
    const wellId = readWellId(req);
    const data = await InventorySnapshot.find(wellId ? { wellId } : {}).sort({
      category: 1,
      itemName: 1,
    });

    return res.status(200).json({
      success: true,
      count: data.length,
      data,
      summary: summaryFromRows(data),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
