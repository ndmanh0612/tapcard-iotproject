#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <AESLib.h>
#include <Base64.h>

#define SS_PIN 5
#define RST_PIN 22

// CẤU HÌNH BẢO MẬT (Giữ nguyên của bạn)
const char* SECRET_KEY_BASE64 = "Rw4ct/4Yf/XdyEnKdQI/pAS5hD0y/Sjj5jU/8p+3oFI=";

// CẤU HÌNH KẾT NỐI (Thay bằng WiFi của bạn)
const char* ssid = "Hello123";
const char* password = "86868686";

// CẤU HÌNH SERVER (Quan trọng: Cập nhật IP máy tính bạn)
const char* serverUrl = "https://448b1884fc7ca9e6-171-241-78-48.serveousercontent.com/attendance/swipe";
const char* readerId = "69ff24d6d49100db02e88893"; 

MFRC522 rfid(SS_PIN, RST_PIN);
AESLib aesLib;
byte aesKey[32];

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

  WiFi.begin(ssid, password);
  Serial.print("[WiFi] Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n[WiFi] Connected!");
  Serial.print("[WiFi] IP: "); Serial.println(WiFi.localIP());
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
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;

  String cardUID = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    cardUID += String(rfid.uid.uidByte[i], HEX);
  }
  cardUID.toUpperCase();
  Serial.println("\n[RFID] Tag: " + cardUID);

  // Mã hóa UID
  String encryptedUID = encrypt(cardUID);

  // Gửi trực tiếp lên Server
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure(); // Bỏ qua kiểm tra chứng chỉ
    
    HTTPClient http;
    http.begin(client, serverUrl); // Truyền client vào đây
    http.addHeader("Content-Type", "application/json");

    String jsonPayload = "{\"reader\":\"" + String(readerId) + "\", \"tag\":\"" + encryptedUID + "\"}";
    
    int httpCode = http.POST(jsonPayload);
    
    if (httpCode > 0) {
      Serial.printf("[HTTP] Response: %d\n", httpCode);
      if (httpCode == 200) Serial.println("[OK] Diem danh thanh cong!");
      else if (httpCode == 403) Serial.println("[FAIL] Phien diem danh chua mo!");
    } else {
      Serial.printf("[HTTP] Failed, error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  }

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  delay(1000); // Tránh quẹt lặp liên tục
}

String encrypt(String plainText) {
  int inputLength = plainText.length();
  int cipherLength = aesLib.get_cipher64_length(inputLength);
  char encrypted[cipherLength];
  byte iv[16] = { 0 };
  aesLib.encrypt64((byte*)plainText.c_str(), inputLength, encrypted, aesKey, 256, iv);
  return String(encrypted);
}
