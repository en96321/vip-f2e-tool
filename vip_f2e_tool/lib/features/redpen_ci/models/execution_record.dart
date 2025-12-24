import 'dart:convert';

class ExecutionRecord {
  final String repo;
  final String commitHash;
  final DateTime timestamp;
  final String response;
  final bool success;

  ExecutionRecord({
    required this.repo,
    required this.commitHash,
    required this.timestamp,
    required this.response,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
        'repo': repo,
        'commitHash': commitHash,
        'timestamp': timestamp.toIso8601String(),
        'response': response,
        'success': success,
      };

  factory ExecutionRecord.fromJson(Map<String, dynamic> json) =>
      ExecutionRecord(
        repo: json['repo'] as String,
        commitHash: json['commitHash'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        response: json['response'] as String,
        success: json['success'] as bool,
      );

  static String encodeList(List<ExecutionRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<ExecutionRecord> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => ExecutionRecord.fromJson(e)).toList();
  }
}
