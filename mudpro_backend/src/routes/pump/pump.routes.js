import express from 'express';
import pumpController from '../../controllers/pump/pump.controller.js';

const router = express.Router();


// Get all pumps for a well
router.get('/well/:wellId', pumpController.getPumps);

// Get single pump by ID
router.get('/:id', pumpController.getPumpById);

// Create new pump
router.post('/well/:wellId', pumpController.createPump);

// Update pump
router.put('/:id', pumpController.updatePump);

// Delete pump
router.delete('/:id', pumpController.deletePump);

// Delete all pumps for a well
router.delete('/well/:wellId/all', pumpController.deleteAllPumps);

// Bulk create/update pumps
router.post('/well/:wellId/bulk', pumpController.bulkUpsertPumps);

export default router;