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
      required: true,
      trim: true
    },

    /* =========================
       UI: SG
       Decimal allowed, mandatory
    ========================== */
    SG: {
      type: String,
      required: true
    },

    /* =========================
       UI: Unit (Grouped)
       - Num : number (e.g. 54)
       - Class : admin custom value (e.g. KG, Gal, MT, Gel)
    ========================== */
    Unit: {
      Num: {
        type: String,
        required: true
      },
      Class: {
        type: String,
        required: true,
        trim: true
      }
    },

    /* =========================
       UI: Group
       Category selection
    ========================== */
    Group: {
      type: String,
      required: true,
      trim: true
    },

    /* =========================
       UI: Retail
       Free text BUT value Yes / No
    ========================== */
    Retail: {
      type: String,
      enum: ["Yes", "No"],
      default: "No"
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
   DUPLICATE PREVENTION (KEEPED AS ASKED)
   - Code must be unique (active records)
===================================== */
productSchema.index(
  { Code: 1, isDeleted: 1 },
  { unique: true }
);

export default mongoose.model("Product", productSchema);
