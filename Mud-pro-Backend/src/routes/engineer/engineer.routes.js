import { Router } from "express";
const router = Router();
import { 
  createEngineer, 
  getEngineers, 
  updateEngineer, 
  deleteEngineer 
} from "../../controllers/engineer/engineer.controller.js";

router.post("/add-engineers", createEngineer);
router.get("/get-engineers", getEngineers);
router.put("/update-engineer/:id", updateEngineer);
router.delete("/delete-engineer/:id", deleteEngineer);

export default router;