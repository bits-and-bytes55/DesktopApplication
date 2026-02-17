import express from 'express';
import * as inventoryController from '../../controllers/inventory/inventory.controller.js';

const router = express.Router();

// Note: If you have authentication middleware, import and use it
// import authMiddleware from '../../middleware/auth.js';
// router.use(authMiddleware);

// ==================== PREMIXED ROUTES ====================

// Get all premixed for a well
router.get('/get-premixed/:wellId', inventoryController.getPremixed);

// Create new premixed
router.post('/add-premixed/:wellId', inventoryController.createPremixed);

// Update premixed
router.put('/update-premixed/:id', inventoryController.updatePremixed);

// Delete premixed
router.delete('/delete-premixed/:id', inventoryController.deletePremixed);

// ==================== OBM ROUTES ====================

// Get all OBM for a well
router.get('/get-obm/:wellId', inventoryController.getObm);

// Create new OBM
router.post('/add-obm/:wellId', inventoryController.createObm);

// Update OBM
router.put('/update-obm/:id', inventoryController.updateObm);

// Delete OBM
router.delete('/delete-obm/:id', inventoryController.deleteObm);

export default router;