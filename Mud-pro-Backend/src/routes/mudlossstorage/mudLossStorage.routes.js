import express from "express";
import { createMudLossStorage } from "../../controllers/mudlossstorage/mudLossStorage.controller.js";

const router = express.Router();

router.post("/", createMudLossStorage);

export default router;