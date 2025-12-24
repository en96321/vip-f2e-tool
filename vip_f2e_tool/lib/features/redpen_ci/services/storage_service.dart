import 'package:shared_preferences/shared_preferences.dart';
import '../models/repo_config.dart';

class StorageService {
  static const _keyRepos = 'repos';
  static const _keyTargetUrl = 'targetUrl';
  static const _keyToken = 'token';
  static const _keyMail = 'mail';
  static const _keySastFilter = 'sastFilter';
  static const _keyCommitCount = 'commitCount';

  static const defaultTargetUrl = 'https://your-redpen-server.com/ci.sh';
  static const defaultSastFilter =
      '!**/codebuild/**,!**/plugins/**,!**/tests/**,!**/mock/**,!**/gulp/**,!yarn.lock';
  static const defaultCommitCount = 5;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Repos list
  List<RepoConfig> get repos {
    final jsonStr = _prefs.getString(_keyRepos);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return RepoConfig.decodeList(jsonStr);
    } catch (e) {
      return [];
    }
  }

  set repos(List<RepoConfig> value) =>
      _prefs.setString(_keyRepos, RepoConfig.encodeList(value));

  void addRepo(RepoConfig repo) {
    final list = repos;
    if (!list.contains(repo)) {
      list.add(repo);
      repos = list;
    }
  }

  void removeRepo(RepoConfig repo) {
    final list = repos;
    list.remove(repo);
    repos = list;
  }

  // Commit count to fetch
  int get commitCount => _prefs.getInt(_keyCommitCount) ?? defaultCommitCount;
  set commitCount(int value) => _prefs.setInt(_keyCommitCount, value);

  // Target URL
  String get targetUrl => _prefs.getString(_keyTargetUrl) ?? defaultTargetUrl;
  set targetUrl(String value) => _prefs.setString(_keyTargetUrl, value);

  // Token
  String get token => _prefs.getString(_keyToken) ?? '';
  set token(String value) => _prefs.setString(_keyToken, value);

  // Mail
  String get mail => _prefs.getString(_keyMail) ?? '';
  set mail(String value) => _prefs.setString(_keyMail, value);

  // SAST Filter
  String get sastFilter => _prefs.getString(_keySastFilter) ?? defaultSastFilter;
  set sastFilter(String value) => _prefs.setString(_keySastFilter, value);
}
