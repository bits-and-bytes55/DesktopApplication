const express = require("express");
const router = express.Router();
const controller = require("./engineer.controller");

router.post("/add-engineers", controller.createEngineer);
router.get("/get-engineers", controller.getEngineers);

module.exports = router;
