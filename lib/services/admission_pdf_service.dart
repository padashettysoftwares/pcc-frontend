import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student.dart';

class AdmissionPdfService {
  // ─── Institute Constants ───
  static const String _instituteName = 'PADASHETTY COACHING CLASS';
  static const String _tagline = 'Excellence in Education Since 2009';
  static const String _address =
      'Sangmeshwar Colony, Beside Nisty Hospital, SB Temple Road, Kalaburagi - 585103';
  static const String _phone = 'Ph: +91 9945203603  |  +91 8618075133';
  static const String _email = 'Email: padashettycoaching@gmail.com';
  static const String _website = 'www.padashettycoaching.in';

  // ─── Fonts ───
  Future<pw.Font> _baseFont() => PdfGoogleFonts.notoSansRegular();
  Future<pw.Font> _boldFont() => PdfGoogleFonts.notoSansBold();
  Future<pw.Font> _italicFont() => PdfGoogleFonts.notoSansItalic();

  pw.PageTheme _pageTheme(pw.Font base, pw.Font bold, pw.Font italic) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: base, bold: bold, italic: italic),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ADMISSION FORM PDF
  // ═══════════════════════════════════════════════════════════
  Future<Uint8List> generateAdmissionForm(
    Student student, {
    Uint8List? photoBytes,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    final base = await _baseFont();
    final bold = await _boldFont();
    final italic = await _italicFont();
    final theme = _pageTheme(base, bold, italic);

    // Try loading photo from file if photoBytes not provided
    Uint8List? resolvedPhoto = photoBytes;
    if (resolvedPhoto == null && student.photoPath != null) {
      try {
        final file = File(student.photoPath!);
        if (await file.exists()) {
          resolvedPhoto = await file.readAsBytes();
        }
      } catch (_) {}
    }

    final pw.ImageProvider? photoImage =
        resolvedPhoto != null ? pw.MemoryImage(resolvedPhoto) : null;
    final pw.ImageProvider? logoImage =
        logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final academicYear = now.month >= 4
        ? '${now.year} - ${now.year + 1}'
        : '${now.year - 1} - ${now.year}';

    pdf.addPage(
      pw.Page(
        pageTheme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              _buildHeader(logoImage),
              pw.SizedBox(height: 6),
              pw.Container(height: 3, color: PdfColors.indigo900),
              pw.Container(height: 1.5, color: PdfColors.indigo300),
              pw.SizedBox(height: 14),

              // ── TITLE ──
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 40, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    border: pw.Border.all(color: PdfColors.indigo800, width: 2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('ADMISSION FORM',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo900,
                              letterSpacing: 3)),
                      pw.SizedBox(height: 2),
                      pw.Text('Academic Year: $academicYear',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Date: $dateStr',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 12),

              // ── STUDENT DETAILS + PHOTO ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('STUDENT INFORMATION'),
                        pw.SizedBox(height: 6),
                        _detailRow('Student ID', student.studentId),
                        _detailRow('Student Name', student.name),
                        _detailRow('Class', student.className),
                        _detailRow('Date of Admission',
                            student.admissionDate),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Passport Photo Box
                  pw.Container(
                    width: 90,
                    height: 110,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: PdfColors.indigo800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: photoImage != null
                        ? pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.Image(photoImage,
                                fit: pw.BoxFit.cover,
                                width: 90,
                                height: 110))
                        : pw.Center(
                            child: pw.Column(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                    width: 30,
                                    height: 30,
                                    decoration: pw.BoxDecoration(
                                        shape: pw.BoxShape.circle,
                                        color: PdfColors.grey300),
                                    child: pw.Center(
                                        child: pw.Text('?',
                                            style: pw.TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    pw.FontWeight.bold,
                                                color:
                                                    PdfColors.grey600)))),
                                pw.SizedBox(height: 4),
                                pw.Text('PHOTO',
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey500,
                                        letterSpacing: 1.5,
                                        fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // ── PARENT INFORMATION ──
              _sectionTitle('PARENT / GUARDIAN INFORMATION'),
              pw.SizedBox(height: 6),
              _detailRow('Parent / Guardian Name', student.parentName),
              _detailRow('Contact Number', student.parentPhone),
              pw.SizedBox(height: 14),

              // ── CREDENTIALS ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber800, width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PARENT LOGIN CREDENTIALS',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber900,
                            letterSpacing: 1)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                        'Use these credentials to log in to the PCC Parent Portal App.',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Expanded(
                          child: _credentialBox(
                              'Username', student.parentUsername ?? 'N/A')),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                          child: _credentialBox(
                              'Password', student.parentPassword ?? 'N/A')),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ── TERMS & CONDITIONS ──
              _sectionTitle('TERMS & CONDITIONS'),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _termItem('1',
                        'The student must maintain regular attendance (minimum 75%) to continue enrolment.'),
                    _termItem('2',
                        'Fees once paid are non-refundable under any circumstances.'),
                    _termItem('3',
                        'The institute reserves the right to dismiss a student for misconduct or violation of rules.'),
                    _termItem('4',
                        'Parents/Guardians must attend parent-teacher meetings when notified.'),
                    _termItem('5',
                        'Any damage to institute property shall be borne by the parent/guardian.'),
                    _termItem('6',
                        'Mobile phones and electronic gadgets are strictly prohibited inside the classroom.'),
                    _termItem('7',
                        'The institute is not responsible for loss of personal belongings.'),
                    _termItem('8',
                        'Fee payment must be completed before the 10th of every month.'),
                    _termItem('9',
                        'The institute reserves the right to modify the schedule, syllabus, or fee structure.'),
                    _termItem('10',
                        'By signing this form, the parent/guardian agrees to all the above terms.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // ── DECLARATION ──
              pw.Text(
                'I, the undersigned parent/guardian, hereby declare that the information provided is true and I agree to abide by all the rules and regulations of $_instituteName.',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey800),
              ),
              pw.Spacer(),

              // ── SIGNATURES ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Parent signature
                  pw.Column(
                    children: [
                      pw.Container(
                          width: 160,
                          height: 1,
                          color: PdfColors.grey800),
                      pw.SizedBox(height: 4),
                      pw.Text('Parent / Guardian Signature',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                    ],
                  ),
                  // Institute stamp
                  pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.green800, width: 2),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('APPROVED',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green800,
                                    letterSpacing: 2)),
                            pw.Text('PCC',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green700)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signatory',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── FOOTER ──
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$_instituteName  |  $_phone',
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('This is a computer-generated document.',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════
  //  FEE RECEIPT PDF
  // ═══════════════════════════════════════════════════════════
  Future<Uint8List> generateFeeReceipt(
    Student student, {
    required double totalFees,
    required double paidAmount,
    required double dueAmount,
    Uint8List? logoBytes,
    String? receiptNo,
  }) async {
    final pdf = pw.Document();
    final base = await _baseFont();
    final bold = await _boldFont();
    final italic = await _italicFont();
    final theme = _pageTheme(base, bold, italic);

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final receiptNumber =
        receiptNo ?? 'PCC-RCT-${now.millisecondsSinceEpoch.toString().substring(6)}';

    final pw.ImageProvider? logoImage =
        logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    // Payment status
    final String statusText;
    final PdfColor statusColor;
    final PdfColor statusBg;
    if (dueAmount <= 0) {
      statusText = 'FULLY PAID';
      statusColor = PdfColors.green800;
      statusBg = PdfColors.green50;
    } else if (paidAmount > 0) {
      statusText = 'PARTIALLY PAID';
      statusColor = PdfColors.amber800;
      statusBg = PdfColors.amber50;
    } else {
      statusText = 'UNPAID';
      statusColor = PdfColors.red800;
      statusBg = PdfColors.red50;
    }

    pdf.addPage(
      pw.Page(
        pageTheme: theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              _buildHeader(logoImage),
              pw.SizedBox(height: 6),
              pw.Container(height: 3, color: PdfColors.indigo900),
              pw.Container(height: 1.5, color: PdfColors.indigo300),
              pw.SizedBox(height: 16),

              // ── TITLE ──
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 50, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    border: pw.Border.all(color: PdfColors.indigo800, width: 2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('FEE RECEIPT',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                          letterSpacing: 4)),
                ),
              ),
              pw.SizedBox(height: 14),

              // ── Receipt No & Date ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                            text: 'Receipt No: ',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800)),
                        pw.TextSpan(
                            text: receiptNumber,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.indigo800)),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                            text: 'Date: ',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800)),
                        pw.TextSpan(
                            text: dateStr,
                            style: const pw.TextStyle(
                                fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── STUDENT DETAILS ──
              _sectionTitle('STUDENT DETAILS'),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _detailRow('Student ID', student.studentId),
                    _detailRow('Student Name', student.name),
                    _detailRow('Class', student.className),
                    _detailRow('Parent / Guardian', student.parentName),
                    _detailRow('Contact', student.parentPhone),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ── FEE BREAKDOWN TABLE ──
              _sectionTitle('FEE BREAKDOWN'),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(
                    color: PdfColors.grey400, width: 1),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.indigo50),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.indigo900),
                cellStyle:
                    const pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                headers: ['Description', 'Amount (INR)'],
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                data: [
                  ['Total Fees', _formatCurrency(totalFees)],
                  ['Amount Paid', _formatCurrency(paidAmount)],
                  ['Balance Due', _formatCurrency(dueAmount)],
                ],
              ),
              pw.SizedBox(height: 12),

              // ── STATUS BADGE ──
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: statusBg,
                    border: pw.Border.all(color: statusColor, width: 2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(statusText,
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 2)),
                ),
              ),
              pw.SizedBox(height: 18),

              // ── TERMS & CONDITIONS ──
              _sectionTitle('TERMS & CONDITIONS'),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _termItem('1',
                        'Fees once paid are non-refundable and non-transferable.'),
                    _termItem('2',
                        'Please retain this receipt for future reference. Duplicate receipts will not be issued.'),
                    _termItem('3',
                        'Fee payment must be completed before the 10th of every month to avoid late charges.'),
                    _termItem('4',
                        'Cheque bounce charges of Rs. 500/- will be applicable.'),
                    _termItem('5',
                        'For any fee-related queries, contact the institute administration.'),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── SIGNATURE ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                          width: 160, height: 1, color: PdfColors.grey800),
                      pw.SizedBox(height: 4),
                      pw.Text('Parent / Guardian Signature',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.indigo800, width: 2),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('RECEIVED',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.indigo800,
                                    letterSpacing: 2)),
                            pw.Text('PCC',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.indigo700)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signatory',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── FOOTER ──
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$_instituteName  |  $_phone',
                      style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('This is a computer-generated receipt.',
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(_instituteName,
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                      letterSpacing: 1.5)),
              pw.SizedBox(height: 2),
              pw.Text(_tagline,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(_address,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey800)),
              pw.Text('$_phone  |  $_email',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey800)),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        // Logo
        logo != null
            ? pw.Container(
                width: 56,
                height: 56,
                child: pw.ClipOval(
                    child:
                        pw.Image(logo, fit: pw.BoxFit.cover, width: 56, height: 56)),
              )
            : pw.Container(
                width: 56,
                height: 56,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.indigo800,
                  border:
                      pw.Border.all(color: PdfColors.indigo300, width: 2),
                ),
                child: pw.Center(
                  child: pw.Text('PCC',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 16,
                          letterSpacing: 1)),
                ),
              ),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        border: pw.Border(
            left: pw.BorderSide(color: PdfColors.indigo800, width: 3)),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
              letterSpacing: 1)),
    );
  }

  pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text('$label :',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey900)),
          ),
        ],
      ),
    );
  }

  pw.Widget _credentialBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.amber700),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900)),
        ],
      ),
    );
  }

  pw.Widget _termItem(String number, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 18,
            child: pw.Text('$number.',
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(text,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey800)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BLANK ADMISSION FORM PDF (for manual / hardcopy entry)
  // ═══════════════════════════════════════════════════════════
  // ── compact term item for blank form ──
  pw.Widget _compactTermItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
    );
  }

  Future<Uint8List> generateBlankAdmissionForm({
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    final base = await _baseFont();
    final bold = await _boldFont();
    final italic = await _italicFont();

    // Tighter margins for compact single-page layout
    final compactTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      theme: pw.ThemeData.withFont(base: base, bold: bold, italic: italic),
    );

    final pw.ImageProvider? logoImage =
        logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final academicYear = now.month >= 4
        ? '${now.year} - ${now.year + 1}'
        : '${now.year - 1} - ${now.year}';

    pdf.addPage(
      pw.Page(
        pageTheme: compactTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── COMPACT HEADER ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(_instituteName,
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900,
                                letterSpacing: 1)),
                        pw.SizedBox(height: 1),
                        pw.Text(_address,
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('$_phone  |  $_email',
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 36,
                      height: 36,
                      child: pw.ClipOval(
                          child: pw.Image(logoImage,
                              fit: pw.BoxFit.cover, width: 36, height: 36)),
                    )
                  else
                    pw.Container(
                      width: 36,
                      height: 36,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.indigo800,
                      ),
                      child: pw.Center(
                        child: pw.Text('PCC',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 10)),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Container(height: 2, color: PdfColors.indigo900),
              pw.SizedBox(height: 6),

              // ── COMPACT TITLE + DATE ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      border:
                          pw.Border.all(color: PdfColors.indigo800, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text('ADMISSION FORM  |  $academicYear',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                            letterSpacing: 1.5)),
                  ),
                  pw.Text('Date: $dateStr',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 6),

              // ── STUDENT INFORMATION (no photo) ──
              _sectionTitle('STUDENT INFORMATION'),
              pw.SizedBox(height: 3),
              _blankRow('Student Name'),
              _blankRow('Date of Birth'),
              _blankRow('Class / Standard'),
              _blankRow('School Name'),
              _blankRow('Date of Admission'),
              pw.SizedBox(height: 5),

              // ── PARENT / GUARDIAN INFORMATION ──
              _sectionTitle('PARENT / GUARDIAN INFORMATION'),
              pw.SizedBox(height: 3),
              _blankRow('Parent / Guardian Name'),
              _blankRow("Parent's Occupation"),
              _blankRow('Contact Number'),
              _blankRow('Alternate Contact'),
              _blankRow('Email Address'),
              pw.SizedBox(height: 5),

              // ── ADDRESS ──
              _sectionTitle('ADDRESS'),
              pw.SizedBox(height: 3),
              _blankRow('Residential Address'),
              _blankRow('City / Taluk'),
              _blankRow('PIN Code'),
              pw.SizedBox(height: 5),

              // ── FEE DETAILS ──
              _sectionTitle('FEE DETAILS'),
              pw.SizedBox(height: 3),
              _blankRow('Overall Fees'),
              _blankRow('Fees Paid'),
              pw.SizedBox(height: 5),

              // ── TERMS & CONDITIONS (compact) ──
              _sectionTitle('TERMS & CONDITIONS'),
              pw.SizedBox(height: 2),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _compactTermItem('1. Student must maintain min 75% attendance.'),
                    _compactTermItem('2. Fees once paid are non-refundable.'),
                    _compactTermItem('3. Institute may dismiss student for misconduct.'),
                    _compactTermItem('4. Parents must attend PTMs when notified.'),
                    _compactTermItem('5. Property damage cost borne by parent/guardian.'),
                    _compactTermItem('6. Mobile phones strictly prohibited in class.'),
                    _compactTermItem('7. Institute not responsible for lost belongings.'),
                    _compactTermItem('8. Fees must be paid immediately upon notification by the institute.'),
                    _compactTermItem('9. Schedule/fee structure may be modified.'),
                    _compactTermItem('10. Signing agrees to all above terms.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // ── DECLARATION ──
              pw.Text(
                'I, the undersigned parent/guardian, declare that the information provided is true and I agree to abide by all the rules and regulations of $_instituteName.',
                style: pw.TextStyle(
                    fontSize: 7.5,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 4),

              // ── NOTE ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber800, width: 1),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('\u2605 NOTE: ',
                        style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber900)),
                    pw.Expanded(
                      child: pw.Text(
                        'A soft copy with student login credentials will be sent digitally.',
                        style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.amber900),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── SIGNATURES ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Parent / Guardian signature
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 24),
                      pw.Container(
                          width: 150, height: 1, color: PdfColors.grey800),
                      pw.SizedBox(height: 3),
                      pw.Text('Parent / Guardian Signature',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                    ],
                  ),
                  // Approved Stamp
                  pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(
                              color: PdfColors.green800, width: 2),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text('APPROVED',
                                style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green800,
                                    letterSpacing: 2)),
                            pw.SizedBox(height: 1),
                            pw.Container(
                                width: 50,
                                height: 0.8,
                                color: PdfColors.green600),
                            pw.SizedBox(height: 1),
                            pw.Text('PADASHETTY COACHING CLASS',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green700,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('Tutor / Authorized Signatory',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // ── FOOTER ──
              pw.Container(height: 0.8, color: PdfColors.grey400),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('$_instituteName  |  $_phone',
                      style: pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey600,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('For Office Use Only',
                      style: pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey500,
                          fontStyle: pw.FontStyle.italic)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }


  // ── blank row: label + dotted underline for manual entry ──
  pw.Widget _blankRow(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text('$label :',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800)),
          ),
          pw.Expanded(
            child: pw.Container(
              height: 1,
              margin: const pw.EdgeInsets.only(bottom: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    // Format with Indian Rupee sign and commas
    final str = amount.toStringAsFixed(2);
    final parts = str.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Indian number system formatting
    String formatted = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = ',$formatted';
        count = 0;
      } else if (count > 3 && (count - 3) % 2 == 0) {
        formatted = ',$formatted';
      }
      formatted = '${intPart[i]}$formatted';
      count++;
    }

    return 'Rs. $formatted.$decPart';
  }
}
