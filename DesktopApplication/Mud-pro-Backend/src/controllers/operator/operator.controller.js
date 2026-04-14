import Operator from "../../modules/operator/operator.model.js";
import cloudinary from "../../config/cloudinary.js";
import fs from "fs";

// ADD / UPDATE (bulk save from table)
export async function saveOperators(req, res) {
  try {
    const operators = req.body; // array

    if (!Array.isArray(operators)) {
      return res.status(400).json({
        success: false,
        message: "Array of operators required",
      });
    }

    // Handle logo image upload if present in the request
    const processedOperators = await Promise.all(
      operators.map(async (operator) => {
        if (operator.logoUrl && operator.logoUrl.startsWith('data:image')) {
          try {
            // Upload to cloudinary
            const uploadResult = await cloudinary.uploader.upload(operator.logoUrl, {
              folder: 'operator-logos',
              resource_type: 'image',
            });
            operator.logoUrl = uploadResult.secure_url;
          } catch (uploadError) {
            console.error("Error uploading logo:", uploadError);
            // Keep original base64 if upload fails
          }
        }
        return operator;
      })
    );

    const saved = await Operator.insertMany(processedOperators);

    res.json({
      success: true,
      message: "Operators saved successfully",
      data: saved,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// GET operators
export async function getOperators(req, res) {
  try {
    const operators = await Operator.find().sort({ createdAt: 1 });
    res.json({ success: true, data: operators });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// UPDATE operator
export async function updateOperator(req, res) {
  try {
    console.log("Updating operator:", req.params.id, req.body);
    
    let updateData = { ...req.body };
    
    // Handle logo image upload if present as base64
    if (updateData.logoUrl && updateData.logoUrl.startsWith('data:image')) {
      try {
        // Upload to cloudinary
        const uploadResult = await cloudinary.uploader.upload(updateData.logoUrl, {
          folder: 'operator-logos',
          resource_type: 'image',
        });
        updateData.logoUrl = uploadResult.secure_url;
      } catch (uploadError) {
        console.error("Error uploading logo:", uploadError);
        // Keep original base64 if upload fails
      }
    }
    
    const data = await Operator.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!data) {
      return res.status(404).json({ 
        success: false, 
        message: "Operator not found" 
      });
    }
    
    res.json({ 
      success: true, 
      data, 
      message: "Operator updated successfully" 
    });
  } catch (err) {
    console.error("Error updating operator:", err);
    res.status(500).json({ success: false, message: err.message });
  }
}

// DELETE operator
export async function deleteOperator(req, res) {
  try {
    console.log("Deleting operator:", req.params.id);
    const data = await Operator.findByIdAndDelete(req.params.id);
    
    if (!data) {
      return res.status(404).json({ 
        success: false, 
        message: "Operator not found" 
      });
    }
    
    res.json({ 
      success: true, 
      message: "Operator deleted successfully" 
    });
  } catch (err) {
    console.error("Error deleting operator:", err);
    res.status(500).json({ success: false, message: err.message });
  }
}
