import fs from "fs";
import Product from "../../modules/product/product.model.js";
import ActivityLog from "../../modules/product/activityLog.model.js";
import { parseProductExcel } from "../../utils/excelParser.js";

let productIndexReady;
const ensureProductCodeIndex = async () => {
  if (!productIndexReady) {
    productIndexReady = (async () => {
      try {
        await Product.collection.dropIndex("Code_1_isDeleted_1");
      } catch (error) {
        if (error?.codeName !== "IndexNotFound" && error?.code !== 27) {
          throw error;
        }
      }

      await Product.collection.createIndex(
        { Code: 1, isDeleted: 1 },
        {
          unique: true,
          partialFilterExpression: {
            Code: { $type: "string", $ne: "" },
            isDeleted: false
          }
        }
      );
    })();
  }

  return productIndexReady;
};

const productPayload = (body) => ({
  Product: body.Product,
  Code: body.Code ?? "",
  SG: body.SG ?? "",
  Unit: {
    Num: body.Unit?.Num ?? "",
    Class: body.Unit?.Class ?? ""
  },
  Group: body.Group ?? "",
  Retail: body.Retail ?? "",
  A: body.A,
  B: body.B,
  C: body.C,
  D: body.D,
  E: body.E,
  F: body.F
});

/* ======================================================
   1️⃣ ADD SINGLE PRODUCT (UI GRID – ONE ROW)
   ====================================================== */
export const addProduct = async (req, res) => {
  try {
    await ensureProductCodeIndex();

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
      !productName
    ) {
      return res.status(400).json({
        success: false,
        message: "Product is required"
      });
    }

    const product = await Product.create(productPayload(req.body));

    await ActivityLog.create({
      action: "CREATE",
      referenceId: product._id,
      description: `Product ${Code} added`
    });

    res.status(201).json({
      success: true,
      data: product,
      message: "Product added successfully"
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
    await ensureProductCodeIndex();

    if (!Array.isArray(req.body)) {
      return res.status(400).json({
        success: false,
        message: "Payload must be an array"
      });
    }

    // ✅ Sirf filled rows hi uthao
    const validRows = req.body
      .filter(row => row.Product)
      .map(productPayload);

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
      saved: inserted.length,
      message: `${inserted.length} product(s) saved successfully`
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
    await ensureProductCodeIndex();

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
      errors,
      message: `Excel imported successfully. ${inserted.length} product(s) added`
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
   4️⃣ UPDATE PRODUCT
   ====================================================== */
export const updateProduct = async (req, res) => {
  try {
    await ensureProductCodeIndex();

    const { id } = req.params;
    const {
      Product: productName,
      Code,
      SG,
      Unit,
      Group,
      Retail,
      A, B, C, D, E, F
    } = req.body;

    // ✅ Basic validation
    if (
      !productName
    ) {
      return res.status(400).json({
        success: false,
        message: "Product is required"
      });
    }

    const cleanCode = Code?.trim() ?? "";
    const existing = cleanCode
      ? await Product.findOne({
          Code: cleanCode,
          isDeleted: false,
          _id: { $ne: id }
        })
      : null;

    if (existing) {
      return res.status(400).json({
        success: false,
        message: "Product code already exists"
      });
    }


    const product = await Product.findByIdAndUpdate(
      id,
      productPayload(req.body),
      { new: true, runValidators: true }
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found"
      });
    }

    await ActivityLog.create({
      action: "UPDATE",
      referenceId: product._id,
      description: `Product ${Code} updated`
    });

    res.json({
      success: true,
      data: product,
      message: "Product updated successfully"
    });
  } catch (e) {
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};

/* ======================================================
   5️⃣ SOFT DELETE
   ====================================================== */
export const deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;

    const product = await Product.findByIdAndUpdate(
      id,
      { isDeleted: true },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found"
      });
    }

    await ActivityLog.create({
      action: "DELETE",
      referenceId: product._id,
      description: `Product ${product.Code} soft deleted`
    });

    res.json({
      success: true,
      message: "Product deleted successfully"
    });
  } catch (e) {
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};

/* ======================================================
   6️⃣ RESTORE
   ====================================================== */
export const restoreProduct = async (req, res) => {
  try {
    const { id } = req.params;

    const product = await Product.findByIdAndUpdate(
      id,
      { isDeleted: false },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found"
      });
    }

    await ActivityLog.create({
      action: "RESTORE",
      referenceId: product._id,
      description: `Product ${product.Code} restored`
    });

    res.json({
      success: true,
      message: "Product restored successfully"
    });
  } catch (e) {
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};

/* ======================================================
   7️⃣ GET PRODUCTS (PAGINATION + SEARCH – UI GRID)
   ====================================================== */
export const getProducts = async (req, res) => {
  try {
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
  } catch (e) {
    res.status(400).json({
      success: false,
      message: e.message
    });
  }
};
