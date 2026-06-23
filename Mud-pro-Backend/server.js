import dotenv from "dotenv";

dotenv.config();

await import("./src/plugins/installationScopePlugin.js");
const { default: app } = await import("./src/app.js");
const { default: connectDB } = await import("./src/config/db.js");

connectDB();


const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
