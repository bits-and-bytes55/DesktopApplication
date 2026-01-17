const express = require("express");
const router = express.Router();
const controller = require("./company.controller");

router.get("/get-company-details", controller.getCompany);
router.post("/add-company-details", controller.saveCompany);

module.exports = router;
