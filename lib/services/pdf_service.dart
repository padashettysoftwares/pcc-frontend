import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/student.dart';
import '../services/api_service.dart';

class PDFService {
  final _api = ApiService();

  // Safely format a dynamic value to a fixed-decimal string
  // This handles String, num, int, double, null — everything the API might return
  String _fmtDec(dynamic value, int decimals) {
    if (value == null) return (0.0).toStringAsFixed(decimals);
    if (value is double) return value.toStringAsFixed(decimals);
    if (value is int) return value.toDouble().toStringAsFixed(decimals);
    if (value is num) return value.toDouble().toStringAsFixed(decimals);
    // value is String or something else — parse it
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed.toStringAsFixed(decimals);
    return (0.0).toStringAsFixed(decimals);
  }

  // Safely parse to double
  double _toNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0.0;
  }

  // Safely parse to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed ?? 0;
  }

  Future<Uint8List> generateReportCard(Student student) async {
    final pdf = pw.Document();

    // Fetch Data
    final marks = await _api.getStudentMarks(student.studentId);
    final attendanceStats = await _api.getAttendanceStats(student.studentId);
    final feeData = await _api.getStudentFees(student.studentId);

    // Pre-compute ALL values as plain Strings BEFORE building the PDF
    final String attTotal = _toInt(attendanceStats['total']).toString();
    final String attPresent = _toInt(attendanceStats['present']).toString();
    final String attPercentage = _fmtDec(attendanceStats['percentage'], 1);

    final String totalFeesStr = _fmtDec(feeData['total_fees'], 2);
    final String paidAmountStr = _fmtDec(feeData['paid_amount'], 2);
    final String dueAmountStr = _fmtDec(feeData['due_amount'], 2);
    final bool hasDue = _toNum(feeData['due_amount']) > 0;

    // Pre-process marks into plain string lists — no toStringAsFixed inside the builder
    final List<List<String>> marksData = [];
    for (final m in marks) {
      final double obt = _toNum(m['marks_obtained']);
      final double tot = _toNum(m['total_marks']);
      final double pct = tot > 0 ? (obt / tot) * 100 : 0.0;
      marksData.add([
        (m['test_name'] ?? '').toString(),
        (m['subject'] ?? '').toString(),
        (m['date'] ?? '').toString().split('T').first,
        _fmtDec(obt, 1),
        _toInt(m['total_marks']).toString(),
        '${_fmtDec(pct, 1)}%',
      ]);
    }

    final String dateStr = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                          pw.Text("Padashetty Coaching Class", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text("Excellence in Education", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text("Sangmeshwar colony beside nisty hospital SB Temple road ,Kalaburagi-585103", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text("Ph: +91 9945203603 | Ph: +91 8618075133 | Email: info@pcc.edu", style: const pw.TextStyle(fontSize: 10)),
                      ]
                   ),
                   pw.Container(
                      height: 50, width: 50,
                      decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.blue100),
                      child: pw.Center(child: pw.Text("PCC", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)))
                   )
                ]
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Student Progress Report', style: const pw.TextStyle(fontSize: 18))),
              pw.SizedBox(height: 20),

              // Student Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                            pw.Text('Name: ${student.name}'),
                            pw.Text('Class: ${student.className}'),
                            pw.Text('Student ID: ${student.studentId}'),
                        ]
                    ),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                            pw.Text('Date: $dateStr'),
                            pw.Text('Parent: ${student.parentName}'),
                        ]
                    )
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),

              // Attendance Section
              pw.Text("Attendance", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text("Total Days: $attTotal"),
              pw.Text("Present Days: $attPresent"),
              pw.Text("Percentage: $attPercentage%"),
              pw.SizedBox(height: 20),

              // Marks Table
              pw.Text("Academic Performance", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Test Name', 'Subject', 'Date', 'Marks Obtained', 'Total Marks', 'Percentage'],
                data: marksData,
              ),

              pw.SizedBox(height: 20),
              // Fee Section (Optional but good)
              pw.Text("Fee Status", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
               pw.Text("Total Fees: $totalFeesStr"),
               pw.Text("Paid Amount: $paidAmountStr"),
               pw.Text("Due Amount: $dueAmountStr", 
                    style: pw.TextStyle(color: hasDue ? PdfColors.red : PdfColors.green)),

              pw.Spacer(),
              pw.Center(child: pw.Text("Keep Learning, Keep Growing!", style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
