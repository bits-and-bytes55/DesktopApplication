import express from "express";
import { transferMud } from "../../controllers/transfermud/transferMud.controller.js";

const router = express.Router();

router.post("/", transferMud);

export default router;