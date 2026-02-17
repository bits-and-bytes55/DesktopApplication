import { Router } from "express";
import { 
  saveOperators, 
  getOperators, 
  updateOperator, 
  deleteOperator 
} from "../../controllers/operator/operator.controller.js";

const router = Router();

router.post("/add-operators", saveOperators);
router.get("/get-operators", getOperators);
router.put("/:id", updateOperator);
router.delete("/:id", deleteOperator);

export default router;