import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/question_paper.dart';

class QuestionPaperPdfService {
  Future<Uint8List> generateQuestionPaperPdf(QuestionPaper paper) async {
    final pdf = pw.Document();

    // Fonts: Main + Bold + Italic + full symbol fallback chain
    final mainFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final italicFont = await PdfGoogleFonts.notoSansItalic();
    final mathFont = await PdfGoogleFonts.notoSansMathRegular();
    final symbolFont = await PdfGoogleFonts.notoSansSymbolsRegular();
    final symbol2Font = await PdfGoogleFonts.notoSansSymbols2Regular();
    
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(
        base: mainFont,
        bold: boldFont,
        italic: italicFont,
        fontFallback: [mathFont, symbolFont, symbol2Font],
      ),
      buildBackground: (context) {
        return pw.FullPage(
          ignoreMargins: false,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
            ),
          ),
        );
      },
      buildForeground: (context) {
        // Non-removable diagonal watermark rendered ON TOP of content
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotateBox(
              angle: -0.5,
              child: pw.Text(
                'Padashetty Coaching Class',
                style: pw.TextStyle(
                  fontSize: 54,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.6, 0.65, 0.7, 0.12),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Group questions by section
    final Map<String, List<QuestionPaperQuestion>> sections = {};
    for (final q in paper.questions) {
      final sec = q.section ?? 'A';
      sections.putIfAbsent(sec, () => []);
      sections[sec]!.add(q);
    }
    final sortedSections = sections.keys.toList()..sort();

    const sectionNames = {
      'A': 'Section A',
      'B': 'Section B',
      'C': 'Section C',
      'D': 'Section D',
    };

    const sectionDescriptions = {
      'A': 'Objective Type Questions',
      'B': 'Short Answer Questions',
      'C': 'Long Answer Questions',
      'D': 'Case-Based / Very Long Answer Questions',
    };

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => _buildHeader(paper, context),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Instructions Box
          String instructionsText = paper.instructions != null && paper.instructions!.isNotEmpty 
              ? paper.instructions! 
              : '1. All questions are compulsory.\n2. Read each question carefully before answering.\n3. Marks for each question are indicated against it.\n4. Write neat and legible answers.';

          widgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                border: pw.Border.all(color: PdfColors.grey400, width: 1),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('GENERAL INSTRUCTIONS:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.grey900,
                        letterSpacing: 0.5,
                      )),
                  pw.SizedBox(height: 6),
                  pw.Text(instructionsText, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                ],
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 16));

          // Sections
          for (final sec in sortedSections) {
            final questions = sections[sec]!;
            questions.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));

            final secMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);

            // Section Divider
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  border: pw.Border.all(color: PdfColors.blueGrey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${sectionNames[sec] ?? 'Section $sec'} — ${sectionDescriptions[sec] ?? ''}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.Text(
                      '[$secMarks Marks]',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ],
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 12));

            // Questions
            for (final q in questions) {
              widgets.add(_buildQuestion(q));
              widgets.add(pw.SizedBox(height: 8));
            }

            widgets.add(pw.SizedBox(height: 16));
          }

          // End
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(
            pw.Center(
              child: pw.Text(
                '✦ ✦ ✦   END OF QUESTION PAPER   ✦ ✦ ✦',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: PdfColors.grey600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    // Answer Key page (if enabled)
    if (paper.includeAnswerKey) {
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ANSWER KEY',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    '${paper.subject.toUpperCase()} — CLASS ${paper.className}',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 1),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  headers: ['Q.No.', 'Section', 'Type', 'Correct Answer'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.center,
                  data: paper.questions.map((q) {
                    return [
                      '${q.questionNumber}',
                      q.section ?? '-',
                      q.questionType,
                      q.correctAnswer ?? '-',
                    ];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildHeader(QuestionPaper paper, pw.Context context) {
    if (context.pageNumber > 1) return pw.SizedBox.shrink();

    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          paper.schoolName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Sangmeshwar Colony, SB Temple Road, Kalaburagi - 585103',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Ph: +91 9945203603 | +91 8618075133',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey700),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    height: 54,
                    width: 54,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.blueGrey800,
                      border: pw.Border.all(color: PdfColors.white, width: 2),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'PCC',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.blueGrey300, thickness: 1),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('EXAM: ${paper.examType?.toUpperCase() ?? "PRACTICE TEST"}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                        pw.SizedBox(height: 4),
                        pw.Text('SUBJECT: ${paper.subject.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                        if (paper.chapter != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('CHAPTER: ${paper.chapter!.toUpperCase()}', style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800)),
                        ]
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('CLASS: ${paper.className}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                        pw.SizedBox(height: 4),
                        pw.Text('MAX MARKS: ${paper.totalMarks}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                        if (paper.timeDuration != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('TIME: ${paper.timeDuration}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('PCC Coaching Classes', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _buildQuestion(QuestionPaperQuestion q) {
    final isMcq = q.questionType == 'MCQ' || q.questionType == 'Fill in the Blank' || q.questionType == 'Assertion-Reason';
    final children = <pw.Widget>[];

    children.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 26,
            child: pw.Text(
              '${q.questionNumber}.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isMcq ? 9.5 : 10.5, color: PdfColors.grey900),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              q.questionText,
              style: pw.TextStyle(fontSize: isMcq ? 9.5 : 10.5, lineSpacing: 1.2, color: PdfColors.grey900),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            '[${q.marks}]',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    if (isMcq && q.optionA != null && q.optionA!.isNotEmpty) {
      children.add(pw.SizedBox(height: 3));
      children.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 26),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildOption('A', q.optionA!)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildOption('B', q.optionB ?? '')),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildOption('C', q.optionC ?? '')),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildOption('D', q.optionD ?? '')),
            ],
          ),
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5, style: pw.BorderStyle.dashed),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _buildOption(String letter, String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '($letter) ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.blueGrey800),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.0, color: PdfColors.grey800),
          ),
        ),
      ],
    );
  }
}

