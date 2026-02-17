import express from "express";
import { getCompany, saveCompany } from "../../controllers/company/company.controller.js";

const router = express.Router();

router.get("/get-company-details", getCompany);
router.post("/add-company-details", saveCompany);
router.put("/update-company-details", saveCompany);


export default router;
