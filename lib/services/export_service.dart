import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/itinerary.dart';
import '../constants/app_constants.dart';
import '../utils/app_utils.dart';
import 'package:intl/intl.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

  Future<File> exportPdf(Itinerary itinerary) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Seyahat Planı', style: pw.TextStyle(font: boldFont, fontSize: 24)),
          ),
          pw.SizedBox(height: 20),
          ...itinerary.items.map((item) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.title,
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
              pw.Text(
                'Başlangıç: ${_dateFormat.format(item.start)}',
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                'Bitiş: ${_dateFormat.format(item.end)}',
                style: pw.TextStyle(font: font),
              ),
              if (item.description != null)
                pw.Text(
                  item.description!,
                  style: pw.TextStyle(font: font),
                ),
              pw.Divider(),
            ],
          )).toList(),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/seyahat_plani.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<String> exportCsv(Itinerary itinerary) async {
    List<List<dynamic>> rows = [
      ['Başlık', 'Başlangıç', 'Bitiş', 'Açıklama']
    ];

    for (var item in itinerary.items) {
      rows.add([
        item.title,
        _dateFormat.format(item.start),
        _dateFormat.format(item.end),
        item.description ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/seyahat_plani.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  Future<void> shareItinerary(Itinerary itinerary, ExportFormat format) async {
    try {
      switch (format) {
        case ExportFormat.pdf:
          final file = await exportPdf(itinerary);
          // Implement sharing logic here
          break;
        case ExportFormat.csv:
          final path = await exportCsv(itinerary);
          // Implement sharing logic here
          break;
      }
    } catch (e) {
      print('Dışa aktarma hatası: $e');
      rethrow;
    }
  }
}

enum ExportFormat { pdf, csv } 