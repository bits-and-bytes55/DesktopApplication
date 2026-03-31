import mongoose from 'mongoose';

const selectedMudPropertiesSchema = new mongoose.Schema(
  {
    waterBased: {
      type: [{ name: String, unit: String }],
      default: [],
    },
    oilBased: {
      type: [{ name: String, unit: String }],
      default: [],
    },
    synthetic: {
      type: [{ name: String, unit: String }],
      default: [],
    },
    userId: {
      type: String,
      default: 'default',
    },
  },
  { timestamps: true }
);

const SelectedMudProperties = mongoose.model(
  'SelectedMudProperties',
  selectedMudPropertiesSchema
);

export default SelectedMudProperties;