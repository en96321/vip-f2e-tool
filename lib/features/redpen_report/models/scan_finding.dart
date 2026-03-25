/// Represents a single finding from a RedPen/Checkmarx scan report
class ScanFinding {
  final String query;
  final String queryPath;
  final String srcFileName;
  final String line;
  final String column;
  final String nodeId;
  final String name;
  final String destFileName;
  final String destLine;
  final String destColumn;
  final String destNodeId;
  final String destName;
  final String resultState;
  final String resultSeverity;
  String comment;
  final String link;
  final String resultStatus;
  final String detectionDate;
  // Remaining fields stored as a list
  final List<String> extraFields;

  ScanFinding({
    required this.query,
    required this.queryPath,
    required this.srcFileName,
    required this.line,
    required this.column,
    required this.nodeId,
    required this.name,
    required this.destFileName,
    required this.destLine,
    required this.destColumn,
    required this.destNodeId,
    required this.destName,
    required this.resultState,
    required this.resultSeverity,
    required this.comment,
    required this.link,
    required this.resultStatus,
    required this.detectionDate,
    required this.extraFields,
  });

  /// Key used to match findings across reports
  String get matchKey => '$query|$srcFileName|$name';

  /// All CSV headers
  static const List<String> headers = [
    'Query',
    'Query Path',
    'SrcFileName',
    'Line',
    'Column',
    'NodeID',
    'Name',
    'DestFileName',
    'DestLine',
    'DestColumn',
    'DestNodeId',
    'DestName',
    'Result State',
    'Result Severity',
    'Comment',
    'Link',
    'Result Status',
    'Detection Date',
    'Scanner',
    'Platform',
    'Category',
    'Expected Value',
    'Actual Value',
    'Issue Type',
    'Package',
    'Package Id',
    'Package Version',
    'Category Name',
    'CVE',
    'CWE',
    'Image',
    'Secret Type',
    'Check',
    'File/Artifact',
    'Location Line',
    'Commit SHA',
    'Validity',
    'Remediation',
  ];

  factory ScanFinding.fromRow(List<String> row) {
    // Pad row to ensure we have enough fields
    final padded = List<String>.from(row);
    while (padded.length < 18) {
      padded.add('');
    }

    return ScanFinding(
      query: padded[0],
      queryPath: padded[1],
      srcFileName: padded[2],
      line: padded[3],
      column: padded[4],
      nodeId: padded[5],
      name: padded[6],
      destFileName: padded[7],
      destLine: padded[8],
      destColumn: padded[9],
      destNodeId: padded[10],
      destName: padded[11],
      resultState: padded[12],
      resultSeverity: padded[13],
      comment: padded[14],
      link: padded[15],
      resultStatus: padded[16],
      detectionDate: padded[17],
      extraFields: padded.length > 18 ? padded.sublist(18) : [],
    );
  }

  List<String> toRow() {
    return [
      query,
      queryPath,
      srcFileName,
      line,
      column,
      nodeId,
      name,
      destFileName,
      destLine,
      destColumn,
      destNodeId,
      destName,
      resultState,
      resultSeverity,
      comment,
      link,
      resultStatus,
      detectionDate,
      ...extraFields,
    ];
  }
}
