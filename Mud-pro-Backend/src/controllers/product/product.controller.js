import fs from "fs";
import Product from "../../modules/product/product.model.js";
import ActivityLog from "../../modules/product/activityLog.model.js";
import { parseProductExcel } from "../../utils/excelParser.js";

/* ======================================================
   1️⃣ ADD SINGLE PRODUCT (UI GRID – ONE ROW)
   ====================================================== */
export const addProduct = async (req, res) => {
  try {
    const {
      Product: productName,
      Code,
      SG,
      Unit,
      Group,
      Retail,
      A, B, C, D, E, F
    } = req.body;

    // ✅ Basic validation (only required fields)
    if (
      !productName ||
      !Code ||
      SG === undefined ||
      !Unit?.Num ||
      !Unit?.Class ||
      !Group
    ) {
      return res.status(400).json({
        success: false,
        message: "Required fields are missing"
      });
    }

    const product = await Product.create({
      Product: productName,
      Code,
      SG,
      Unit,
      Group,
      Retail,
      A, B, C, D, E, F
    });

    await ActivityLog.create({
      action: "CREATE",
      referenceId: product._id,
      description: `Product ${Code} added`
    });

    res.status(201).json({
      success: true,
      data: product
    });
  } catch (e) {
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};

/* ======================================================
   2️⃣ BULK ADD PRODUCTS (SAVE BUTTON / GRID SAVE)
   ====================================================== */
export const bulkAddProducts = async (req, res) => {
  try {
    if (!Array.isArray(req.body)) {
      return res.status(400).json({
        success: false,
        message: "Payload must be an array"
      });
    }

    // ✅ Sirf filled rows hi uthao
    const validRows = req.body.filter(row =>
      row.Product &&
      row.Code &&
      row.SG !== undefined &&
      row.Unit?.Num &&
      row.Unit?.Class &&
      row.Group
    );

    if (!validRows.length) {
      return res.status(400).json({
        success: false,
        message: "No valid rows found to save"
      });
    }

    const inserted = await Product.insertMany(validRows, {
      ordered: false
    });

    await ActivityLog.create({
      action: "BULK_CREATE",
      description: `Bulk added ${inserted.length} products`
    });

    res.status(201).json({
      success: true,
      saved: inserted.length
    });
  } catch (e) {
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};

/* ======================================================
   3️⃣ EXCEL UPLOAD (IMPORT)
   ====================================================== */
export const uploadProductExcel = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Excel file not received"
      });
    }

    const result = parseProductExcel(req.file.path);

    // Header error (UI friendly)
    if (result.success === false) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json(result);
    }

    const { valid, errors } = result;

    let inserted = [];
    if (valid.length) {
      inserted = await Product.insertMany(valid, { ordered: false });
    }

    await ActivityLog.create({
      action: "UPLOAD",
      description: `Uploaded ${inserted.length} products from Excel`
    });

    fs.unlinkSync(req.file.path);

    res.json({
      success: true,
      inserted: inserted.length,
      errors
    });
  } catch (e) {
    if (req.file?.path) fs.unlinkSync(req.file.path);
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};

/* ======================================================
   4️⃣ SOFT DELETE
   ====================================================== */
export const deleteProduct = async (req, res) => {
  await Product.findByIdAndUpdate(req.params.id, { isDeleted: true });

  await ActivityLog.create({
    action: "DELETE",
    referenceId: req.params.id,
    description: "Product soft deleted"
  });

  res.json({ success: true });
};

/* ======================================================
   5️⃣ RESTORE
   ====================================================== */
export const restoreProduct = async (req, res) => {
  await Product.findByIdAndUpdate(req.params.id, { isDeleted: false });

  await ActivityLog.create({
    action: "RESTORE",
    referenceId: req.params.id,
    description: "Product restored"
  });

  res.json({ success: true });
};

/* ======================================================
   6️⃣ GET PRODUCTS (PAGINATION + SEARCH – UI GRID)
   ====================================================== */
export const getProducts = async (req, res) => {
  const {
    page = 1,
    limit = 20,
    search,
    Group
  } = req.query;

  const filter = { isDeleted: false };

  if (Group) filter.Group = Group;

  if (search) {
    filter.$or = [
      { Product: { $regex: search, $options: "i" } },
      { Code: { $regex: search, $options: "i" } }
    ];
  }

  const data = await Product.find(filter)
    .skip((page - 1) * limit)
    .limit(Number(limit))
    .sort({ createdAt: -1 });

  const total = await Product.countDocuments(filter);

  res.json({
    success: true,
    page: Number(page),
    total,
    data
  });
};
