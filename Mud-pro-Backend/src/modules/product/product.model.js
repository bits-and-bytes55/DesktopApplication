import mongoose from "mongoose";

const productSchema = new mongoose.Schema(
  {
    /* =========================
       UI: Product
       Meaning: Company Brand Name
    ========================== */
    Product: {
      type: String,
      required: true,
      trim: true
    },

    /* =========================
       UI: Code
       Mandatory + Unique
    ========================== */
    Code: {
      type: String,
      default: "",
      trim: true
    },

    /* =========================
       UI: SG
       Decimal allowed, mandatory
    ========================== */
    SG: {
      type: String,
      default: ""
    },

    /* =========================
       UI: Unit (Grouped)
       - Num : number (e.g. 54)
       - Class : admin custom value (e.g. KG, Gal, MT, Gel)
    ========================== */
    Unit: {
      Num: {
        type: String,
        default: ""
      },
      Class: {
        type: String,
        default: "",
        trim: true
      }
    },

    /* =========================
       UI: Group
       Category selection
    ========================== */
    Group: {
      type: String,
      default: "",
      trim: true
    },

    /* =========================
       UI: Retail
       Free text BUT value Yes / No
    ========================== */
    Retail: {
      type: String,
      enum: ["", "Yes", "No"],
      default: ""
    },

    /* =========================
       UI: A – F Columns
       Optional, limited input
    ========================== */
    A: { type: String },
    B: { type: String },
    C: { type: String },
    D: { type: String },
    E: { type: String },
    F: { type: String },

    /* =========================
       System
    ========================== */
    isDeleted: {
      type: Boolean,
      default: false
    }
  },
  { timestamps: true }
);

/* =====================================
   DUPLICATE PREVENTION
   - Code must be unique per installation (active records)
===================================== */
productSchema.index(
  { installationId: 1, Code: 1, isDeleted: 1 },
  {
    unique: true,
    partialFilterExpression: {
      Code: { $gt: "" },
      isDeleted: false
    }
  }
);

export default mongoose.model("Product", productSchema);
