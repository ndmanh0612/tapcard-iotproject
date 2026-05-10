# 🪪 TapTag - Hệ thống Điểm danh Thông minh RFID

**TapTag** là một giải pháp điểm danh hiện đại sử dụng công nghệ RFID, kết hợp giữa phần cứng ESP32, ứng dụng di động Flutter và hệ thống Backend Express mạnh mẽ. Dự án giúp việc quản lý hiện diện trở nên nhanh chóng, chính xác và trực quan.

---

## ✨ Tính năng chính

- **Xác thực RFID:** Sử dụng thẻ/móc khóa RFID để điểm danh nhanh chóng.
- **Tương tác Thời gian thực:** Tích hợp WebSockets giúp cập nhật trạng thái quẹt thẻ ngay lập tức lên ứng dụng.
- **Kết nối Linh hoạt:** ESP32 hỗ trợ cả chế độ Wi-Fi Hotspot và Client.
- **Đa nền tảng:** Ứng dụng Flutter hỗ trợ Android, Windows và Web.
- **Quản lý Backend:** Hệ thống quản trị người dùng, nhật ký điểm danh và bảo mật API.

---

## 🏗️ Cấu trúc dự án

Dự án được chia thành 3 phần chính:
- `arduino/`: Mã nguồn firmware cho vi điều khiển ESP32.
- `flutter/`: Ứng dụng di động và giao diện người dùng.
- `express/`: Hệ thống Backend (TypeScript, Node.js, MongoDB).

---

## 🔌 Sơ đồ đấu nối (Hardware)

Để hệ thống hoạt động, bạn cần kết nối module **RFID RC522** với **ESP32** theo sơ đồ sau:

| RFID RC522 Pin | ESP32 Pin | Chức năng |
| :--- | :--- | :--- |
| **SDA (SS)** | GPIO 5 | Chip Select |
| **SCK** | GPIO 18 | Serial Clock |
| **MOSI** | GPIO 23 | Master Out Slave In |
| **MISO** | GPIO 19 | Master In Slave Out |
| **GND** | GND | Ground |
| **RST** | GPIO 22 | Reset |
| **3.3V** | 3.3V | Nguồn cấp (VCC) |

*Lưu ý: Pin IRQ không cần kết nối trong chế độ SPI mặc định.*

---

## 🚀 Hướng dẫn cài đặt

### 1. Nạp code ESP32
1. Mở file `.ino` trong thư mục `arduino/` bằng **Arduino IDE**.
2. Cài đặt các thư viện cần thiết: `MFRC522`, `ArduinoJson`.
3. Chọn board **ESP32 Dev Module** và cổng COM tương ứng.
4. Nhấn **Upload**.

### 2. Thiết lập Backend
1. Truy cập thư mục `express/`: `cd express`
2. Cài đặt thư viện: `npm install`
3. Cấu hình file `.env` (MongoDB URI, Port, Secret Key).
4. Khởi chạy server: `npm run dev`

### 3. Khởi chạy ứng dụng Flutter
1. Truy cập thư mục `flutter/`: `cd flutter`
2. Lấy các gói phụ thuộc: `flutter pub get`
3. Chạy ứng dụng: `flutter run`

---

## 🛠️ Yêu cầu hệ thống
- **Phần cứng:** ESP32, Module RC522, Thẻ RFID 13.56MHz.
- **Phần mềm:** Flutter SDK, Node.js & npm, MongoDB, Arduino IDE.

---

## 📄 Tài liệu bổ sung
- **API Documentation:** [Postman Collection](https://www.postman.com/s-m-quadri/taptag)
- **Demo Video:** [Youtube link](https://www.youtube.com/watch?v=MczDsma9pwM)

---
*Dự án này được phát triển cho mục đích học tập và trình diễn công nghệ.*
