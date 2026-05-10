import 'dotenv/config';
import connectDB from "./src/configurations/db.config";
import ReaderModel from "./src/models/reader.model";

async function seed() {
    try {
        await connectDB();
        const ssid = "RFID-5UEV1KSG4TW";
        const existing = await ReaderModel.findOne({ ssid });
        if (!existing) {
            await ReaderModel.create({
                name: "DEMO READER",
                description: "Mạch ESP32 dùng cho Demo",
                ssid: ssid,
                password: "demo-password",
                secret: "Rw4ct/4Yf/XdyEnKdQI/pAS5hD0y/Sjj5jU/8p+3oFI=", // Trùng với SECRET_KEY trong Arduino
            });
            console.log("✅ Đã tạo Reader thành công!");
        } else {
            console.log("ℹ️ Reader đã tồn tại trong database.");
        }
    } catch (error) {
        console.error("❌ Lỗi khi tạo Reader:", error);
    } finally {
        process.exit();
    }
}
seed();
