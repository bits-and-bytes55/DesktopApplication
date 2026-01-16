const express = require("express");
const cors = require("cors");

const engineerRoutes = require("./modules/engineers/engineer.routes");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/api/engineers", engineerRoutes);

// app.get("/", (req, res) => {
//   res.send(`Server running on http://localhost:${PORT}`);
// });

module.exports = app;
