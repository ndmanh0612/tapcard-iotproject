import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taptag/core/constants.dart';

class ReaderModel {
  final String? id;
  final String name;
  final bool isActive;
  final String? description;
  final String ssid;
  final String? password;

  ReaderModel({
    this.id,
    this.name = "Unknown",
    this.isActive = true,
    this.description,
    required this.ssid,
    this.password,
  });

  factory ReaderModel.fromJson(Map<String, dynamic> json) {
    return ReaderModel(
      id: json['_id'],
      name: json['name'],
      isActive: json['isActive'],
      description: json['description'],
      ssid: json['ssid'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'isActive': isActive,
    'description': description,
    'ssid': ssid,
    'password': password,
  };
}

class ReaderProvider with ChangeNotifier {
  ReaderModel? _connectedReader;
  List<ReaderModel> _allReaders = [];

  ReaderModel? get connectedReader => _connectedReader;
  List<ReaderModel> get allReaders => _allReaders;

  /// Fetch a single reader by SSID
  Future<void> fetchReaderBySSID(String ssid, String token) async {
    final url = Uri.parse("${AppConstants.baseUrl}/reader?ssid=$ssid");
    final response = await http.get(url, headers: {'Authorization': token});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'][0];
      _connectedReader = ReaderModel.fromJson(result);
      notifyListeners();
    } else {
      throw Exception("Failed to fetch reader by SSID: ${response.body}");
    }
  }

  Future<void> fetchAllReaders(String token) async {
    final url = Uri.parse("${AppConstants.baseUrl}/reader");
    final response = await http.get(url, headers: {'Authorization': token});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _allReaders = (data['result'] as List).map((reader) => ReaderModel.fromJson(reader)).toList();
      notifyListeners();
    } else {
      throw Exception("Failed to fetch all readers: ${response.body}");
    }
  }

  Future<void> toggleBindingMode(String readerId, bool enable, String token) async {
    final url = Uri.parse("${AppConstants.baseUrl}/reader/toggle-binding");
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'id': readerId,
        'enable': enable,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to toggle binding mode: ${response.body}");
    }
    notifyListeners();
  }

  void clearReader() {
    _connectedReader = null;
    notifyListeners();
  }

  void clearAllReaders() {
    _allReaders.clear();
    notifyListeners();
  }
}
