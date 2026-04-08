import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

import operatorRoutes from "./routes/operator/operator.route.js";

import pitRoutes from "./routes/pit/pit.routes.js";
import inventoryRoutes from "./routes/inventory/inventory.routes.js";

import nozzleRoutes from "./routes/nozzle/nozzle.routes.js";
import unitSystemRoutes from "./routes/unitSystem/unitSystem.js";


import engineerRoutes from "./routes/engineer/engineer.routes.js";
import companyRoutes from "./routes/company/company.routes.js";

// Product routes imports would go here
import productRoutes from "./routes/product/product.routes.js";
import { errorHandler } from "./middlewares/error.middleware.js";
import consumeProductRoutes from "./routes/Consumeproduct/consumeProductRoutes.js";
import csPackageRoutes from "./routes/ConsumeServices/Packages/packageRoutes.js";
import csServiceRoutes from "./routes/ConsumeServices/Services/serviceRoutes.js";
import csEngineeringRoutes from "./routes/ConsumeServices/Engineers/engineeringRoutes.js";
import receiveProductRoutes from "./routes/ReceiveProduct/Product/receiveProductRoutes.js";
import receivePackageRoutes from "./routes/ReceiveProduct/Package/receivePackageRoutes.js";
import returnProductRoutes from "./routes/ReturnProduct/Product/returnProductRoutes.js";
import returnPackageRoutes from "./routes/ReturnProduct/Package/returnPackageRoutes.js";
import drillStringRoutes from "./routes/DrillString/drillString.routes.js";

import mudPropertiesRoute from "./routes/mudProperties/mudProperetiesRoutes.js";

import servicesRoutes from "./routes/service/service.routes.js";
import engineeringRoutes from "./routes/service/engineering.routes.js";
import packageRoutes from "./routes/service/package.routes.js";

//pump routes imports
import pumpRoutes from "./routes/pump/pump.routes.js";

//sce routes imports
import sceRoutes from "./routes/sce/sce.routes.js";


import wellGeneralRoutes from "./routes/wellGeneral/wellGeneralRoutes.js";
import intervalRoutes from "./routes/wellInterval/intervalRoutes.js";



import activityRoutes from './routes/others/otherActivity.routes.js';
import additionRoutes from './routes/others/otherAddition.route.js';
import lossRoutes from './routes/others/otherLoss.routes.js';
import waterBasedRoutes from './routes/others/otherWaterbase.route.js';
import oilBasedRoutes from './routes/others/otherOilbase.route.js';
import syntheticRoutes from './routes/others/otherSynthetic.route.js';

import ugInventoryRoutes from "./routes/ugInventory/ugInventoryProductsRoutes.js";

import inventorySnapshotRoutes from "./routes/FullInventory/inventorySnapshotRoutes.js";
import exportRoutes from "./routes/Export/exportRoutes.js";

import solidanalysisroute from "./routes/SolidAnalysis/solidanalysisroute.js"
import casingRoutes from "./routes/casing/casing.routes.js";
import volumeNameRoutes from "./routes/pitvolumename/volumeName.routes.js";
import transferMudRoutes from "./routes/transfermud/transferMud.routes.js";
import receiveMudRoutes from "./routes/receivemud/receiveMud.routes.js";
import returnLostMudRoutes from "./routes/returnlostmud/returnLostMud.routes.js";
import addWaterRoutes from "./routes/addwater/addWater.routes.js";
import movePitStatusRoutes from "./routes/movepit/movePitStatus.routes.js";
import otherVolAdditionRoutes from "./routes/othervol/otherVolAddition.routes.js";
import mudLossRoutes from "./routes/mudloss/mudLoss.routes.js";
import mudLossStorageRoutes from "./routes/mudlossstorage/mudLossStorage.routes.js";
import padRoutes from "./routes/pad/pad.routes.js";
import wellRoutes from "./routes/well/well.routes.js";
import emptyFluidActiveSystemRoutes from "./routes/emptyfluidactivesystem/emptyFluidActiveSystem.routes.js";
import operationRoutes from "./routes/operation/operation.routes.js";
import reportRoutes from "./routes/report/report.routes.js";



const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();


app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(helmet());
app.use(express.json());

// 🔹 Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, "uploads", "company-logos");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// 🔹 Serve static files
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    status: "ok",
    service: "mudpro_backend",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/engineers", engineerRoutes);
app.use("/api/company", companyRoutes);

//operator routes
app.use("/api/operators", operatorRoutes);

app.use("/api/pit", pitRoutes);


//service routes
app.use("/api/services", servicesRoutes);
app.use("/api/services/engineering", engineeringRoutes);
app.use("/api/services/packages", packageRoutes);

// Product routes
app.use("/api/v1/products", productRoutes);


//inventory routes

app.use('/api/inventory', inventoryRoutes);

app.use('/api/pump', pumpRoutes);

//sce routes

app.use('/api/sce', sceRoutes);


//other page routes
app.use('/api/activity', activityRoutes);
app.use('/api/addition', additionRoutes);
app.use('/api/loss', lossRoutes);
app.use('/api/waterbased', waterBasedRoutes);
app.use('/api/oilbased', oilBasedRoutes);
app.use('/api/synthetic', syntheticRoutes);

//consumeproduct routes
app.use("/api/consume-product", consumeProductRoutes);

//consumeservices package route
app.use("/api/cs/package", csPackageRoutes);
app.use("/api/cs/service", csServiceRoutes);
app.use("/api/cs/engineering", csEngineeringRoutes);
//receive product route
app.use("/api/receive-product", receiveProductRoutes);
app.use("/api/receive-package", receivePackageRoutes);
//return product route
app.use("/api/return-product", returnProductRoutes);
app.use("/api/return-package", returnPackageRoutes);


//snapshot route
app.use("/api/inventory", inventorySnapshotRoutes);

//export route
app.use("/api/export", exportRoutes);


//ug inventory product routes
app.use("/api/ug-inventory", ugInventoryRoutes);
//drill string
app.use("/api/drill-string", drillStringRoutes);

app.use("/api/well-general", wellGeneralRoutes);

//nozzle
app.use("/api/nozzle", nozzleRoutes);


app.use("/api/unit-systems", unitSystemRoutes);


//mud properties
app.use('/api/mud-properties', mudPropertiesRoute);

app.use('/api/solids',solidanalysisroute);
app.use('/api/casing', casingRoutes);
app.use("/api/volume-name", volumeNameRoutes);
app.use("/api/transfer-mud", transferMudRoutes);
app.use("/api/receive-mud", receiveMudRoutes);
app.use("/api/return-lost-mud", returnLostMudRoutes);
app.use("/api/add-water", addWaterRoutes);
app.use("/api/move-pit-status", movePitStatusRoutes);
app.use("/api/other-vol-addition", otherVolAdditionRoutes);
app.use("/api/mud-loss", mudLossRoutes);
app.use("/api/mud-loss-storage", mudLossStorageRoutes);
app.use("/api/empty-fluid-active-system", emptyFluidActiveSystemRoutes);

app.use("/api/intervals", intervalRoutes);
app.use("/api/pads", padRoutes);
app.use("/api/wells", wellRoutes);
app.use("/api/operations", operationRoutes);
app.use("/api/reports", reportRoutes);


// Error handler (ALWAYS LAST)
app.use(errorHandler);

export default app;
