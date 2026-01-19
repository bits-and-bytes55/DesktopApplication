import fs from "fs";
import Product from "../../modules/product/product.model.js";
import ActivityLog from "../../modules/product/activityLog.model.js";
import { parseProductExcel } from "../../utils/excelParser.js";

/**
 * EXCEL UPLOAD
 */
export const uploadProductExcel = async (req, res, next) => {
  console.log("📌 Hit Uploaded file info:", req.file);
  try {
    const { valid, errors } = parseProductExcel(req.file.path);

    let inserted = [];
    if (valid.length) {
      inserted = await Product.insertMany(valid, { ordered: false });
    }

    await ActivityLog.create({
      action: "UPLOAD",
      description: `Uploaded ${inserted.length} products`
    });

    fs.unlinkSync(req.file.path);

    res.json({
      success: true,
      inserted: inserted.length,
      validationErrors: errors
    });
  } catch (e) {
    if (req.file?.path) fs.unlinkSync(req.file.path);
    res.status(400).json(e);
  }
};

/**
 * SOFT DELETE
 */
export const deleteProduct = async (req, res, next) => {
  await Product.findByIdAndUpdate(req.params.id, { isDeleted: true });

  await ActivityLog.create({
    action: "DELETE",
    referenceId: req.params.id,
    description: "Product soft deleted"
  });

  res.json({ success: true });
};

/**
 * RESTORE
 */
export const restoreProduct = async (req, res) => {
  await Product.findByIdAndUpdate(req.params.id, { isDeleted: false });

  await ActivityLog.create({
    action: "RESTORE",
    referenceId: req.params.id,
    description: "Product restored"
  });

  res.json({ success: true });
};

/**
 * PAGINATION + SEARCH
 */
export const getProducts = async (req, res) => {
  const {
    page = 1,
    limit = 20,
    search,
    category,
    packaging
  } = req.query;

  const filter = { isDeleted: false };

  if (category) filter.productCategory = category;
  if (packaging) filter.packagingType = packaging;
  if (search) {
    filter.companyBrandName = { $regex: search, $options: "i" };
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
