import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/scan_finding.dart';

class ReportMergeService {
  /// Parse CSV file into list of ScanFinding
  List<ScanFinding> parseCsv(String filePath) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content);

    if (rows.isEmpty) return [];

    // Skip header row
    return rows
        .skip(1)
        .where((row) => row.isNotEmpty && row[0].toString().trim().isNotEmpty)
        .map((row) => ScanFinding.fromRow(row.map((e) => e.toString()).toList()))
        .toList();
  }

  /// Parse Excel file into list of ScanFinding
  List<ScanFinding> parseExcel(String filePath) {
    final file = File(filePath);
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    final findings = <ScanFinding>[];

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      if (sheet.maxRows < 2) continue;

      // Find the header row index by looking for "Query" in the first column
      int headerRowIndex = -1;
      for (int i = 0; i < sheet.maxRows && i < 5; i++) {
        final row = sheet.row(i);
        if (row.isNotEmpty) {
          final firstCell = row[0]?.value?.toString().trim() ?? '';
          if (firstCell == 'Query') {
            headerRowIndex = i;
            break;
          }
        }
      }

      if (headerRowIndex == -1) continue;

      // Parse data rows
      for (int i = headerRowIndex + 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        final values = row.map((cell) => cell?.value?.toString() ?? '').toList();
        if (values.isEmpty || values[0].trim().isEmpty) continue;
        findings.add(ScanFinding.fromRow(values));
      }
    }

    return findings;
  }

  /// Merge new findings with old report, copying existing comments
  MergeResult merge({
    required List<ScanFinding> oldFindings,
    required List<ScanFinding> newFindings,
  }) {
    // Build lookup map from old findings
    // Key: matchKey, Value: list of comments (may have multiple matches)
    final oldCommentMap = <String, String>{};
    for (final finding in oldFindings) {
      final comment = finding.comment.trim();
      if (comment.isNotEmpty && comment != '-') {
        oldCommentMap[finding.matchKey] = comment;
      }
    }

    int copiedCount = 0;
    int newCount = 0;

    for (final finding in newFindings) {
      final oldComment = oldCommentMap[finding.matchKey];
      if (oldComment != null) {
        finding.comment = oldComment;
        copiedCount++;
      } else {
        // Only mark as needs review if no existing comment
        if (finding.comment.trim().isEmpty || finding.comment.trim() == '-') {
          final severity = finding.resultSeverity.toUpperCase();
          if (severity == 'INFO' || severity == 'LOW') {
            finding.comment = '-';
          } else {
            finding.comment = '(需人工查看)';
            newCount++;
          }
        }
      }
    }

    return MergeResult(
      findings: newFindings,
      totalCount: newFindings.length,
      copiedCommentCount: copiedCount,
      newIssueCount: newCount,
    );
  }

  /// Export merged findings to Excel file
  Future<String> exportExcel({
    required List<ScanFinding> findings,
    required String outputPath,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = 'RedPen Report';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Write headers
    final headers = ScanFinding.headers;
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Write data rows
    for (int rowIdx = 0; rowIdx < findings.length; rowIdx++) {
      final row = findings[rowIdx].toRow();
      for (int colIdx = 0; colIdx < row.length; colIdx++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 1),
        );
        cell.value = TextCellValue(row[colIdx]);

        // Highlight new issues that need review
        if (colIdx == 14 && row[colIdx] == '(需人工查看)') {
          cell.cellStyle = CellStyle(
            fontColorHex: ExcelColor.fromHexString('#FF0000'),
            bold: true,
          );
        }
      }
    }

    // Auto-fit isn't supported, but set some reasonable column widths
    sheet.setColumnWidth(0, 30); // Query
    sheet.setColumnWidth(2, 50); // SrcFileName
    sheet.setColumnWidth(6, 30); // Name
    sheet.setColumnWidth(14, 40); // Comment
    sheet.setColumnWidth(15, 60); // Link

    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Failed to generate Excel file');

    final file = File(outputPath);
    await file.writeAsBytes(fileBytes);
    return outputPath;
  }
}

class MergeResult {
  final List<ScanFinding> findings;
  final int totalCount;
  final int copiedCommentCount;
  final int newIssueCount;

  MergeResult({
    required this.findings,
    required this.totalCount,
    required this.copiedCommentCount,
    required this.newIssueCount,
  });
}
