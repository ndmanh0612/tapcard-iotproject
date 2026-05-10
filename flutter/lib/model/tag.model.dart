import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taptag/core/constants.dart';

class TagModel {
  final String? id;
  final String tag;
  final String associated;
  final String? status;
  final String? by;

  TagModel({
    this.id,
    required this.tag,
    required this.associated,
    this.status,
    this.by,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['_id'],
      tag: json['tag'],
      associated: json['associated'],
      status: json['status'],
      by: json['by'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'associated': associated,
  };
}

class TagProvider with ChangeNotifier {
  List<TagModel> _tags = [];

  List<TagModel> get tags => _tags;

  Future<void> fetchAllTags(String token) async {
    final url = Uri.parse("${AppConstants.baseUrl}/tag");
    final response = await http.get(url, headers: {'Authorization': token});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _tags = (data['result'] as List).map((t) => TagModel.fromJson(t)).toList();
      notifyListeners();
    } else {
      throw Exception("Failed to fetch tags: ${response.body}");
    }
  }

  Future<void> bindTag({
    required String token,
    required String tag,
    required String userId,
  }) async {
    final url = Uri.parse("${AppConstants.baseUrl}/tag");
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'tag': tag,
        'associated': userId,
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ Tag bound successfully");
      await fetchAllTags(token);
    } else {
      throw Exception("Failed to bind tag: ${response.body}");
    }
  }

  Future<void> deleteTag(String token, String tagUid) async {
    final url = Uri.parse("${AppConstants.baseUrl}/tag?tag=$tagUid");
    final response = await http.delete(url, headers: {'Authorization': token});

    if (response.statusCode == 200) {
      debugPrint("✅ Tag deleted successfully");
      await fetchAllTags(token);
    } else {
      throw Exception("Failed to delete tag: ${response.body}");
    }
  }
}
