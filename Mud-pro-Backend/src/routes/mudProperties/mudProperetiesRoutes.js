import express from 'express';
import {
  getSelectedMudProperties,
  saveSelectedMudProperties,
} from '../../controllers/mudProperties/mudPropertiesController.js';

const router = express.Router();



// GET saved/selected mud properties from DB
// GET /api/mud-properties/selected?userId=default
router.get('/selected', getSelectedMudProperties);

// POST save selected mud properties to DB
// POST /api/mud-properties/selected
router.post('/selected', saveSelectedMudProperties);

export default router;