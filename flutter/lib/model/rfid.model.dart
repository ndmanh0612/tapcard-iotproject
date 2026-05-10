import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taptag/model/user.model.dart';
import 'package:taptag/core/constants.dart';

class RFIDProvider with ChangeNotifier {
  List<WiFiAccessPoint> rfidNetworks = [];
  WebSocketChannel? _channel;
  IO.Socket? _socket; // Thêm Socket.io
  List<String> offlineBuffer = [];
  List<UserModel> scannedStudents = []; // Chuyển từ rfid sang student object
  String? lastDetectedTag; // Lưu mã thẻ vừa quẹt nhưng chưa gán
  bool isListening = false;

  bool isScanning = false;
  bool isConnected = false;
  String? currentSSID;

  Future<void> scanRFIDNetworks() async {
    final locPermission = await Permission.location.request();
    if (!locPermission.isGranted) throw Exception("Location permission required.");

    isScanning = true;
    notifyListeners();

    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) throw Exception("Cannot scan: $canScan");

    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();
    rfidNetworks = results.where((ap) => ap.ssid.startsWith("RFID-")).toList();

    isScanning = false;
    notifyListeners();
  }

  Future<String> fetchPasswordForSSID(String ssid, String token) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/reader?ssid=$ssid'), headers: {'Authorization': token});
    print("Reader Response: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("🔑 Password for $ssid: ${data['result'][0]['password']}");
      return data['result'][0]['password'];
    } else {
      throw Exception("Failed to fetch reader info");
    }
  }

  Future<void> connectToRFID(String ssid, String password) async {
    print("🔗 Connecting to $ssid with password: $password");
    final success = await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      security: NetworkSecurity.WPA,
      joinOnce: true,
      withInternet: false,
    );
    print("Connection success: $success");

    if (!success) throw Exception("Failed to connect to $ssid");

    currentSSID = ssid;
    isConnected = true;
    notifyListeners();

    await connectToWebSocket();
  }

  Future<void> connectToWebSocket() async {
    // 1. Kết nối Socket.io tới SERVER (để nhận update real-time từ server)
    try {
      _socket = IO.io(AppConstants.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('✅ Connected to Server Socket.io');
        isListening = true;
        notifyListeners();
      });

      _socket!.on("new-attendance", (data) {
        debugPrint("📨 Real-time Attendance from Server: $data");
        if (data['student'] != null) {
          UserModel student = UserModel.fromJson(data['student']);
          bool exists = scannedStudents.any((s) => s.mobileNo == student.mobileNo);
          if (!exists) {
            scannedStudents.add(student);
            notifyListeners();
          }
        }
      });

      _socket!.on("tag-detected", (data) {
        debugPrint("🆕 New Unregistered Tag Detected: ${data['tag']}");
        lastDetectedTag = data['tag'];
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 Disconnected from Server Socket.io');
        isListening = false;
        notifyListeners();
      });

    } catch (e) {
      debugPrint("💥 Socket.io Error: $e");
    }

    // 2. (Tùy chọn) Vẫn giữ kết nối trực tiếp tới ESP32 nếu cần (đã có ở code cũ)
    // Hiện tại bạn muốn lấy từ Server nên phần này có thể để trống hoặc xóa.
  }

  Future<void> cacheLocally(String data) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cached = prefs.getStringList('rfid_cache') ?? [];
    cached.add(data);
    await prefs.setStringList('rfid_cache', cached);
  }

  Future<void> syncDataToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cached = prefs.getStringList('rfid_cache') ?? [];

    for (var item in cached) {
      await http.post(
        Uri.parse("${AppConstants.baseUrl}/sync-rfid"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': item}),
      );
    }

    offlineBuffer.clear();
    await prefs.remove('rfid_cache');
    notifyListeners();
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
    _socket?.disconnect(); // Ngắt socket.io
    _socket = null;
    isListening = false;
    notifyListeners();
  }
}
