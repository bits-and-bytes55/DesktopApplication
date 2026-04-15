import mongoose from "mongoose";

const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGO_URI_LOCAL || process.env.MONGO_URI;

    if (!mongoUri) {
      throw new Error("MONGO_URI_LOCAL or MONGO_URI is required");
    }

    await mongoose.connect(mongoUri);
    console.log("MongoDB Connected");
  } catch (err) {
    console.error("DB Connection Failed:", err.message);
    process.exit(1);
  }
};

export default connectDB;
