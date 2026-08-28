import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cycle.dart';
import '../models/day_note.dart';

class PdfExportService {
  static Future<Uint8List> generatePeriodReport({
    required List<Cycle> cycles,
    required List<DayNote> notes,
    required int averageCycleLength,
    required int averagePeriodLength,
    int? currentDay,
    bool isOnPeriod = false,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#E05368');
    final secondaryColor = PdfColor.fromHex('#9B8AB4');
    final darkInk = PdfColor.fromHex('#2E282A');
    final mutedGray = PdfColor.fromHex('#8C8285');
    final lightBg = PdfColor.fromHex('#FFF5F6');
    final borderColor = PdfColor.fromHex('#F0E6E8');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 24,
                      height: 24,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'B',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Bloom',
                      style: pw.TextStyle(
                        color: darkInk,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Confidential Health Report - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(color: mutedGray, fontSize: 9),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 16),

            // Hero Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Menstrual Cycle & Health Summary',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: darkInk,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Exported on ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 10, color: mutedGray),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(16),
                    ),
                    child: pw.Text(
                      isOnPeriod ? 'Period Active (Day ${currentDay ?? 1})' : 'Cycle Day ${currentDay ?? "--"}',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Key Metrics Summary Row
            pw.Row(
              children: [
                _buildMetricCard('Average Cycle', '$averageCycleLength Days', primaryColor, borderColor),
                pw.SizedBox(width: 10),
                _buildMetricCard('Average Period', '$averagePeriodLength Days', primaryColor, borderColor),
                pw.SizedBox(width: 10),
                _buildMetricCard('Total Tracked', '${cycles.length} Cycles', secondaryColor, borderColor),
              ],
            ),
            pw.SizedBox(height: 20),

            // Section 1: Cycle History Table
            pw.Text(
              'CYCLE & PERIOD HISTORY',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 8),

            if (cycles.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text('No historical period records logged yet.', style: pw.TextStyle(color: mutedGray, fontSize: 11)),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2),
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(1.8),
                  5: pw.FlexColumnWidth(3.0),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: lightBg),
                    children: [
                      _th('#'),
                      _th('Start Date'),
                      _th('End Date'),
                      _th('Period Duration'),
                      _th('Cycle Length'),
                      _th('Notes / Details'),
                    ],
                  ),
                  ...cycles.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final c = entry.value;
                    final isEven = idx % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: isEven ? lightBg : PdfColors.white),
                      children: [
                        _td('$idx'),
                        _td(DateFormat('MMM d, yyyy').format(c.startDate)),
                        _td(c.endDate != null ? DateFormat('MMM d, yyyy').format(c.endDate!) : 'Ongoing'),
                        _td(c.periodLength != null ? '${c.periodLength} days' : '${c.daysSinceStart} days (active)'),
                        _td(c.cycleLength != null ? '${c.cycleLength} days' : '--'),
                        _td(c.notes.isNotEmpty ? c.notes : '—'),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 24),

            // Section 2: Daily Health & Symptom Log (Recent 15 notes)
            if (notes.isNotEmpty) ...[
              pw.Text(
                'DAILY SYMPTOM & MOOD ENTRIES',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(3.5),
                  5: pw.FlexColumnWidth(3.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: lightBg),
                    children: [
                      _th('Date'),
                      _th('Mood'),
                      _th('Flow'),
                      _th('Cramps (0-10)'),
                      _th('Symptoms'),
                      _th('Notes'),
                    ],
                  ),
                  ...notes.take(20).map((n) {
                    final moodText = n.mood != null ? _getMoodLabel(n.mood!) : '—';
                    return pw.TableRow(
                      children: [
                        _td(DateFormat('MMM d, yyyy').format(n.date)),
                        _td(moodText),
                        _td(n.flowLevel ?? 'None'),
                        _td(n.crampsSeverity > 0 ? '${n.crampsSeverity}/10' : 'None'),
                        _td(n.symptoms.isNotEmpty ? n.symptoms.join(', ') : '—'),
                        _td(n.content.isNotEmpty ? n.content : '—'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Footer note
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Notice: This summary is generated from your personal Bloom records for health tracking and physician consultations. All health data is encrypted and stored locally on your device.',
                style: pw.TextStyle(fontSize: 8.5, color: mutedGray),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static String _getMoodLabel(String mood) {
    switch (mood) {
      case '😊':
        return 'Happy';
      case '😢':
        return 'Sad';
      case '😠':
        return 'Irritable';
      case '😰':
        return 'Anxious';
      case '😴':
        return 'Tired';
      case '🥰':
        return 'Loving';
      case '😐':
        return 'Neutral';
      default:
        return mood;
    }
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor color, PdfColor border) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#8C8285')),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E282A')),
      ),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#2E282A')),
      ),
    );
  }

  static Future<void> sharePeriodReport(
    BuildContext context, {
    required List<Cycle> cycles,
    required List<DayNote> notes,
    required int averageCycleLength,
    required int averagePeriodLength,
    int? currentDay,
    bool isOnPeriod = false,
  }) async {
    final pdfBytes = await generatePeriodReport(
      cycles: cycles,
      notes: notes,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      currentDay: currentDay,
      isOnPeriod: isOnPeriod,
    );

    final filename = 'bloom_period_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }
}
