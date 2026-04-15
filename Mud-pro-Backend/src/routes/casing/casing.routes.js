import express from 'express';
import {
  getAllCasings,
  addCasing,
  updateCasing,
  deleteCasing
} from '../../controllers/casing/casing.controller.js';

const router = express.Router();

router.get('/', getAllCasings);
router.post('/', addCasing);
router.put('/:id', updateCasing);
router.delete('/:id', deleteCasing);

export default router;
