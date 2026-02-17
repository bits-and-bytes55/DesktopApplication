import express from 'express';
import {
  getShakers,
  createShaker,
  updateShaker,
  deleteShaker,
  getOtherSce,
  createOtherSce,
  updateOtherSce,
  deleteOtherSce
} from '../../controllers/sce/sce.controller.js';

const router = express.Router();

// ==================== SHAKER ROUTES ====================
// GET all shakers for a well
router.get('/shakers/:wellId', getShakers);

// POST create a new shaker
router.post('/shakers/:wellId', createShaker);

// PUT update a shaker
router.put('/shakers/:id', updateShaker);

// DELETE a shaker
router.delete('/shakers/:id', deleteShaker);

// ==================== OTHER SCE ROUTES ====================
// GET all other SCE for a well
router.get('/other-sce/:wellId', getOtherSce);

// POST create a new other SCE
router.post('/other-sce/:wellId', createOtherSce);

// PUT update an other SCE
router.put('/other-sce/:id', updateOtherSce);

// DELETE an other SCE
router.delete('/other-sce/:id', deleteOtherSce);

export default router;