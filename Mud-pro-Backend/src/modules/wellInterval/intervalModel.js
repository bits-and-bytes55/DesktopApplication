import mongoose from "mongoose";

// ── Individual interval inside a well ─────────────────────────────
const intervalSchema = new mongoose.Schema(
  {
    // Which well / UG-ST this interval belongs to
    wellId: {
      type: String,
      required: true,
      index: true,
    },

    // Display name (editable by user)
    name: {
      type: String,
      default: "New Interval",
    },

    // Sort order in the list
    order: {
      type: Number,
      default: 0,
    },

    // If this interval belongs to a group, store group id
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "IntervalGroup",
      default: null,
    },

    // ── General tab – table fields ─────────────────────────────────
    formation: { type: String, default: "" },
    bitSize:   { type: String, default: "" },
    casing:    { type: String, default: "" },
    intervalFIT: { type: String, default: "" },
    mudDescription: { type: String, default: "" },
    mudType:   { type: String, default: "" },

    // ── General tab – text-area fields ────────────────────────────
    intervalSummary: { type: String, default: "" },
    solidControl:    { type: String, default: "" },
    intervalConclusion: { type: String, default: "" },
    sweeps:          { type: String, default: "" },
    labTesting:      { type: String, default: "" },

    // End-of-interval bottom text-area
    endOfIntervalConclusion: { type: String, default: "" },
  },
  { timestamps: true }
);

// ── Group model (contains a list of interval ids) ─────────────────
const intervalGroupSchema = new mongoose.Schema(
  {
    wellId: {
      type: String,
      required: true,
      index: true,
    },

    name: {
      type: String,
      default: "Group",
    },

    // ordered list of interval _ids that belong to this group
    intervalIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Interval",
      },
    ],

    // order in the overall list (same sequence space as intervals)
    order: {
      type: Number,
      default: 0,
    },

    // collapsed / expanded state (stored server-side for persistence)
    collapsed: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

export const Interval      = mongoose.model("Interval",      intervalSchema);
export const IntervalGroup = mongoose.model("IntervalGroup", intervalGroupSchema);