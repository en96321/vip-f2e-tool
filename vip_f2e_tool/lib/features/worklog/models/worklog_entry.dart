/// 工時記錄輸入資料
class WorklogEntry {
  final DateTime date;
  final String issueKey;
  final int minutes;
  final String comment;

  WorklogEntry({
    required this.date,
    required this.issueKey,
    required this.minutes,
    this.comment = '',
  });

  /// 計算以秒為單位的時間（Jira API 需要）
  int get timeSpentSeconds => minutes * 60;

  /// 格式化日期為 Jira API 格式
  /// 格式: 2025-07-31T09:00:00.000+0800
  String getFormattedStarted() {
    final offset = date.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final mins = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    
    return '${date.toIso8601String().split('.')[0]}.000$sign$hours$mins';
  }
}
