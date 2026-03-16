import 'package:flutter/foundation.dart';
import 'dart:convert';

class ItemComposition {
  final String? contentId; // content table id
  final String? strengthId; // strength table id
  final String? contentName; // Joined from API
  final String? strengthName; // Joined from API

  ItemComposition({
    this.contentId,
    this.strengthId,
    this.contentName,
    this.strengthName,
  });

  ItemComposition copyWith({
    String? contentId,
    String? strengthId,
    String? contentName,
    String? strengthName,
  }) {
    return ItemComposition(
      contentId: contentId ?? this.contentId,
      strengthId: strengthId ?? this.strengthId,
      contentName: contentName ?? this.contentName,
      strengthName: strengthName ?? this.strengthName,
    );
  }

  factory ItemComposition.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('[ItemComposition.fromJson] raw: ${jsonEncode(json)}');
    }

    // Handle Supabase join structure (can be Map or List of Map)
    String? cName;
    String? cId = json['content_id']?.toString();

    final contentJson = json['content'];
    if (contentJson != null) {
      if (contentJson is Map) {
        cName = contentJson['content_name'] ?? contentJson['item_content'];
        cId ??= contentJson['id']?.toString();
      } else if (contentJson is List && contentJson.isNotEmpty) {
        final first = contentJson.first;
        if (first is Map) {
          cName = first['content_name'] ?? first['item_content'];
          cId ??= first['id']?.toString();
        }
      }
    }

    String? sName;
    String? sId = json['strength_id']?.toString();

    final strengthJson = json['strength'];
    if (strengthJson != null) {
      if (strengthJson is Map) {
        sName = strengthJson['strength_name'] ?? strengthJson['item_strength'];
        sId ??= strengthJson['id']?.toString();
      } else if (strengthJson is List && strengthJson.isNotEmpty) {
        final first = strengthJson.first;
        if (first is Map) {
          sName = first['strength_name'] ?? first['item_strength'];
          sId ??= first['id']?.toString();
        }
      }
    }

    // Secondary fallback for flat keys
    cName ??=
        json['content_name']?.toString() ?? json['contentName']?.toString();
    sName ??=
        json['strength_name']?.toString() ?? json['strengthName']?.toString();
    cId ??= json['content_id']?.toString() ?? json['contentId']?.toString();
    sId ??= json['strength_id']?.toString() ?? json['strengthId']?.toString();

    return ItemComposition(
      contentId: cId,
      strengthId: sId,
      contentName: cName,
      strengthName: sName,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    if (contentId != null) data['content_id'] = contentId;
    if (strengthId != null) data['strength_id'] = strengthId;

    return data;
  }
}
