import Nozzle from "../../modules/nozzle/nozzle.model.js";

const calculateNozzleArea = (size32) => {
  const diameter = size32 / 32;
  const area = (Math.PI * Math.pow(diameter, 2)) / 4;
  return {
    diameter: +diameter.toFixed(4),
    area: +area.toFixed(4),
  };
};

const processNozzles = (inputNozzles) => {
  let processedNozzles = [];
  let totalTFA = 0;

  inputNozzles.forEach((nz) => {
    const { diameter, area } = calculateNozzleArea(nz.size32);
    const totalArea = area * nz.count;
    totalTFA += totalArea;
    processedNozzles.push({
      count: nz.count,
      size32: nz.size32,
      diameterInch: diameter,
      area: area,
    });
  });

  return { processedNozzles, totalTFA: +totalTFA.toFixed(4) };
};

// ─── CREATE ────────────────────────────────────────────────────────
export const createNozzle = async (req, res) => {
  try {
    const inputNozzles = req.body.nozzles;
    const { processedNozzles, totalTFA } = processNozzles(inputNozzles);

    const nozzle = await Nozzle.create({
      nozzles: processedNozzles,
      tfa: totalTFA,
    });

    res.status(201).json({ success: true, data: nozzle });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─── GET ALL ───────────────────────────────────────────────────────
export const getNozzles = async (req, res) => {
  try {
    const nozzles = await Nozzle.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: nozzles });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─── UPDATE ────────────────────────────────────────────────────────
export const updateNozzle = async (req, res) => {
  try {
    const { id } = req.params;
    const inputNozzles = req.body.nozzles;
    const { processedNozzles, totalTFA } = processNozzles(inputNozzles);

    const updated = await Nozzle.findByIdAndUpdate(
      id,
      { nozzles: processedNozzles, tfa: totalTFA },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ success: false, message: "Nozzle not found" });
    }

    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};