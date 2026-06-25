# 🪪 TapTag - Hệ thống Điểm danh Thông minh RFID & LCD

**TapTag** là một giải pháp điểm danh thông minh tích hợp IoT toàn diện, kết hợp giữa vi điều khiển **ESP32**, ứng dụng di động **Flutter** đa nền tảng và hệ thống quản trị **Backend Express (TypeScript)**. Hệ thống cho phép điểm danh thời gian thực bằng thẻ RFID, hiển thị kết quả trực tiếp lên màn hình LCD của thiết bị quét và cập nhật tức thời lên ứng dụng quản lý của giáo viên/quản trị viên.

---

## 🏗️ Kiến trúc & Công nghệ sử dụng

Hệ thống được chia thành 3 phần chính hoạt động đồng bộ:

### 1. Backend API (`express/`)
* **Framework:** Node.js, Express, TypeScript.
* **Database:** MongoDB Atlas (sử dụng Mongoose ORM).
* **Real-time:** Socket.io (phát tín hiệu điểm danh và trạng thái quét thẻ lập tức về ứng dụng di động).
* **Bảo mật:** Giải mã dữ liệu thẻ RFID bằng thuật toán **AES-256-CBC** (mã hóa đầu cuối từ ESP32).
* **Tính năng phụ:** Helper tự động chuẩn hóa tên học sinh sang dạng **tiếng Việt không dấu viết hoa** để hiển thị tối ưu trên màn hình LCD.

### 2. Mobile Application (`flutter/`)
* **Framework:** Flutter (Dart).
* **State Management:** Provider.
* **Real-time:** Socket.io Client.
* **Nền tảng:** Android (chạy mượt trên máy ảo và máy thật), hỗ trợ build sang iOS, Web và Desktop.

### 3. Firmware IoT (`arduino/`)
* **Vi điều khiển:** ESP32.
* **Thiết bị ngoại vi:** Đầu đọc thẻ RFID MFRC522 (kết nối qua SPI), Màn hình hiển thị LCD 1602 tích hợp module I2C.
* **Bảo mật:** Mã hóa cứng thẻ UID bằng thư viện **AESLib** trước khi gửi lên API để tránh giả mạo dữ liệu đường truyền.
* **Giao thức mạng:** HTTP Client gửi dữ liệu dưới dạng JSON payload.

---

## 🔌 Sơ đồ đấu nối phần cứng (ESP32)

Để hệ thống hoạt động chính xác với màn hình LCD và đầu đọc thẻ, hãy đấu dây theo sơ đồ chi tiết dưới đây.

> [!WARNING]
> Chân **RST** của module RFID đã được chuyển sang **GPIO 4** để nhường chân **GPIO 22** làm chân SCL cho màn hình LCD I2C.

| Thiết bị ngoại vi | Chân trên Module | Chân trên ESP32 | Ghi chú |
| :--- | :--- | :--- | :--- |
| **LCD 1602 I2C** | GND | GND | Đất chung |
| | VCC | 5V (hoặc VIN) | Hiển thị tốt nhất ở nguồn 5V |
| | SDA | **GPIO 21** | Chân dữ liệu I2C mặc định |
| | SCL | **GPIO 22** | Chân clock I2C mặc định |
| **RFID MFRC522** | RST | **GPIO 4** | **ĐÃ CẬP NHẬT** (Tránh xung đột I2C) |
| | MISO | GPIO 19 | Giao tiếp SPI |
| | MOSI | GPIO 23 | Giao tiếp SPI |
| | SCK | GPIO 18 | Giao tiếp SPI |
| | SDA (SS) | GPIO 5 | Chip Select SPI |
| | 3.3V | 3.3V | Nguồn cấp cho RFID |
| | GND | GND | Đất chung |

---

## 🚀 Hướng dẫn khởi chạy hệ thống

### Bước 1: Khởi động Backend Express
1. Di chuyển vào thư mục backend:
   ```bash
   cd express
   ```
2. Cài đặt các gói phụ thuộc:
   ```bash
   npm install
   ```
3. Tạo file cấu hình môi trường `.env` trong thư mục `express/` với các biến sau:
   ```env
   PORT=8080
   ATLAS=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<dbname>
   SECRET=taptag_secret_2026_demo
   JWT_SECRET=taptag_jwt_secret_2026_demo
   ```
4. Khởi chạy server ở chế độ phát triển:
   ```bash
   npm run dev
   ```
   *Mặc định server sẽ lắng nghe tại cổng `8080`.*

---

### Bước 2: Nạp Firmware cho ESP32
1. Mở file [arduino.ino](file:///c:/IOT%20project/taptag/arduino/arduino.ino) bằng **Arduino IDE**.
2. Cài đặt các thư viện cần thiết thông qua **Library Manager**:
   * `MFRC522`
   * `LiquidCrystal I2C` (bởi Frank de Brabander)
   * `ArduinoJson` (Hỗ trợ cả phiên bản v6 và v7)
   * `AESLib`
3. Cấu hình WiFi và URL Server trong code:
   ```cpp
   const char *ssid = "Tên_WiFi_Của_Bạn";
   const char *password = "Mật_Khẩu_WiFi";
   
   // Dùng IP nội bộ máy tính của bạn (VD: 192.168.1.5)
   const char *serverUrl = "http://<IP_MAY_TINH>:8080/attendance/swipe";
   ```
4. Chọn đúng Board (**ESP32 Dev Module**) và cổng COM của thiết bị, sau đó bấm **Upload**.

---

### Bước 3: Chạy ứng dụng Flutter
1. Cấu hình địa chỉ IP máy tính (hoặc link ngrok) trong file cấu hình [constants.dart](file:///c:/IOT%20project/taptag/flutter/lib/core/constants.dart):
   ```dart
   static const String baseUrl = 'http://<IP_MAY_TINH>:8080';
   ```
2. Di chuyển vào thư mục app di động:
   ```bash
   cd flutter
   ```
3. Tải các gói phụ thuộc Dart:
   ```bash
   flutter pub get
   ```
4. Khởi chạy ứng dụng (trên máy ảo hoặc thiết bị thực kết nối qua USB):
   ```bash
   flutter run
   ```
   > [!TIP]
   > Để biên dịch thành ứng dụng Android cài trực tiếp trên máy thật, bạn có thể chạy lệnh:
   > `flutter build apk --release`
   > File cài đặt sẽ được tạo ra tại thư mục `flutter/build/app/outputs/flutter-apk/app-release.apk`.

---

## 🛠️ Trạng thái hiển thị trên màn hình LCD 1602

Thiết bị quét thẻ ESP32 sẽ tự động phân tích phản hồi từ backend và hiển thị các trạng thái trực quan lên LCD 1602:
* **Điểm danh thành công:**
  * Dòng 1: `DIEM DANH OK!`
  * Dòng 2: `[TÊN HỌC SINH KHÔNG DẤU]` (Ví dụ: `NGUYEN VAN ANH`)
* **Chưa mở phiên điểm danh:**
  * Dòng 1: `PHIEN CHUA MO`
  * Dòng 2: `Vui long mo phien` (giáo viên cần mở ca trên App Flutter trước)
* **Thẻ chưa đăng ký:**
  * Dòng 1: `THE CHUA DANG KY`
  * Dòng 2: `Vui long gan the` (khi chế độ gán thẻ đang tắt)
* **Chế độ gán thẻ (Binding mode):**
  * Dòng 1: `CHE DO GAN THE`
  * Dòng 2: `[Mã UID thẻ]` (sau đó gán cho học sinh trên App Flutter)
* **Lỗi kết nối / WiFi:**
  * Hiển thị `Connection Error` hoặc `WiFi Disconnected`.

---
*Dự án này được tối ưu hóa cho việc dạy học, quản lý lớp học và nghiên cứu các ứng dụng IoT thực tế.*
