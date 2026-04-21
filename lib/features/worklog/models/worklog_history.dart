import 'dart:convert';

/// 單筆工時紀錄歷史
class WorklogHistoryItem {
  final String memberId;
  final String memberName;
  final String worklogId;
  bool isUndone;

  WorklogHistoryItem({
    required this.memberId,
    required this.memberName,
    required this.worklogId,
    this.isUndone = false,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'worklogId': worklogId,
        'isUndone': isUndone,
      };

  factory WorklogHistoryItem.fromJson(Map<String, dynamic> json) =>
      WorklogHistoryItem(
        memberId: json['memberId'],
        memberName: json['memberName'],
        worklogId: json['worklogId'],
        isUndone: json['isUndone'] ?? false,
      );
}

/// 批次工時紀錄歷史
class WorklogHistory {
  final String id;
  final DateTime createdAt;
  final String issueKey;
  final int minutes;
  final String comment;
  final List<WorklogHistoryItem> items;

  WorklogHistory({
    required this.id,
    required this.createdAt,
    required this.issueKey,
    required this.minutes,
    required this.comment,
    required this.items,
  });

  bool get isAllUndone => items.isNotEmpty && items.every((item) => item.isUndone);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'issueKey': issueKey,
        'minutes': minutes,
        'comment': comment,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory WorklogHistory.fromJson(Map<String, dynamic> json) => WorklogHistory(
        id: json['id'],
        createdAt: DateTime.parse(json['createdAt']),
        issueKey: json['issueKey'],
        minutes: json['minutes'],
        comment: json['comment'] ?? '',
        items: (json['items'] as List)
            .map((e) => WorklogHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static String encodeList(List<WorklogHistory> list) =>
      json.encode(list.map((e) => e.toJson()).toList());

  static List<WorklogHistory> decodeList(String str) =>
      (json.decode(str) as List)
          .map((e) => WorklogHistory.fromJson(e as Map<String, dynamic>))
          .toList();
}
