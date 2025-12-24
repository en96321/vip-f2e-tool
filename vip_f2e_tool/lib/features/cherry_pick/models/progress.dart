import 'commit.dart';

/// Represents the progress state of a cherry-pick operation
class CherryPickProgress {
  final List<String> tickets;
  final String environment;
  final String baseBranch;
  final String sourceBranch;
  final String targetBranch;
  final List<Commit> allCommits;
  final int currentIndex;
  final DateTime timestamp;
  final String? workingDirectory;

  CherryPickProgress({
    required this.tickets,
    required this.environment,
    required this.baseBranch,
    required this.sourceBranch,
    required this.targetBranch,
    required this.allCommits,
    required this.currentIndex,
    DateTime? timestamp,
    this.workingDirectory,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'tickets': tickets,
        'environment': environment,
        'baseBranch': baseBranch,
        'sourceBranch': sourceBranch,
        'targetBranch': targetBranch,
        'allCommits': allCommits.map((c) => c.toJson()).toList(),
        'currentIndex': currentIndex,
        'timestamp': timestamp.toIso8601String(),
        'workingDirectory': workingDirectory,
      };

  factory CherryPickProgress.fromJson(Map<String, dynamic> json) =>
      CherryPickProgress(
        tickets: List<String>.from(json['tickets']),
        environment: json['environment'] as String,
        baseBranch: json['baseBranch'] as String,
        sourceBranch: json['sourceBranch'] as String,
        targetBranch: json['targetBranch'] as String,
        allCommits: (json['allCommits'] as List)
            .map((c) => Commit.fromJson(c as Map<String, dynamic>))
            .toList(),
        currentIndex: json['currentIndex'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        workingDirectory: json['workingDirectory'] as String?,
      );

  CherryPickProgress copyWith({
    List<String>? tickets,
    String? environment,
    String? baseBranch,
    String? sourceBranch,
    String? targetBranch,
    List<Commit>? allCommits,
    int? currentIndex,
    DateTime? timestamp,
    String? workingDirectory,
  }) =>
      CherryPickProgress(
        tickets: tickets ?? this.tickets,
        environment: environment ?? this.environment,
        baseBranch: baseBranch ?? this.baseBranch,
        sourceBranch: sourceBranch ?? this.sourceBranch,
        targetBranch: targetBranch ?? this.targetBranch,
        allCommits: allCommits ?? this.allCommits,
        currentIndex: currentIndex ?? this.currentIndex,
        timestamp: timestamp ?? this.timestamp,
        workingDirectory: workingDirectory ?? this.workingDirectory,
      );

  int get totalCommits => allCommits.length;
  int get appliedCount =>
      allCommits.where((c) => c.status == CherryPickStatus.applied).length;
  int get skippedCount =>
      allCommits.where((c) => c.status == CherryPickStatus.skipped).length;
  bool get isComplete => currentIndex >= allCommits.length;
  double get progressPercent =>
      totalCommits > 0 ? currentIndex / totalCommits : 0.0;
}
