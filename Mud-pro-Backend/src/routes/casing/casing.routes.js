import express from 'express';
import {
  getAllCasings,
  addCasing,
  updateCasing,
  deleteCasing
} from '../../controllers/casing/casing.controller.js';

const router = express.Router();

router.get('/:wellId', getAllCasings);
router.post('/', addCasing);
router.put('/:wellId/:id', updateCasing);
router.delete('/:wellId/:id', deleteCasing);

export default router;
