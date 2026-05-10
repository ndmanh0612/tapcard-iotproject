import mongoose from "mongoose";
import dotenv from "dotenv";
import path from "path";

// Load .env manually before anything else
dotenv.config({ path: path.resolve(__dirname, ".env") });

import UserModel from "./src/models/user.model";
import env from "./src/configurations/env.config";

async function elevate() {
  try {
    await mongoose.connect(env.ATLAS);
    const user = await UserModel.findOneAndUpdate(
      { mobileNo: "0912035034" },
      { type: "admin", verified: true, verifiedEmail: true, verifiedMobileNo: true },
      { new: true }
    );
    if (user) {
      console.log("✅ User elevated to admin:", user.name);
    } else {
      console.log("❌ User not found.");
    }
  } catch (error) {
    console.error("❌ Error:", error);
  } finally {
    await mongoose.disconnect();
  }
}

elevate();
