#include <AESLib.h>
#include <Base64.h>
#include <HTTPClient.h>
#include <MFRC522.h>
#include <SPI.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ArduinoJson.h>

#define SS_PIN 5
#define RST_PIN 4  // Đã đổi từ 22 sang 4 để giải phóng chân SCL (GPIO 22) cho LCD I2C

const char *SECRET_KEY_BASE64 = "Rw4ct/4Yf/XdyEnKdQI/pAS5hD0y/Sjj5jU/8p+3oFI=";

const char *ssid = "Redmi Note 11";
const char *password = "11112222";

const char *serverUrl = "http://10.213.151.130:8080/attendance/swipe";
const char *readerId = "69ff24d6d49100db02e88893";

MFRC522 rfid(SS_PIN, RST_PIN);
AESLib aesLib;
byte aesKey[32];

// Khởi tạo LCD 1602 I2C với địa chỉ mặc định 0x27 (16 cột, 2 hàng)
LiquidCrystal_I2C lcd(0x27, 16, 2);

void decodeSecretKey() {
  char decodedKey[33];
  base64_decode(decodedKey, SECRET_KEY_BASE64, strlen(SECRET_KEY_BASE64));
  memcpy(aesKey, decodedKey, 32);
}

void setup() {
  Serial.begin(115200);
  decodeSecretKey();
  SPI.begin();
  rfid.PCD_Init();

  // Khởi tạo LCD
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("TAPTAG SYSTEM");
  lcd.setCursor(0, 1);
  lcd.print("Initializing...");
  delay(1500);

  WiFi.begin(ssid, password);
  Serial.print("[WiFi] Connecting");
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connecting");
  
  int dotCount = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    lcd.setCursor(dotCount % 16, 1);
    lcd.print(".");
    dotCount++;
  }
  
  Serial.println("\n[WiFi] Connected!");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected!");
  lcd.setCursor(0, 1);
  lcd.print(WiFi.localIP().toString());
  delay(2000);
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("READY TO SWIPE");
}

void loop() {
  // Kiểm tra đầu đọc RFID
  byte version = rfid.PCD_ReadRegister(MFRC522::VersionReg);
  if (version == 0x00 || version == 0xFF) {
    rfid.PCD_Init();
    delay(100);
    return;
  }

  // Chờ thẻ quẹt
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial())
    return;

  // Hiển thị trạng thái đang đọc
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Processing...");

  String cardUID = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    cardUID += String(rfid.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();
  Serial.println("\n[RFID] Tag: " + cardUID);

  // Mã hóa UID
  String encryptedUID = encrypt(cardUID);

  // Gửi trực tiếp lên Server qua HTTP
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClient client;
    HTTPClient http;
    http.begin(client, serverUrl); // Truyền client vào đây
    http.addHeader("Content-Type", "application/json");

    String jsonPayload = "{\"reader\":\"" + String(readerId) +
                         "\", \"tag\":\"" + encryptedUID + "\"}";

    int httpCode = http.POST(jsonPayload);

    if (httpCode > 0) {
      Serial.printf("[HTTP] Response: %d\n", httpCode);
      String payload = http.getString();
      Serial.println(payload);

      // Hỗ trợ cả ArduinoJson v6 và v7
      #if ARDUINOJSON_VERSION_MAJOR >= 7
        JsonDocument doc;
      #else
        DynamicJsonDocument doc(1024);
      #endif

      DeserializationError error = deserializeJson(doc, payload);

      if (!error) {
        bool apiStatus = doc["status"] | false;
        
        lcd.clear();
        if (apiStatus) {
          String statusType = doc["result"]["status"] | "";
          if (statusType == "SUCCESS") {
            String studentName = doc["result"]["studentName"] | "HOC SINH";
            Serial.println("[OK] Diem danh thanh cong: " + studentName);
            
            lcd.setCursor(0, 0);
            lcd.print("DIEM DANH OK!");
            lcd.setCursor(0, 1);
            lcd.print(studentName);
          } 
          else if (statusType == "BINDING_MODE") {
            String tagUid = doc["result"]["tag"] | "";
            Serial.println("[BINDING] Phat hien the moi: " + tagUid);
            
            lcd.setCursor(0, 0);
            lcd.print("CHE DO GAN THE");
            lcd.setCursor(0, 1);
            lcd.print(tagUid);
          }
          else if (statusType == "BINDING_MODE_REGISTERED") {
            Serial.println("[BINDING] The da dang ky.");
            
            lcd.setCursor(0, 0);
            lcd.print("THE DA DANG KY");
            lcd.setCursor(0, 1);
            lcd.print("Binding mode");
          }
        } 
        else {
          String errorStatus = doc["error"]["status"] | "";
          String message = doc["message"] | "Loi!";
          
          if (errorStatus == "UNREGISTERED") {
            Serial.println("[FAIL] The chua dang ky!");
            lcd.setCursor(0, 0);
            lcd.print("THE CHUA DANG KY");
            lcd.setCursor(0, 1);
            lcd.print("Vui long gan the");
          } 
          else if (errorStatus == "NO_SESSION") {
            Serial.println("[FAIL] Phien chua mo!");
            lcd.setCursor(0, 0);
            lcd.print("PHIEN CHUA MO");
            lcd.setCursor(0, 1);
            lcd.print("Vui long mo phien");
          }
          else {
            Serial.println("[FAIL] " + message);
            lcd.setCursor(0, 0);
            lcd.print("DIEM DANH LOI!");
            lcd.setCursor(0, 1);
            lcd.print(message.substring(0, 16));
          }
        }
      } 
      else {
        Serial.print(F("deserializeJson() failed: "));
        Serial.println(error.f_str());
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("JSON Parse Error");
      }
    } else {
      Serial.printf("[HTTP] Failed, error: %s\n",
                    http.errorToString(httpCode).c_str());
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Connection Error");
      lcd.setCursor(0, 1);
      lcd.print(http.errorToString(httpCode).substring(0, 16));
    }
    http.end();
  } else {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Disconnected");
  }

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  delay(3000); // Đợi 3 giây để người dùng đọc thông tin hiển thị
  
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("READY TO SWIPE");
}

String encrypt(String plainText) {
  int inputLength = plainText.length();
  int cipherLength = aesLib.get_cipher64_length(inputLength);
  char encrypted[cipherLength];
  byte iv[16] = {0};
  aesLib.encrypt64((byte *)plainText.c_str(), inputLength, encrypted, aesKey,
                   256, iv);
  return String(encrypted);
}