import TubularDatabase from "../../modules/tubularDatabase/tubularDatabase.model.js";

const DEFAULT_TYPES = [
  "CWS",
  "CWS w/ FICD",
  "ECL",
  "Drill Pipe Premium",
  "Heavy Weight DP",
  "Drill Collar",
  "Tubing",
  "Casing",
  "Coiled Tubing",
  "Drill Pipe Class 2",
  "Drill Pipe New",
  "Line Pipe",
  "Aluminum DP",
  "Mud Motor",
  "Drilling Reamer",
  "Rotary Steerable",
  "MWD",
  "LWD",
  "Hydraulic Jar",
  "Jar Slinger",
  "ESS",
  "EXR",
  "EXT",
  "SP",
  "EZI",
];

const DEFAULT_CATALOGS = ["Weatherford"];
const DEFAULT_MATERIALS = ["Steel", "Aluminium"];

const DEFAULT_ROWS = [
  { od: "2.720", id: "1.995", grade: "Super weld", yieldPsi: "33034", tensileStr: "88690", connectionOd: "2.820" },
  { od: "2.730", id: "1.995", grade: "Dura Grip", yieldPsi: "32516", tensileStr: "88690", connectionOd: "2.820" },
  { od: "3.080", id: "1.995", grade: "Excelflo", yieldPsi: "20508", tensileStr: "88690", connectionOd: "2.820" },
  { od: "3.080", id: "1.995", grade: "Micro Pac", yieldPsi: "20508", tensileStr: "88690", connectionOd: "2.820" },
  { od: "3.220", id: "2.441", grade: "Super Weld", yieldPsi: "35576", tensileStr: "123220", connectionOd: "3.320" },
  { od: "3.230", id: "2.441", grade: "Dura Grip", yieldPsi: "35063", tensileStr: "123220", connectionOd: "3.330" },
  { od: "3.270", id: "1.995", grade: "Maxflow", yieldPsi: "16822", tensileStr: "88690", connectionOd: "3.370" },
  { od: "3.570", id: "2.441", grade: "Excelflo", yieldPsi: "23118", tensileStr: "123220", connectionOd: "3.670" },
  { od: "3.580", id: "2.441", grade: "Micro Pac", yieldPsi: "22877", tensileStr: "123220", connectionOd: "3.680" },
  { od: "3.770", id: "2.441", grade: "Maxflow", yieldPsi: "19007", tensileStr: "123220", connectionOd: "3.870" },
  { od: "3.850", id: "2.992", grade: "Dura Grip", yieldPsi: "38201", tensileStr: "176130", connectionOd: "3.950" },
  { od: "3.850", id: "2.992", grade: "Super Weld", yieldPsi: "38201", tensileStr: "176130", connectionOd: "3.950" },
  { od: "3.970", id: "2.992", grade: "Ultra Grip", yieldPsi: "16585", tensileStr: "88690", connectionOd: "4.070" },
  { od: "4.000", id: "2.992", grade: "Ultra Grip", yieldPsi: "31819", tensileStr: "176130", connectionOd: "4.100" },
  { od: "4.070", id: "2.992", grade: "Dura Grip", yieldPsi: "14833", tensileStr: "88690", connectionOd: "4.170" },
  { od: "4.110", id: "2.992", grade: "Excelflo", yieldPsi: "28244", tensileStr: "176130", connectionOd: "4.210" },
  { od: "4.200", id: "2.992", grade: "Micro Pac", yieldPsi: "25812", tensileStr: "176130", connectionOd: "4.300" },
  { od: "4.220", id: "2.992", grade: "Maxflow", yieldPsi: "25321", tensileStr: "176130", connectionOd: "4.320" },
  { od: "4.350", id: "3.548", grade: "Dura Grip", yieldPsi: "36626", tensileStr: "182210", connectionOd: "4.450" },
  { od: "4.350", id: "3.548", grade: "Super Weld", yieldPsi: "36626", tensileStr: "182210", connectionOd: "4.450" },
  { od: "4.470", id: "3.548", grade: "Ultra Grip", yieldPsi: "31382", tensileStr: "182210", connectionOd: "4.570" },
  { od: "4.500", id: "3.548", grade: "Ultra Grip", yieldPsi: "30280", tensileStr: "182210", connectionOd: "4.600" },
  { od: "4.570", id: "3.548", grade: "Dura Grip", yieldPsi: "27963", tensileStr: "182210", connectionOd: "4.670" },
  { od: "4.610", id: "3.548", grade: "Excelflo", yieldPsi: "26778", tensileStr: "182210", connectionOd: "4.710" },
  { od: "4.700", id: "3.548", grade: "Micro Pac", yieldPsi: "24416", tensileStr: "182210", connectionOd: "4.800" },
  { od: "4.720", id: "3.548", grade: "Maxflow", yieldPsi: "23942", tensileStr: "182210", connectionOd: "4.820" },
];

const text = (value) => String(value ?? "").trim();

const rowPayload = (body) => ({
  kind: "row",
  type: text(body.type),
  catalog: text(body.catalog),
  sortOrder: Number.isFinite(Number(body.sortOrder)) ? Number(body.sortOrder) : 0,
  od: text(body.od),
  id: text(body.id),
  nominalWt: text(body.nominalWt),
  wallThickness: text(body.wallThickness),
  driftId: text(body.driftId),
  grade: text(body.grade),
  yieldPsi: text(body.yieldPsi),
  fatigueEndurance: text(body.fatigueEndurance),
  ultimateTensile: text(body.ultimateTensile),
  collapseStr: text(body.collapseStr),
  burstStr: text(body.burstStr),
  tensileStr: text(body.tensileStr),
  compressiveStr: text(body.compressiveStr),
  torsionalStr: text(body.torsionalStr),
  connectionType: text(body.connectionType),
  connectionOd: text(body.connectionOd),
  connectionId: text(body.connectionId),
  connectionGrade: text(body.connectionGrade),
  connectionYield: text(body.connectionYield),
  connectionUts: text(body.connectionUts),
  connectionBurst: text(body.connectionBurst),
  connectionTensile: text(body.connectionTensile),
  connectionCompressive: text(body.connectionCompressive),
  connectionTorsional: text(body.connectionTorsional),
  makeupTorque: text(body.makeupTorque),
  assemblyAdjustWt: text(body.assemblyAdjustWt),
});

const ensureSeedData = async () => {
  const existingCount = await TubularDatabase.countDocuments();
  if (existingCount > 0) {
    for (const [index, name] of DEFAULT_MATERIALS.entries()) {
      const exists = await TubularDatabase.findOne({ kind: "material", name });
      if (!exists) {
        await TubularDatabase.create({ kind: "material", name, sortOrder: index });
      }
    }

    await TubularDatabase.updateMany(
      {
        kind: "type",
        $or: [{ material: { $exists: false } }, { material: "" }, { material: null }],
      },
      { $set: { material: DEFAULT_MATERIALS[0] } }
    );

    const rowsNeedingConnection = await TubularDatabase.find({
      kind: "row",
      $or: [
        { connectionType: { $exists: false } },
        { connectionType: "" },
        { connectionId: { $exists: false } },
        { connectionId: "" },
        { assemblyAdjustWt: { $exists: false } },
        { assemblyAdjustWt: "" },
      ],
    });

    for (const row of rowsNeedingConnection) {
      const patch = {};
      if (!text(row.connectionType)) patch.connectionType = "Various";
      if (!text(row.connectionId)) patch.connectionId = text(row.id);
      if (!text(row.connectionOd)) patch.connectionOd = text(row.od);
      if (!text(row.assemblyAdjustWt)) patch.assemblyAdjustWt = text(row.nominalWt);
      if (Object.keys(patch).length > 0) {
        await TubularDatabase.updateOne({ _id: row._id }, { $set: patch });
      }
    }
    return;
  }

  const docs = [
    ...DEFAULT_TYPES.map((name, index) => ({
      kind: "type",
      name,
      material: DEFAULT_MATERIALS[0],
      sortOrder: index,
    })),
    ...DEFAULT_CATALOGS.map((name, index) => ({
      kind: "catalog",
      name,
      sortOrder: index,
    })),
    ...DEFAULT_MATERIALS.map((name, index) => ({
      kind: "material",
      name,
      sortOrder: index,
    })),
    ...DEFAULT_ROWS.map((row, index) => ({
      ...rowPayload({
        ...row,
        type: DEFAULT_TYPES[0],
        catalog: DEFAULT_CATALOGS[0],
        nominalWt: "0.000",
        connectionType: "Various",
        connectionId: row.id,
        assemblyAdjustWt: "7.900",
        sortOrder: index,
      }),
    })),
  ];

  await TubularDatabase.insertMany(docs);
};

const sendDatabase = async (res) => {
  await ensureSeedData();
  const [types, catalogs, materials, rows] = await Promise.all([
    TubularDatabase.find({ kind: "type" }).sort({ sortOrder: 1, name: 1 }).lean(),
    TubularDatabase.find({ kind: "catalog" }).sort({ sortOrder: 1, name: 1 }).lean(),
    TubularDatabase.find({ kind: "material" }).sort({ sortOrder: 1, name: 1 }).lean(),
    TubularDatabase.find({ kind: "row" }).sort({ type: 1, catalog: 1, sortOrder: 1, createdAt: 1 }).lean(),
  ]);

  res.status(200).json({
    success: true,
    data: { types, catalogs, materials, rows },
  });
};

export const getTubularDatabase = async (_req, res) => {
  try {
    await sendDatabase(res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createType = async (req, res) => {
  try {
    const name = text(req.body.name);
    const material = text(req.body.material) || DEFAULT_MATERIALS[0];
    if (!name) {
      return res.status(400).json({ success: false, message: "Type is required" });
    }

    const exists = await TubularDatabase.findOne({ kind: "type", name });
    if (exists) {
      return res.status(400).json({ success: false, message: "Type already exists" });
    }

    const sortOrder = await TubularDatabase.countDocuments({ kind: "type" });
    const data = await TubularDatabase.create({ kind: "type", name, material, sortOrder });
    res.status(201).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteType = async (req, res) => {
  try {
    const item = await TubularDatabase.findOne({ _id: req.params.id, kind: "type" });
    if (!item) {
      return res.status(404).json({ success: false, message: "Type not found" });
    }

    await TubularDatabase.deleteOne({ _id: item._id });
    await TubularDatabase.deleteMany({ kind: "row", type: item.name });
    res.status(200).json({ success: true, message: "Type deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createCatalog = async (req, res) => {
  try {
    const name = text(req.body.name);
    if (!name) {
      return res.status(400).json({ success: false, message: "Catalog is required" });
    }

    const exists = await TubularDatabase.findOne({ kind: "catalog", name });
    if (exists) {
      return res.status(400).json({ success: false, message: "Catalog already exists" });
    }

    const sortOrder = await TubularDatabase.countDocuments({ kind: "catalog" });
    const data = await TubularDatabase.create({ kind: "catalog", name, sortOrder });
    res.status(201).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createMaterial = async (req, res) => {
  try {
    const name = text(req.body.name);
    if (!name) {
      return res.status(400).json({ success: false, message: "Material is required" });
    }

    const exists = await TubularDatabase.findOne({ kind: "material", name });
    if (exists) {
      return res.status(200).json({ success: true, data: exists });
    }

    const sortOrder = await TubularDatabase.countDocuments({ kind: "material" });
    const data = await TubularDatabase.create({ kind: "material", name, sortOrder });
    res.status(201).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteCatalog = async (req, res) => {
  try {
    const item = await TubularDatabase.findOne({ _id: req.params.id, kind: "catalog" });
    if (!item) {
      return res.status(404).json({ success: false, message: "Catalog not found" });
    }

    await TubularDatabase.deleteOne({ _id: item._id });
    await TubularDatabase.deleteMany({ kind: "row", catalog: item.name });
    res.status(200).json({ success: true, message: "Catalog deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createRow = async (req, res) => {
  try {
    const payload = rowPayload(req.body);
    if (!payload.type || !payload.catalog) {
      return res.status(400).json({ success: false, message: "Type and catalog are required" });
    }

    const data = await TubularDatabase.create(payload);
    res.status(201).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateRow = async (req, res) => {
  try {
    const data = await TubularDatabase.findOneAndUpdate(
      { _id: req.params.id, kind: "row" },
      rowPayload(req.body),
      { new: true, runValidators: true }
    );

    if (!data) {
      return res.status(404).json({ success: false, message: "Row not found" });
    }

    res.status(200).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteRow = async (req, res) => {
  try {
    const deleted = await TubularDatabase.findOneAndDelete({
      _id: req.params.id,
      kind: "row",
    });

    if (!deleted) {
      return res.status(404).json({ success: false, message: "Row not found" });
    }

    res.status(200).json({ success: true, message: "Row deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
