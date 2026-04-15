// routes/others/activity.routes.js
import express from "express";
import { 
  createActivity, 
  createBulkActivities,
  getActivities, 
  updateActivity, 
  deleteActivity 
} from "../../controllers/others/others.controller.js";

const router = express.Router();

router.post("/add-activity", createActivity);
router.post("/add-bulk-activities", createBulkActivities);
router.get("/get-activities", getActivities);
router.put("/:id", updateActivity);
router.delete("/:id", deleteActivity);

export default router;











