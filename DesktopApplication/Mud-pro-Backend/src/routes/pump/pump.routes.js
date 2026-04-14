import express from 'express';
import pumpController from '../../controllers/pump/pump.controller.js';

const router = express.Router();

// Get all pumps
router.get('/', pumpController.getPumps);

// Get single pump
router.get('/:id', pumpController.getPumpById);

// Create pump
router.post('/', pumpController.createPump);

// Update pump
router.put('/:id', pumpController.updatePump);

// Delete pump
router.delete('/:id', pumpController.deletePump);

// Delete all pumps
router.delete('/', pumpController.deleteAllPumps);

// Bulk upsert pumps
router.post('/bulk', pumpController.bulkUpsertPumps);

export default router;