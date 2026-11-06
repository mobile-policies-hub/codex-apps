import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:hybrid_app/modules/native_dashboard/presentation/apex_calc_controller.dart';

/// Builds a PDF the share sheet can open. Rates in the file are samples.
Future<Uint8List> buildApexReportPdf(ApexCalcController calc) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [
          pw.Text(
            'Apex Calc report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Rates are for reference only.'),
          pw.SizedBox(height: 16),
          pw.Text('Amount: ${calc.amount.round()}'),
          pw.Text('Rate: ${calc.rate.round()}%'),
          pw.Text('Term: ${calc.years.round()} years'),
          pw.Text('Inflation: ${calc.inflation.round()}%'),
          pw.Text('Balance: ${calc.compounded.round()}'),
          pw.Text('After inflation: ${calc.afterInflation.round()}'),
          pw.SizedBox(height: 12),
          pw.Text('Conversion: ${calc.conversionCaption}'),
          pw.Text('Result: ${calc.readout} ${calc.resultUnit}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Saved history',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (calc.history.isEmpty)
            pw.Text('No saved calculations yet.')
          else
            for (final note in calc.history)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text('${note.title}: ${note.note}'),
              ),
        ];
      },
    ),
  );
  return document.save();
}
