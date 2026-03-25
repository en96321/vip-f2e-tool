import 'dart:convert';
import 'package:flutter/material.dart';

/// 工時記錄預設樣板
class WorklogTemplate {
  final String id;
  final String name;
  final String issueKey;
  final int minutes;
  final String comment;
  final TimeOfDay defaultTime;
  final List<String> selectedMemberIds;

  WorklogTemplate({
    required this.id,
    required this.name,
    this.issueKey = '',
    this.minutes = 60,
    this.comment = '',
    TimeOfDay? defaultTime,
    this.selectedMemberIds = const [],
  }) : defaultTime = defaultTime ?? const TimeOfDay(hour: 9, minute: 0);

  /// 從 JSON 建立
  factory WorklogTemplate.fromJson(Map<String, dynamic> json) {
    return WorklogTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      issueKey: json['issueKey'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 60,
      comment: json['comment'] as String? ?? '',
      defaultTime: TimeOfDay(
        hour: json['defaultTimeHour'] as int? ?? 9,
        minute: json['defaultTimeMinute'] as int? ?? 0,
      ),
      selectedMemberIds: (json['selectedMemberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issueKey': issueKey,
      'minutes': minutes,
      'comment': comment,
      'defaultTimeHour': defaultTime.hour,
      'defaultTimeMinute': defaultTime.minute,
      'selectedMemberIds': selectedMemberIds,
    };
  }

  /// 建立副本並修改部分欄位
  WorklogTemplate copyWith({
    String? id,
    String? name,
    String? issueKey,
    int? minutes,
    String? comment,
    TimeOfDay? defaultTime,
    List<String>? selectedMemberIds,
  }) {
    return WorklogTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      issueKey: issueKey ?? this.issueKey,
      minutes: minutes ?? this.minutes,
      comment: comment ?? this.comment,
      defaultTime: defaultTime ?? this.defaultTime,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
    );
  }

  /// 從 JSON 字串解碼樣板清單
  static List<WorklogTemplate> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => WorklogTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 將樣板清單編碼為 JSON 字串
  static String encodeList(List<WorklogTemplate> templates) {
    return jsonEncode(templates.map((e) => e.toJson()).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorklogTemplate && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
