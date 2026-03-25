import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_member.dart';
import '../models/worklog_template.dart';

/// 工時記錄儲存服務
/// 使用 SharedPreferences 儲存成員清單和樣板設定
class WorklogStorageService {
  static const _keyMembers = 'worklog_members';
  static const _keyTemplates = 'worklog_templates';
  static const _keyJiraDomain = 'worklog_jira_domain';

  late SharedPreferences _prefs;

  /// 初始化 SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 成員管理 ====================

  /// 取得所有成員
  List<TeamMember> get members {
    final jsonStr = _prefs.getString(_keyMembers);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return TeamMember.decodeList(jsonStr);
    } catch (e) {
      return [];
    }
  }

  /// 設定成員清單
  set members(List<TeamMember> value) =>
      _prefs.setString(_keyMembers, TeamMember.encodeList(value));

  /// 新增成員
  void addMember(TeamMember member) {
    final list = members;
    list.add(member);
    members = list;
  }

  /// 更新成員
  void updateMember(TeamMember member) {
    final list = members;
    final index = list.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      list[index] = member;
      members = list;
    }
  }

  /// 刪除成員
  void removeMember(String id) {
    final list = members;
    list.removeWhere((m) => m.id == id);
    members = list;
  }

  /// 根據 ID 取得成員
  TeamMember? getMemberById(String id) {
    try {
      return members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==================== 樣板管理 ====================

  /// 取得所有樣板
  List<WorklogTemplate> get templates {
    final jsonStr = _prefs.getString(_keyTemplates);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return WorklogTemplate.decodeList(jsonStr);
    } catch (e) {
      return [];
    }
  }

  /// 設定樣板清單
  set templates(List<WorklogTemplate> value) =>
      _prefs.setString(_keyTemplates, WorklogTemplate.encodeList(value));

  /// 新增樣板
  void addTemplate(WorklogTemplate template) {
    final list = templates;
    list.add(template);
    templates = list;
  }

  /// 更新樣板
  void updateTemplate(WorklogTemplate template) {
    final list = templates;
    final index = list.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      list[index] = template;
      templates = list;
    }
  }

  /// 刪除樣板
  void removeTemplate(String id) {
    final list = templates;
    list.removeWhere((t) => t.id == id);
    templates = list;
  }

  /// 根據 ID 取得樣板
  WorklogTemplate? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==================== 系統設定 ====================

  /// 取得 Jira Domain
  String get jiraDomain => _prefs.getString(_keyJiraDomain) ?? '';

  /// 設定 Jira Domain
  set jiraDomain(String value) => _prefs.setString(_keyJiraDomain, value);
}
