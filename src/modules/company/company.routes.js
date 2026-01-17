const express = require("express");
const router = express.Router();
const controller = require("./company.controller");

router.get("/get-company-details", controller.getCompany);
router.post("/add-company-details", controller.saveCompany);
router.put("/update-company-details", controller.updateCompany);


module.exports = router;
