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
    const groupedProducts = {};

    for (let receive of receives) {

      if (!groupedProducts[receive.code]) {
        groupedProducts[receive.code] = {
          productName: receive.productName,
          price: receive.price || 0,
          rec: 0
        };
      }

      groupedProducts[receive.code].rec += receive.amount || 0;
    }

    for (let code in groupedProducts) {

      const product = groupedProducts[code];

      const totalUsed = consumes
        .filter(c => c.code === code)
        .reduce((sum, c) => sum + (c.used || 0), 0);

      const totalReturn = returns
        .filter(r => r.code === code)
        .reduce((sum, r) => sum + (r.amount || 0), 0);

      const finalQty = (product.rec || 0) - totalReturn - totalUsed;

      const cost = totalUsed * product.price;

      snapshotData.push({
        category: "Product",
        itemName: product.productName,
        price: product.price,
        used: totalUsed,
        final: finalQty,
        subtotal: cost,
        cost: cost
      });
    }

    // =========================
    // SERVICES
    // =========================
    for (let srv of services) {

      const cost = srv.cost || 0;

      snapshotData.push({
        category: "Service",
        itemName: srv.serviceName,
        price: srv.price || 0,
        used: srv.usage || 0,
        final: 0,
        subtotal: cost,
        cost: cost
      });
    }

    // =========================
    // ENGINEERING
    // =========================
    for (let eng of engineering) {

      const cost = eng.cost || 0;

      snapshotData.push({
        category: "Engineering",
        itemName: eng.engineeringName,
        price: eng.price || 0,
        used: eng.usage || 0,
        final: 0,
        subtotal: cost,
        cost: cost
      });
    }

    // =========================
    // PACKAGE
    // =========================
    for (let pkg of packages) {

      const cost = pkg.cost || 0;

      snapshotData.push({
        category: "Package",
        itemName: pkg.packageName,
        price: pkg.price || 0,
        used: pkg.used || 0,
        final: pkg.final || 0,
        subtotal: cost,
        cost: cost
      });
    }

    // =========================
    // CATEGORY TOTAL CALCULATION
    // =========================
    const categoryTotals = {};

    snapshotData.forEach(item => {
      if (!categoryTotals[item.category]) {
        categoryTotals[item.category] = 0;
      }
      categoryTotals[item.category] += item.cost;
    });

    // =========================
    // ADD TOTAL FIELD
    // =========================
    snapshotData = snapshotData.map(item => ({
      ...item,
      total: categoryTotals[item.category]
    }));

    await InventorySnapshot.deleteMany();
    await InventorySnapshot.insertMany(snapshotData);

    res.status(200).json({
      success: true,
      message: "Inventory Snapshot Generated Successfully",
      categoryTotals,
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

