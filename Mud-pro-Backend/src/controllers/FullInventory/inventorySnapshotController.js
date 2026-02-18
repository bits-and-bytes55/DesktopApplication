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
    const returns = await ReturnProduct.find();
    const services = await Service.find();
    const engineering = await Engineering.find();
    const packages = await Package.find();

    let snapshotData = [];

    // =========================
    // PRODUCTS
    // =========================
    for (let receive of receives) {

      const totalUsed = consumes
        .filter(c => c.code === receive.code)
        .reduce((sum, c) => sum + (c.used || 0), 0);

      const totalReturn = returns
        .filter(r => r.code === receive.code)
        .reduce((sum, r) => sum + (r.amount || 0), 0);

      const initial = 0;
      const rec = receive.amount || 0;
      const ret = totalReturn;
      const used = totalUsed;
      const adj = 0;

      const final = initial + rec - ret - used + adj;
      const subtotal = final * (receive.price || 0);

      snapshotData.push({
        category: "Product",
        itemName: receive.productName,
        price: receive.price || 0,
        initial,
        rec,
        ret,
        adj,
        used,
        final,
        subtotal,
        costDollar: subtotal
      });
    }

    // =========================
    // SERVICES
    // =========================
    for (let srv of services) {
      snapshotData.push({
        category: "Service",
        itemName: srv.serviceName,
        price: srv.price || 0,
        used: srv.usage || 0,
        subtotal: srv.cost || 0,
        costDollar: srv.cost || 0
      });
    }

    // =========================
    // ENGINEERING
    // =========================
    for (let eng of engineering) {
      snapshotData.push({
        category: "Engineering",
        itemName: eng.engineeringName,
        price: eng.price || 0,
        used: eng.usage || 0,
        subtotal: eng.cost || 0,
        costDollar: eng.cost || 0
      });
    }

    // =========================
    // PACKAGE
    // =========================
    for (let pkg of packages) {
      snapshotData.push({
        category: "Package",
        itemName: pkg.packageName,
        price: pkg.price || 0,
        initial: pkg.initial || 0,
        used: pkg.used || 0,
        final: pkg.final || 0,
        subtotal: pkg.cost || 0,
        costDollar: pkg.cost || 0
      });
    }

    // =========================
    // GRAND TOTAL CALCULATION
    // =========================

    const grandTotal = snapshotData.reduce(
      (sum, item) => sum + (item.subtotal || 0),
      0
    );

    snapshotData = snapshotData.map(item => {
      const costPercent = grandTotal > 0
        ? ((item.subtotal / grandTotal) * 100).toFixed(2)
        : 0;

      return {
        ...item,
        costPercent: Number(costPercent),
        totalDollar: grandTotal,
        totalPercent: 100
      };
    });

    await InventorySnapshot.deleteMany();
    await InventorySnapshot.insertMany(snapshotData);

    res.status(200).json({
      success: true,
      message: "Inventory Snapshot Generated Successfully",
      grandTotal,
      count: snapshotData.length
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getInventorySnapshot = async (req, res) => {
  try {
    const data = await InventorySnapshot.find();

    res.status(200).json({
      success: true,
      count: data.length,
      data: data
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

