const express = require("express");
const cors = require("cors");

const path = require("path");
const fs = require("fs");

const engineerRoutes = require("./modules/engineers/engineer.routes");
const companyRoutes = require("./modules/company/company.routes");

const app = express();

app.use(express.urlencoded({ extended: true }));

// 🔹 Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, "uploads", "company-logos");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// 🔹 Serve static files (images)
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.use(cors());
app.use(express.json());
app.use("/api/engineers", engineerRoutes);
app.use("/api/company", companyRoutes);

// app.get("/", (req, res) => {
//   res.send(`Server running on http://localhost:${PORT}`);
// });

module.exports = app;
