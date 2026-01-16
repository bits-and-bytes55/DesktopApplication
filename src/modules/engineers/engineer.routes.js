const express = require('express');
const router = express.Router();

const controller = require('./engineer.controller');

// POST
router.post('/', controller.createEngineer);

// GET
router.get('/', controller.getEngineers);

module.exports = router;
