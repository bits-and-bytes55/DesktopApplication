import mongoose from 'mongoose';

const selectedMudPropertiesSchema = new mongoose.Schema(
  {
    waterBased: {
      type: [String],
      default: [],
    },
    oilBased: {
      type: [String],
      default: [],
    },
    synthetic: {
      type: [String],
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