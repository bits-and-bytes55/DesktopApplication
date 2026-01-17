const express = require("express");
const cors = require("cors");

const engineerRoutes = require("./modules/engineers/engineer.routes");
const companyRoutes = require("./modules/company/company.routes");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/api/engineers", engineerRoutes);
app.use("/api/company", companyRoutes);

// app.get("/", (req, res) => {
//   res.send(`Server running on http://localhost:${PORT}`);
// });

module.exports = app;
