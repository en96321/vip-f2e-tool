import 'dart:convert';
import 'dart:io';

import '../models/team_member.dart';
import '../models/worklog_entry.dart';
import '../models/worklog_result.dart';

/// Jira API 服務
/// 負責呼叫 Jira REST API 新增工時記錄
class JiraService {
  // static const String _jiraDomain = 'https://104corp.atlassian.net'; // Removed hardcoded domain

  /// 為單一成員新增工時記錄
  Future<WorklogResult> addWorklog(String domain, TeamMember member, WorklogEntry entry) async {
    try {
      // 建立 Basic Auth token
      final credentials = base64Encode(utf8.encode('${member.email}:${member.token}'));

      // 建立請求內容
      final payload = {
        'timeSpentSeconds': entry.timeSpentSeconds,
        'started': entry.getFormattedStarted(),
        'comment': {
          'type': 'doc',
          'version': 1,
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {
                  'type': 'text',
                  'text': entry.comment.isNotEmpty ? entry.comment : '工時記錄',
                }
              ]
            }
          ]
        }
      };

      // 發送 HTTP 請求
      final client = HttpClient();
      final uri = Uri.parse('$domain/rest/api/3/issue/${entry.issueKey}/worklog');
      final request = await client.postUrl(uri);

      // 設定 Headers
      request.headers.set('Authorization', 'Basic $credentials');
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Accept', 'application/json');

      // 寫入請求內容 (使用 UTF-8 編碼)
      request.add(utf8.encode(jsonEncode(payload)));

      // 發送請求並取得回應
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      // 檢查結果
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return WorklogResult.success(member);
      } else {
        return WorklogResult.failure(
          member,
          'HTTP ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      return WorklogResult.failure(member, '錯誤：${e.toString()}');
    }
  }

  /// 批次為多位成員新增工時記錄
  Future<List<WorklogResult>> addWorklogBatch(
    String domain,
    List<TeamMember> members,
    WorklogEntry entry, {
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <WorklogResult>[];

    for (var i = 0; i < members.length; i++) {
      final member = members[i];
      onProgress?.call(i + 1, members.length);

      final result = await addWorklog(domain, member, entry);
      results.add(result);

      // 加入小延遲避免 API 限流
      if (i < members.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }
}
