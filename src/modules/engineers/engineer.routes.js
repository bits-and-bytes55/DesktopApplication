const express = require("express");
const router = express.Router();
const controller = require("./engineer.controller");

router.post("/", controller.createEngineer);
router.get("/", controller.getEngineers);

module.exports = router;
