class CommitInfo {
  final String sha;
  final String shortSha;
  final String message;
  final String author;
  final DateTime date;

  CommitInfo({
    required this.sha,
    required this.message,
    required this.author,
    required this.date,
  }) : shortSha = sha.length > 7 ? sha.substring(0, 7) : sha;

  /// Parse from git log output line
  /// Format: sha|author|date|message
  factory CommitInfo.fromGitLogLine(String line) {
    final parts = line.split('|');
    if (parts.length < 4) {
      throw FormatException('Invalid git log format');
    }
    return CommitInfo(
      sha: parts[0],
      author: parts[1],
      date: DateTime.tryParse(parts[2]) ?? DateTime.now(),
      message: parts.sublist(3).join('|'), // message might contain |
    );
  }

  /// First line of commit message
  String get shortMessage {
    final firstLine = message.split('\n').first;
    return firstLine.length > 60 ? '${firstLine.substring(0, 57)}...' : firstLine;
  }
}
