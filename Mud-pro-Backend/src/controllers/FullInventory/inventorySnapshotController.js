// FIXED: 'final' is JS reserved word — replaced with finalVal everywhere
import InventorySnapshot from "../../modules/FullInventory/InventorySnapshot.js";
import ConsumeProduct from "../../modules/Consumeproduct/ConsumeProduct.js";
import ReceiveProduct from "../../modules/ReceiveProduct/Product/ReceiveProduct.js";
import ReturnProduct from "../../modules/ReturnProduct/Product/ReturnProduct.js";
import Service from "../../modules/ConsumeServices/Services/Service.js";
import Engineering from "../../modules/ConsumeServices/Engineers/Engineering.js";
import Package from "../../modules/ConsumeServices/Package/Package.js";
import ReceivePackage from "../../modules/ReceiveProduct/Package/ReceivePackage.js";
import ReturnPackage from "../../modules/ReturnProduct/Package/ReturnPackage.js";

export const generateInventorySnapshot = async (req, res) => {
  try {

    const consumes        = await ConsumeProduct.find();
    const receives        = await ReceiveProduct.find();
    const returns         = await ReturnProduct.find();
    const services        = await Service.find();
    const engineering     = await Engineering.find();
    const packages        = await Package.find();
    const packageReceives = await ReceivePackage.find();
    const packageReturns  = await ReturnPackage.find();

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
      const productReturns  = returns.filter(r  => r.code === code);

      const cumulativeRec  = productReceives.reduce((s, r) => s + (r.amount || 0), 0);
      const cumulativeUsed = productConsumes.reduce((s, c) => s + (c.used   || 0), 0);
      const cumulativeRet  = productReturns.reduce( (s, r) => s + (r.amount || 0), 0);

      const price   = productConsumes.length > 0 ? (productConsumes[0].price   || 0) : 0;
      const initial = productConsumes.length > 0 ? (productConsumes[0].initial || 0) : 0;

      // ✅ FIX: productName — receive se lo, nahi to consume ka 'product' field use karo
      const itemName =
        productReceives[0]?.productName ||   // ReceiveProduct schema: productName
        productConsumes[0]?.product    ||    // ConsumeProduct schema: product
        productReturns[0]?.productName ||    // ReturnProduct schema: productName
        "";

      // ✅ FIX: unit — receive se lo, nahi to consume se lo
      const unit =
        productReceives[0]?.unit ||
        productConsumes[0]?.unit ||
        productReturns[0]?.unit  ||
        "";

      const finalVal  = initial + cumulativeRec - cumulativeRet - cumulativeUsed;
      const subtotal  = cumulativeUsed * price;

      snapshotData.push({
        category:      "Product",
        itemName,
        code:          code || "",
        unit,
        price,
        cumulativeRec,
        cumulativeRet,
        cumulativeUsed,
        initial,
        rec:           cumulativeRec,
        ret:           cumulativeRet,
        adj:           0,
        used:          cumulativeUsed,
        final:         finalVal,
        subtotal,
        costDollar:    subtotal,
      });
    }

    // =========================
    // SERVICES
    // =========================

    for (let srv of services) {
      const subtotal = (srv.price || 0) * (srv.usage || 0);
      snapshotData.push({
        category:      "Service",
        itemName:      srv.serviceName || "",
        code:          srv.code  || "",
        unit:          srv.unit  || "",
        price:         srv.price || 0,
        cumulativeUsed: srv.usage || 0,
        used:          srv.usage || 0,
        final:         0,
        subtotal,
        costDollar:    subtotal,
      });
    }

    // =========================
    // ENGINEERING
    // =========================

    for (let eng of engineering) {
      const subtotal = (eng.price || 0) * (eng.usage || 0);
      snapshotData.push({
        category:      "Engineering",
        itemName:      eng.engineeringName || "",
        code:          eng.code  || "",
        unit:          eng.unit  || "",
        price:         eng.price || 0,
        cumulativeUsed: eng.usage || 0,
        used:          eng.usage || 0,
        final:         0,
        subtotal,
        costDollar:    subtotal,
      });
    }

   // =========================
// PACKAGE
// =========================

const packageCodes = [
  ...new Set([
    ...packageReceives.map(r => r.code),
    ...packages.map(c => c.code),
    ...packageReturns.map(r => r.code)
  ])
];

for (let code of packageCodes) {

  const rec  = packageReceives.filter(r => r.code === code);
  const cons = packages.filter(c => c.code === code);
  const ret  = packageReturns.filter(r => r.code === code);

  const cumulativeRec  = rec.reduce((s, r) => s + (r.amount || 0), 0);
  const cumulativeUsed = cons.reduce((s, c) => s + (c.used   || 0), 0);
  const cumulativeRet  = ret.reduce((s, r) => s + (r.amount  || 0), 0);

  const initial  = cons.length > 0 ? (cons[0].initial || 0) : 0;  // ✅ FIX
  const price    = cons.length > 0 ? (cons[0].price   || 0) : 0;
  const subtotal = cumulativeUsed * price;

  // ✅ FIX: 'final' reserved word avoid karo + initial formula mein add karo
  const finalVal = initial + cumulativeRec - cumulativeRet - cumulativeUsed;

  snapshotData.push({
    category: "Package",
    itemName: cons[0]?.packageName || rec[0]?.packageName || "",
    code,
    unit: cons[0]?.unit || rec[0]?.unit || "",
    price,
    cumulativeRec,
    cumulativeUsed,
    cumulativeRet,
    initial,           // ✅ initial ab snapshot mein jayega
    rec:  cumulativeRec,
    ret:  cumulativeRet,
    adj:  0,
    used: cumulativeUsed,
    final: finalVal,   // ✅ reserved word crash fix
    subtotal,
    costDollar: subtotal
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
      success:  true,
      message:  "Inventory Snapshot Generated Successfully",
      grandTotal,
      count:    snapshotData.length,
    });

  } catch (error) {
    console.error("generateInventorySnapshot error:", error);
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
      count:   data.length,
      data,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};