import express from "express";
import cors from "cors";
import helmet from "helmet";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

import engineerRoutes from "./routes/engineer.routes.js";
import companyRoutes from "./routes/company.routes.js";

// Product routes imports would go here
import productRoutes from "./routes/product/product.routes.js";
import { errorHandler } from "./middlewares/error.middleware.js";
import consumeProductRoutes from "./routes/Consumeproduct/consumeProductRoutes.js";
import packageRoutes from "./routes/ConsumeServices/Packages/packageRoutes.js";
import serviceRoutes from "./routes/ConsumeServices/Services/serviceRoutes.js";
import engineeringRoutes from "./routes/ConsumeServices/Engineers/engineeringRoutes.js";
import receiveProductRoutes from "./routes/ReceiveProduct/Product/receiveProductRoutes.js";
import receivePackageRoutes from "./routes/ReceiveProduct/Package/receivePackageRoutes.js";
import returnProductRoutes from "./routes/ReturnProduct/Product/returnProductRoutes.js";
import returnPackageRoutes from "./routes/ReturnProduct/Package/returnPackageRoutes.js";
import inventorySnapshotRoutes from "./routes/FullInventory/inventorySnapshotRoutes.js";



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

app.use("/api/engineers", engineerRoutes);
app.use("/api/company", companyRoutes);


// Product routes
app.use("/api/v1/products", productRoutes);

//consumeproduct routes
app.use("/api/consume-product", consumeProductRoutes);

//consumeservices package route
app.use("/api/package", packageRoutes);
app.use("/api/service", serviceRoutes);
app.use("/api/engineering", engineeringRoutes);
//receive product route
app.use("/api/receive-product", receiveProductRoutes);
app.use("/api/receive-package", receivePackageRoutes);
//return product route
app.use("/api/return-product", returnProductRoutes);
app.use("/api/return-package", returnPackageRoutes);
app.use("/api/inventory", inventorySnapshotRoutes);




// Error handler (ALWAYS LAST)
app.use(errorHandler);

export default app;
