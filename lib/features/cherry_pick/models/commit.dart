/// Represents a single Git commit
class Commit {
  final String hash;
  final int timestamp;
  final String message;
  CherryPickStatus status;

  Commit({
    required this.hash,
    required this.timestamp,
    required this.message,
    this.status = CherryPickStatus.pending,
  });

  /// Parse a commit from git log output format: "hash timestamp message"
  factory Commit.fromGitLog(String line) {
    final parts = line.split(' ');
    if (parts.length < 3) {
      throw FormatException('Invalid commit line format: $line');
    }
    final hash = parts[0];
    final timestamp = int.parse(parts[1]);
    final message = parts.sublist(2).join(' ');
    return Commit(hash: hash, timestamp: timestamp, message: message);
  }

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'timestamp': timestamp,
        'message': message,
        'status': status.name,
      };

  factory Commit.fromJson(Map<String, dynamic> json) => Commit(
        hash: json['hash'] as String,
        timestamp: json['timestamp'] as int,
        message: json['message'] as String,
        status: CherryPickStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CherryPickStatus.pending,
        ),
      );

  String get shortHash => hash.length > 7 ? hash.substring(0, 7) : hash;

  @override
  String toString() => '$shortHash: $message';
}

/// Status of a cherry-pick operation for a commit
enum CherryPickStatus {
  pending,
  applying,
  applied,
  skipped,
  conflict,
  error,
}

extension CherryPickStatusX on CherryPickStatus {
  String get displayName {
    switch (this) {
      case CherryPickStatus.pending:
        return '待處理';
      case CherryPickStatus.applying:
        return '處理中';
      case CherryPickStatus.applied:
        return '已套用';
      case CherryPickStatus.skipped:
        return '已跳過';
      case CherryPickStatus.conflict:
        return '衝突';
      case CherryPickStatus.error:
        return '錯誤';
    }
  }

  bool get isCompleted =>
      this == CherryPickStatus.applied ||
      this == CherryPickStatus.skipped ||
      this == CherryPickStatus.error;
}
