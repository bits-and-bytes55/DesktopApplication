// controllers/others/activity.controller.js
import { Activity , Addition, Loss, WaterBased, OilBased, Synthetic} from "../../modules/others/others.model.js";



export const createActivity = async (req, res) => {
  try {
    const data = await Activity.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createBulkActivities = async (req, res) => {
  try {
    const activities = req.body;
    if (!Array.isArray(activities) || activities.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of activities" 
      });
    }
    const data = await Activity.insertMany(activities);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} activities added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getActivities = async (req, res) => {
  try {
    const data = await Activity.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const updateActivity = async (req, res) => {
  try {
    const data = await Activity.findByIdAndUpdate(req.params.id, req.body, { returnDocument: "after" });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const deleteActivity = async (req, res) => {
  try {
    await Activity.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Activity deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// controllers/others/addition.controller.js

export const createAddition = async (req, res) => {
  try {
    const data = await Addition.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createBulkAdditions = async (req, res) => {
  try {
    const additions = req.body;
    if (!Array.isArray(additions) || additions.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of additions" 
      });
    }
    const data = await Addition.insertMany(additions);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} additions added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getAdditions = async (req, res) => {
  try {
    const data = await Addition.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const updateAddition = async (req, res) => {
  try {
    const data = await Addition.findByIdAndUpdate(req.params.id, req.body, { returnDocument: "after" });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const deleteAddition = async (req, res) => {
  try {
    await Addition.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Addition deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// controllers/others/loss.controller.js

export const createLoss = async (req, res) => {
  try {
    const data = await Loss.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createBulkLosses = async (req, res) => {
  try {
    const losses = req.body;
    if (!Array.isArray(losses) || losses.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of losses" 
      });
    }
    const data = await Loss.insertMany(losses);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} losses added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getLosses = async (req, res) => {
  try {
    const data = await Loss.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const updateLoss = async (req, res) => {
  try {
    const data = await Loss.findByIdAndUpdate(req.params.id, req.body, { returnDocument: "after" });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const deleteLoss = async (req, res) => {
  try {
    await Loss.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Loss deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// controllers/others/waterbased.controller.js

export const createWaterBased = async (req, res) => {
  try {
    const data = await WaterBased.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createBulkWaterBased = async (req, res) => {
  try {
    const waterBased = req.body;
    if (!Array.isArray(waterBased) || waterBased.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of water-based items" 
      });
    }
    const data = await WaterBased.insertMany(waterBased);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} water-based items added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getWaterBased = async (req, res) => {
  try {
    const data = await WaterBased.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const updateWaterBased = async (req, res) => {
  try {
    const data = await WaterBased.findByIdAndUpdate(req.params.id, req.body, { returnDocument: "after" });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const deleteWaterBased = async (req, res) => {
  try {
    await WaterBased.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Water-based deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// controllers/others/oilbased.controller.js

export const createOilBased = async (req, res) => {
  try {
    const data = await OilBased.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createBulkOilBased = async (req, res) => {
  try {
    const oilBased = req.body;
    if (!Array.isArray(oilBased) || oilBased.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of oil-based items" 
      });
    }
    const data = await OilBased.insertMany(oilBased);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} oil-based items added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getOilBased = async (req, res) => {
  try {
    const data = await OilBased.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const updateOilBased = async (req, res) => {
  try {
    const data = await OilBased.findByIdAndUpdate(req.params.id, req.body, { returnDocument: "after" });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const deleteOilBased = async (req, res) => {
  try {
    await OilBased.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Oil-based deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// controllers/others/synthetic.controller.js

export const createSynthetic = async (req, res) => {
  try {
    const data = await Synthetic.create(req.body);
    res.status(201).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const createBulkSynthetic = async (req, res) => {
  try {
    const synthetic = req.body;
    if (!Array.isArray(synthetic) || synthetic.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: "Please provide an array of synthetic items" 
      });
    }
    const data = await Synthetic.insertMany(synthetic);
    res.status(201).json({ 
      success: true, 
      data, 
      saved: data.length,
      message: `${data.length} synthetic items added successfully`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const getSynthetic = async (req, res) => {
  try {
    const data = await Synthetic.find().sort({ createdAt: -1 });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const updateSynthetic = async (req, res) => {
  try {
    const data = await Synthetic.findByIdAndUpdate(req.params.id, req.body, { returnDocument: "after" });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

export const deleteSynthetic = async (req, res) => {
  try {
    await Synthetic.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: "Synthetic deleted" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};