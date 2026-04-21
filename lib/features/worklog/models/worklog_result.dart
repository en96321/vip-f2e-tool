import 'team_member.dart';

/// 工時記錄執行結果
class WorklogResult {
  final TeamMember member;
  final bool success;
  final String message;
  final String? worklogId;

  WorklogResult({
    required this.member,
    required this.success,
    required this.message,
    this.worklogId,
  });

  /// 成功結果
  factory WorklogResult.success(TeamMember member, {String? worklogId}) {
    return WorklogResult(
      member: member,
      success: true,
      message: '成功',
      worklogId: worklogId,
    );
  }

  /// 失敗結果
  factory WorklogResult.failure(TeamMember member, String error) {
    return WorklogResult(
      member: member,
      success: false,
      message: error,
    );
  }
}
