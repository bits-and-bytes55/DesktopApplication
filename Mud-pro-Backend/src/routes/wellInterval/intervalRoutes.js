import express from "express";
import {
  getIntervals,
  createInterval,
  updateInterval,
  deleteInterval,
  createGroup,
  deleteGroup,
  toggleGroupCollapse,
} from "../../controllers/wellInterval/intervalController.js";

const router = express.Router();

// ── Interval endpoints ────────────────────────────────────────────
router.get("/:wellId",      getIntervals);    // GET  all intervals+groups for a well
router.post("/",            createInterval);  // POST create interval
router.put("/:id",          updateInterval);  // PUT  update interval (name + data)
router.delete("/:id",       deleteInterval);  // DELETE remove interval

// ── Group endpoints ───────────────────────────────────────────────
router.post("/groups",              createGroup);          // POST create group
router.delete("/groups/:id",        deleteGroup);          // DELETE remove group
router.patch("/groups/:id/collapse", toggleGroupCollapse); // PATCH toggle collapse

export default router;

