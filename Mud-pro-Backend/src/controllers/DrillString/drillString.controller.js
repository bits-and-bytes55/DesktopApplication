import DrillString from "../../modules/DrillString/DrillString.js";

/**
 * @desc Create Drill String Entry
 */
export const createDrillString = async (req, res) => {
  try {

    const { description, od, weightPpf, id, grade, length } = req.body;

    const drill = await DrillString.create({
      description,
      od: Number(od || 0),
      weightPpf: Number(weightPpf || 0),
      id: Number(id || 0),
      grade,
      length: Number(length || 0)
    });

    res.status(201).json({
      success: true,
      message: "Drill String Added Successfully",
      data: drill
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


/**
 * @desc Get All Drill Strings + Total Length Calculation
 */
export const getDrillStrings = async (req, res) => {
  try {

    const data = await DrillString.find();

    const totalLength = data.reduce(
      (sum, item) => sum + Number(item.length || 0),
      0
    );

    res.status(200).json({
      success: true,
      count: data.length,
      totalLength,
      data
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


/**
 * @desc Delete Drill String
 */
export const deleteDrillString = async (req, res) => {
  try {

    await DrillString.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: "Deleted Successfully"
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};