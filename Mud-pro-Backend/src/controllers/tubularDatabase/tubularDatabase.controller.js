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
const DEFAULT_MATERIAL_PROPERTIES = {
  Steel: {
    density: "7.85",
    elasticModulus: "29.00",
    poissonRatio: "0.30",
    compressibility: "10.0000",
    heatCapacity: "0.11",
    thermalConductivity: "",
  },
  Aluminium: {
    density: "2.80",
    elasticModulus: "10.00",
    poissonRatio: "0.32",
    compressibility: "146.0000",
    heatCapacity: "0.21",
    thermalConductivity: "",
  },
};

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

const CWS_WEATHERFORD_ROW_LIMIT = 81;

const CWS_WEATHERFORD_SUPER_WELD_KEY = {
  kind: "row",
  type: "CWS",
  catalog: "Weatherford",
  od: "2.720",
};

const CWS_WEATHERFORD_SUPER_WELD_FILTER = {
  ...CWS_WEATHERFORD_SUPER_WELD_KEY,
  nominalWt: "0.000",
  grade: "Super weld",
};

const CWS_WEATHERFORD_SUPER_WELD_CLEANUP_FILTER = {
  kind: "row",
  type: { $regex: /^\s*CWS\s*$/i },
  catalog: { $regex: /^\s*Weatherford\s*$/i },
  grade: { $regex: /^\s*super\s*weld\s*$/i },
  $and: [
    { $or: [{ od: "2.720" }, { od: "2.72" }, { od: 2.72 }] },
    {
      $or: [
        { nominalWt: "0.000" },
        { nominalWt: "0.00" },
        { nominalWt: "0.0" },
        { nominalWt: "0" },
        { nominalWt: 0 },
      ],
    },
  ],
};

const CWS_WEATHERFORD_DURA_GRIP_KEY = {
  kind: "row",
  type: "CWS",
  catalog: "Weatherford",
  od: "2.730",
};

const CWS_WEATHERFORD_DURA_GRIP_FILTER = {
  ...CWS_WEATHERFORD_DURA_GRIP_KEY,
  nominalWt: "0.000",
  grade: "Dura Grip",
};

const CWS_WEATHERFORD_DURA_GRIP_CLEANUP_FILTER = {
  kind: "row",
  type: { $regex: /^\s*CWS\s*$/i },
  catalog: { $regex: /^\s*Weatherford\s*$/i },
  grade: { $regex: /^\s*dura\s*grip\s*$/i },
  $and: [
    { $or: [{ od: "2.730" }, { od: "2.73" }, { od: 2.73 }] },
    {
      $or: [
        { nominalWt: "0.000" },
        { nominalWt: "0.00" },
        { nominalWt: "0.0" },
        { nominalWt: "0" },
        { nominalWt: 0 },
      ],
    },
  ],
};

const cwsWeatherfordSuperWeldRow = (sortOrder) =>
  rowPayload({
    ...CWS_WEATHERFORD_SUPER_WELD_FILTER,
    id: "1.995",
    yieldPsi: "33034",
    connectionType: "Various",
    connectionOd: "2.820",
    connectionId: "1.995",
    assemblyAdjustWt: "7.900",
    sortOrder,
  });

const cwsWeatherfordDuraGripRow = (sortOrder) =>
  rowPayload({
    ...CWS_WEATHERFORD_DURA_GRIP_FILTER,
    id: "1.995",
    yieldPsi: "32516",
    connectionType: "Various",
    connectionOd: "2.730",
    connectionId: "1.995",
    assemblyAdjustWt: "7.300",
    sortOrder,
  });

const isExactCwsWeatherfordSuperWeldRows = (rows) =>
  rows.length === CWS_WEATHERFORD_ROW_LIMIT &&
  rows.every(
    (row, index) =>
      Number(row.sortOrder) === index &&
      text(row.kind) === "row" &&
      text(row.type) === "CWS" &&
      text(row.catalog) === "Weatherford" &&
      text(row.od) === "2.720" &&
      text(row.nominalWt) === "0.000" &&
      text(row.grade) === "Super weld" &&
      text(row.id) === "1.995" &&
      text(row.yieldPsi) === "33034" &&
      text(row.connectionType) === "Various" &&
      text(row.connectionOd) === "2.820" &&
      text(row.connectionId) === "1.995" &&
      text(row.assemblyAdjustWt) === "7.900"
);

const isExactCwsWeatherfordDuraGripRows = (rows) =>
  rows.length === CWS_WEATHERFORD_ROW_LIMIT &&
  rows.every(
    (row, index) =>
      Number(row.sortOrder) === index &&
      text(row.kind) === "row" &&
      text(row.type) === "CWS" &&
      text(row.catalog) === "Weatherford" &&
      text(row.od) === "2.730" &&
      text(row.nominalWt) === "0.000" &&
      text(row.grade) === "Dura Grip" &&
      text(row.id) === "1.995" &&
      text(row.yieldPsi) === "32516" &&
      text(row.connectionType) === "Various" &&
      text(row.connectionOd) === "2.730" &&
      text(row.connectionId) === "1.995" &&
      text(row.assemblyAdjustWt) === "7.300"
);

const isCwsWeatherfordSuperWeldCandidate = (row) =>
  text(row.kind) === "row" &&
  /^CWS$/i.test(text(row.type)) &&
  /^Weatherford$/i.test(text(row.catalog)) &&
  ["2.720", "2.72"].includes(text(row.od)) &&
  ["0.000", "0.00", "0.0", "0"].includes(text(row.nominalWt)) &&
  /^super\s*weld$/i.test(text(row.grade));

const isCwsWeatherfordDuraGripCandidate = (row) =>
  text(row.kind) === "row" &&
  /^CWS$/i.test(text(row.type)) &&
  /^Weatherford$/i.test(text(row.catalog)) &&
  ["2.730", "2.73"].includes(text(row.od)) &&
  ["0.000", "0.00", "0.0", "0"].includes(text(row.nominalWt)) &&
  /^dura\s*grip$/i.test(text(row.grade));

const capCwsWeatherfordSuperWeldRows = (rows) => {
  const counts = new Map();
  return rows.filter((row) => {
    const key = isCwsWeatherfordSuperWeldCandidate(row)
      ? "super-weld-2.720"
      : isCwsWeatherfordDuraGripCandidate(row)
        ? "dura-grip-2.730"
        : "";
    if (!key) return true;
    const nextCount = (counts.get(key) || 0) + 1;
    counts.set(key, nextCount);
    return nextCount <= CWS_WEATHERFORD_ROW_LIMIT;
  });
};

const ensureCwsWeatherfordSuperWeldRows = async () => {
  const rows = await TubularDatabase.find(CWS_WEATHERFORD_SUPER_WELD_CLEANUP_FILTER)
    .sort({ sortOrder: 1, createdAt: 1 })
    .lean();

  if (isExactCwsWeatherfordSuperWeldRows(rows)) return;

  await TubularDatabase.deleteMany(CWS_WEATHERFORD_SUPER_WELD_CLEANUP_FILTER);
  await TubularDatabase.insertMany(
    Array.from({ length: CWS_WEATHERFORD_ROW_LIMIT }, (_item, index) =>
      cwsWeatherfordSuperWeldRow(index)
    )
  );
};

const ensureCwsWeatherfordDuraGripRows = async () => {
  const rows = await TubularDatabase.find(CWS_WEATHERFORD_DURA_GRIP_CLEANUP_FILTER)
    .sort({ sortOrder: 1, createdAt: 1 })
    .lean();

  if (isExactCwsWeatherfordDuraGripRows(rows)) return;

  await TubularDatabase.deleteMany(CWS_WEATHERFORD_DURA_GRIP_CLEANUP_FILTER);
  await TubularDatabase.insertMany(
    Array.from({ length: CWS_WEATHERFORD_ROW_LIMIT }, (_item, index) =>
      cwsWeatherfordDuraGripRow(index)
    )
  );
};

const materialProperties = (name) => DEFAULT_MATERIAL_PROPERTIES[name] || {};

const materialPayload = (body) => ({
  name: text(body.name),
  density: text(body.density),
  elasticModulus: text(body.elasticModulus),
  poissonRatio: text(body.poissonRatio),
  compressibility: text(body.compressibility),
  heatCapacity: text(body.heatCapacity),
  thermalConductivity: text(body.thermalConductivity),
});

const ensureSeedData = async () => {
  const existingCount = await TubularDatabase.countDocuments();
  if (existingCount > 0) {
    for (const [index, name] of DEFAULT_MATERIALS.entries()) {
      const exists = await TubularDatabase.findOne({ kind: "material", name });
      if (!exists) {
        await TubularDatabase.create({
          kind: "material",
          name,
          ...materialProperties(name),
          sortOrder: index,
        });
      } else {
        const defaults = materialProperties(name);
        const patch = {};
        for (const [key, value] of Object.entries(defaults)) {
          if (!text(exists[key])) patch[key] = value;
        }
        if (Object.keys(patch).length > 0) {
          await TubularDatabase.updateOne({ _id: exists._id }, { $set: patch });
        }
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
    await ensureCwsWeatherfordSuperWeldRows();
    await ensureCwsWeatherfordDuraGripRows();
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
      ...materialProperties(name),
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
  await ensureCwsWeatherfordSuperWeldRows();
  await ensureCwsWeatherfordDuraGripRows();
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
    data: { types, catalogs, materials, rows: capCwsWeatherfordSuperWeldRows(rows) },
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
    const payload = materialPayload(req.body);
    const name = payload.name;
    if (!name) {
      return res.status(400).json({ success: false, message: "Material is required" });
    }

    const exists = await TubularDatabase.findOne({ kind: "material", name });
    if (exists) {
      return res.status(200).json({ success: true, data: exists });
    }

    const sortOrder = await TubularDatabase.countDocuments({ kind: "material" });
    const data = await TubularDatabase.create({
      kind: "material",
      ...payload,
      sortOrder,
    });
    res.status(201).json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateMaterial = async (req, res) => {
  try {
    const payload = materialPayload(req.body);
    const name = payload.name;
    if (!name) {
      return res.status(400).json({ success: false, message: "Material is required" });
    }

    const item = await TubularDatabase.findOne({ _id: req.params.id, kind: "material" });
    if (!item) {
      return res.status(404).json({ success: false, message: "Material not found" });
    }

    const duplicate = await TubularDatabase.findOne({
      _id: { $ne: item._id },
      kind: "material",
      name,
    });
    if (duplicate) {
      return res.status(400).json({ success: false, message: "Material already exists" });
    }

    const oldName = item.name;
    Object.assign(item, payload);
    await item.save();
    if (oldName !== name) {
      await TubularDatabase.updateMany(
        { kind: "type", material: oldName },
        { $set: { material: name } }
      );
    }

    res.status(200).json({ success: true, data: item });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteMaterial = async (req, res) => {
  try {
    const item = await TubularDatabase.findOne({ _id: req.params.id, kind: "material" });
    if (!item) {
      return res.status(404).json({ success: false, message: "Material not found" });
    }

    const count = await TubularDatabase.countDocuments({ kind: "material" });
    if (count <= 1) {
      return res.status(400).json({
        success: false,
        message: "At least one material is required",
      });
    }

    await TubularDatabase.deleteOne({ _id: item._id });
    const fallback = await TubularDatabase.findOne({ kind: "material" })
      .sort({ sortOrder: 1, name: 1 })
      .lean();
    await TubularDatabase.updateMany(
      { kind: "type", material: item.name },
      { $set: { material: fallback?.name || DEFAULT_MATERIALS[0] } }
    );

    res.status(200).json({ success: true, message: "Material deleted" });
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
      { returnDocument: "after", runValidators: true }
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
