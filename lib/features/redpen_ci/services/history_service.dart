import 'package:shared_preferences/shared_preferences.dart';
import '../models/execution_record.dart';

class HistoryService {
  static const _keyHistory = 'executionHistory';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<ExecutionRecord> getHistory() {
    final jsonStr = _prefs.getString(_keyHistory);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return ExecutionRecord.decodeList(jsonStr);
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecord(ExecutionRecord record) async {
    final records = getHistory();
    records.insert(0, record);
    // Keep only last 100 records
    if (records.length > 100) {
      records.removeRange(100, records.length);
    }
    await _prefs.setString(_keyHistory, ExecutionRecord.encodeList(records));
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyHistory);
  }
}
