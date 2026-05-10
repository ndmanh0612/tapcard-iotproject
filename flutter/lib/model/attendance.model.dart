import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:taptag/model/reader.model.dart';
import 'package:taptag/model/user.model.dart';
import 'package:taptag/core/constants.dart';

class AttendanceResult {
  final String id;
  final String date;
  final bool isOut;
  final int timeIn;
  final int timeOut;
  final String reason;
  final ReaderModel reader;
  final List<UserModel> students;

  AttendanceResult({
    required this.id,
    required this.date,
    required this.isOut,
    required this.timeIn,
    required this.timeOut,
    required this.reason,
    required this.reader,
    required this.students,
  });

  factory AttendanceResult.fromJson(Map<String, dynamic> json) {
    return AttendanceResult(
      id: json['_id'],
      date: json['date'],
      isOut: json['isOut'],
      timeIn: json['timeIn'] ?? 0,
      timeOut: json['timeOut'] ?? 0,
      reason: json['reason'] ?? '',
      reader: ReaderModel.fromJson(json['reader']),
      students: List<UserModel>.from((json['students'] as List).map((s) => UserModel.fromJson(s))),
    );
  }
}

class AttendanceProvider with ChangeNotifier {
  List<AttendanceResult> _attendanceResults = [];
  String? _currentSessionId;

  List<AttendanceResult> get attendanceResults => _attendanceResults;
  String? get currentSessionId => _currentSessionId;

  Future<void> submitAttendance({
    required String token,
    required String reader,
    required List<String> students,
    required String reason,
    required bool isOut,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/attendance'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'reader': reader, 'students': students, 'reason': reason, 'isOut': isOut}),
      );

      if (res.statusCode != 200) {
        debugPrint("⚠️ Server error: ${res.body}");
        throw Exception("Failed to submit attendance: ${res.body}");
      } else {
        await fetchAllAttendance(token);
      }
    } catch (e) {
      debugPrint("🔥 Attendance post error: $e");
      throw Exception("Failed to submit attendance: $e");
    }
  }

  Future<String> startSession({
    required String token,
    required String reader,
    required String reason,
    required bool isOut,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/attendance/start'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'reader': reader, 'reason': reason, 'isOut': isOut}),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _currentSessionId = data['result']['_id'];
        notifyListeners();
        return _currentSessionId!;
      } else {
        throw Exception("Không thể bắt đầu phiên: ${res.body}");
      }
    } catch (e) {
      throw Exception("Failed to start session: $e");
    }
  }

  Future<void> endSession({
    required String token,
    required String sessionId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/attendance/end'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'id': sessionId}),
      );

      if (res.statusCode == 200) {
        _currentSessionId = null;
        notifyListeners();
      } else {
        throw Exception("Không thể kết thúc phiên: ${res.body}");
      }
    } catch (e) {
      throw Exception("Failed to end session: $e");
    }
  }

  Future<void> fetchAllAttendance(String token) async {
    try {
      final res = await http.get(Uri.parse('${AppConstants.baseUrl}/attendance'), headers: {'Authorization': token});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['result'];
        _attendanceResults = List<AttendanceResult>.from(data.map((json) => AttendanceResult.fromJson(json)));
        _attendanceResults.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      } else {
        debugPrint("⚠️ Server error: ${res.body}");
        throw Exception("Failed to fetch attendance");
      }
    } catch (e) {
      debugPrint("🔥 Attendance fetch error: $e");
      throw Exception("Failed to fetch attendance: $e");
    }
  }
}
