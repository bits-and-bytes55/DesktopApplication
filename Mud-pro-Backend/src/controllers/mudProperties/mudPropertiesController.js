import SelectedMudProperties from '../../modules/mudProperties/mudPropertiesModel.js';

// GET saved/selected mud properties from DB
export const getSelectedMudProperties = async (req, res) => {
  try {
    const userId = req.query.userId || 'default';
    let record = await SelectedMudProperties.findOne({ userId });

    if (!record) {
      return res.status(200).json({
        success: true,
        data: { waterBased: [], oilBased: [], synthetic: [] },
      });
    }

    res.status(200).json({
      success: true,
      data: {
        waterBased: record.waterBased,
        oilBased: record.oilBased,
        synthetic: record.synthetic,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// POST save selected mud properties
export const saveSelectedMudProperties = async (req, res) => {
  try {
    const { waterBased = [], oilBased = [], synthetic = [], userId = 'default' } = req.body;

    const record = await SelectedMudProperties.findOneAndUpdate(
      { userId },
      { waterBased, oilBased, synthetic },
      { upsert: true, new: true }
    );

    res.status(200).json({
      success: true,
      message: 'Mud properties saved successfully',
      data: {
        waterBased: record.waterBased,
        oilBased: record.oilBased,
        synthetic: record.synthetic,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
