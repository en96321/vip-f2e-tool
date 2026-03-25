import 'dart:convert';

/// 團隊成員資料模型
class TeamMember {
  final String id;
  final String name;
  final String email;
  final String token;
  bool isEnabled;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    this.isEnabled = true,
  });

  /// 從 JSON 建立
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'isEnabled': isEnabled,
    };
  }

  /// 建立副本並修改部分欄位
  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    bool? isEnabled,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// 從 JSON 字串解碼成員清單
  static List<TeamMember> decodeList(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => TeamMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 將成員清單編碼為 JSON 字串
  static String encodeList(List<TeamMember> members) {
    return jsonEncode(members.map((e) => e.toJson()).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
