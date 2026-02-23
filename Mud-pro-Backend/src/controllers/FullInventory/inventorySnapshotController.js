import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveProduct from "../../modules/ReceiveProduct/Product/ReceiveProduct.js";
import ReturnProduct from "../../modules/ReturnProduct/Product/ReturnProduct.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import Package from "../../modules/ConsumeServices/Package/Package.js";

export const generateInventorySnapshot = async (req, res) => {
  try {

    const consumes = await ConsumeProduct.find();
    const receives = await ReceiveProduct.find();
    const returns  = await ReturnProduct.find();
    const services = await Service.find();
    const engineering = await Engineering.find();
    const packages = await Package.find();

    let snapshotData = [];

    // =========================
    // PRODUCTS
    // =========================

    const productCodes = [
      ...new Set([
        ...receives.map(r => r.code),
        ...consumes.map(c => c.code),
        ...returns.map(r => r.code),
      ])
    ];

    for (let code of productCodes) {

      const productReceives = receives.filter(r => r.code === code);
      const productConsumes = consumes.filter(c => c.code === code);
      const productReturns  = returns.filter(r => r.code === code);

      const cumulativeRec  = productReceives.reduce((s, r) => s + (r.amount  || 0), 0);
      const cumulativeUsed = productConsumes.reduce((s, c) => s + (c.used    || 0), 0);
      const cumulativeRet  = productReturns.reduce( (s, r) => s + (r.amount  || 0), 0);

      const price = productConsumes.length > 0 ? (productConsumes[0].price || 0) : 0;

      // ── Fix: itemName — prefer ReceiveProduct name, fall back to ConsumeProduct name
      const itemName =
        productReceives[0]?.productName ||
        productConsumes[0]?.product     ||
        "";

      // ── Fix: unit — prefer ReceiveProduct unit, fall back to ConsumeProduct unit
      const unit =
        productReceives[0]?.unit ||
        productConsumes[0]?.unit ||
        "";

      const finalQty = cumulativeRec - cumulativeRet - cumulativeUsed;
      const subtotal = cumulativeUsed * price;

      snapshotData.push({
        category: "Product",
        itemName,
        code: code || "",
        unit,
        price,
        cumulativeRec,
        cumulativeRet,
        cumulativeUsed,
        initial: 0,
        rec: cumulativeRec,
        ret: cumulativeRet,
        adj: 0,
        used: cumulativeUsed,
        final: finalQty,
        subtotal,
        costDollar: subtotal,
      });
    }

    // =========================
    // SERVICES
    // =========================

    for (let srv of services) {
      const subtotal = (srv.price || 0) * (srv.usage || 0);

      snapshotData.push({
        category: "Service",
        itemName: srv.serviceName || "",
        code: srv.code || "",
        unit: srv.unit || "",
        price: srv.price || 0,
        cumulativeRec: 0,
        cumulativeRet: 0,
        cumulativeUsed: srv.usage || 0,
        initial: 0,
        rec: 0,
        ret: 0,
        adj: 0,
        used: srv.usage || 0,
        final: 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    // =========================
    // ENGINEERING
    // =========================

    for (let eng of engineering) {
      const subtotal = (eng.price || 0) * (eng.usage || 0);

      snapshotData.push({
        category: "Engineering",
        itemName: eng.engineeringName || "",
        code: eng.code || "",
        unit: eng.unit || "",
        price: eng.price || 0,
        cumulativeRec: 0,
        cumulativeRet: 0,
        cumulativeUsed: eng.usage || 0,
        initial: 0,
        rec: 0,
        ret: 0,
        adj: 0,
        used: eng.usage || 0,
        final: 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    // =========================
    // PACKAGE
    // =========================

    for (let pkg of packages) {
      const subtotal = (pkg.price || 0) * (pkg.used || 0);

      snapshotData.push({
        category: "Package",
        itemName: pkg.packageName || "",
        code: pkg.code || "",
        unit: pkg.unit || "",
        price: pkg.price || 0,
        cumulativeRec: 0,
        cumulativeRet: 0,
        cumulativeUsed: pkg.used || 0,
        initial: 0,
        rec: 0,
        ret: 0,
        adj: 0,
        used: pkg.used || 0,
        final: pkg.final || 0,
        subtotal,
        costDollar: subtotal,
      });
    }

    // =========================
    // GRAND TOTAL
    // =========================

    const grandTotal = snapshotData.reduce(
      (sum, item) => sum + (item.subtotal || 0),
      0
    );

    snapshotData = snapshotData.map(item => ({
      ...item,
      totalDollar: grandTotal,
    }));

    await InventorySnapshot.deleteMany();
    await InventorySnapshot.insertMany(snapshotData);

    res.status(200).json({
      success: true,
      message: "Inventory Snapshot Generated Successfully",
      grandTotal,
      count: snapshotData.length,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getInventorySnapshot = async (req, res) => {
  try {
    const data = await InventorySnapshot.find();

    res.status(200).json({
      success: true,
      count: data.length,
      data: data,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};