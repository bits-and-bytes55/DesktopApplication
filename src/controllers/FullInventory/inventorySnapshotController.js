import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveProduct from "../../modules/ReceiveProduct/Product/ReceiveProduct.js";
import ReturnProduct from "../../modules/ReturnProduct/Product/ReturnProduct.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import Package from "../../modules/ConsumeServices/Package/Package.js";

export const generateInventorySnapshot = async (req, res) => {
  try {

    // 🔹 Fetch All Transaction Data
    const consumes = await ConsumeProduct.find();
    const receives = await ReceiveProduct.find();
    const returns = await ReturnProduct.find();
    const services = await Service.find();
    const engineering = await Engineering.find();
    const packages = await Package.find();

    let snapshotData = [];

    // 🔹 Handle Products
    for (let receive of receives) {

      const totalUsed = consumes
        .filter(c => c.code === receive.code)
        .reduce((sum, c) => sum + c.used, 0);

      const totalReturn = returns
        .filter(r => r.code === receive.code)
        .reduce((sum, r) => sum + r.amount, 0);

      const initial = 0; // first version
      const rec = receive.amount;
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
      });
    }

    // 🔹 Handle Services
    for (let srv of services) {
      snapshotData.push({
        category: "Service",
        itemName: srv.serviceName,
        price: srv.price,
        used: srv.usage,
        subtotal: srv.cost,
      });
    }

    // 🔹 Handle Engineering
    for (let eng of engineering) {
      snapshotData.push({
        category: "Engineering",
        itemName: eng.engineeringName,
        price: eng.price,
        used: eng.usage,
        subtotal: eng.cost,
      });
    }

    // 🔹 Handle Packages
    for (let pkg of packages) {
      snapshotData.push({
        category: "Package",
        itemName: pkg.packageName,
        price: pkg.price,
        initial: pkg.initial,
        used: pkg.used,
        final: pkg.final,
        subtotal: pkg.cost,
      });
    }

    // 🔹 Clear old snapshot
    await InventorySnapshot.deleteMany();

    // 🔹 Insert fresh snapshot
    await InventorySnapshot.insertMany(snapshotData);

    res.status(200).json({
      success: true,
      message: "Inventory Snapshot Generated Successfully",
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

