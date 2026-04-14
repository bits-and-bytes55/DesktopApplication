import express from 'express';
const router = express.Router();
import { 
  addPit, 
  bulkAddPits, 
  getAllPits, 
  getSelectedPits, 
  getUnselectedPits, 
  getPitById, 
  updatePit, 
  bulkUpdatePits, 
  toggleLockPit, 
  deletePit, 
  bulkDeletePits, 
  deleteAllPitsByWell 
} from '../../controllers/pit/pit.controller.js';

// ============= CREATE ROUTES =============
// Add single pit
router.post('/add', addPit);

// Bulk add pits
router.post('/bulk-add', bulkAddPits);

// ============= READ ROUTES =============
// Get all pits for a well
router.get('/well/:wellId', getAllPits);

// Get selected (active) pits
router.get('/well/:wellId/selected', getSelectedPits);

// Get unselected (inactive) pits
router.get('/well/:wellId/unselected', getUnselectedPits);

// Get single pit by ID
router.get('/:id', getPitById);

// ============= UPDATE ROUTES =============
// Update single pit
router.put('/:id', updatePit);

// Bulk update pits
router.put('/bulk-update', bulkUpdatePits);

// Lock/Unlock pit
router.patch('/:id/toggle-lock', toggleLockPit);

// ============= DELETE ROUTES =============
// Delete single pit
router.delete('/:id', deletePit);

// Bulk delete pits
router.delete('/bulk-delete', bulkDeletePits);

// Delete all pits for a well (admin only - use with caution)
router.delete('/well/:wellId/all', deleteAllPitsByWell);

export default router;
