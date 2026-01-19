import mongoose from "mongoose";

const productSchema = new mongoose.Schema(
  {
    companyBrandName: { type: String, required: true, trim: true },
    productCategory: { type: String, required: true },

    sizeValue: { type: Number, required: true },
    sizeUnit: { type: String, required: true },
    packagingType: { type: String, required: true },

    unitDisplay: String,
    densitySG: { type: Number, required: true },

    isDeleted: { type: Boolean, default: false }
  },
  { timestamps: true }
);

/**
 * DUPLICATE PREVENTION (DB LEVEL)
 * Same product + size + unit + packaging cannot repeat
 */
productSchema.index(
  {
    companyBrandName: 1,
    sizeValue: 1,
    sizeUnit: 1,
    packagingType: 1,
    isDeleted: 1
  },
  { unique: true }
);

productSchema.pre("save", function (next) {
  this.unitDisplay = `${this.sizeValue} ${this.sizeUnit}`;
  next();
});

export default mongoose.model("Product", productSchema);
