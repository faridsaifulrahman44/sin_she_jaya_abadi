import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../features/laporan/laporan_summary.dart';

/// Exports laporan data to PDF format.
class PdfExporter {
  /// Export bulanan (single-page PDF for the active period).
  static Future<pw.Document> exportLaporanBulanan(
    LaporanSummary summary,
    String periodLabel,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(periodLabel),
            pw.SizedBox(height: 16),
            _buildSummarySection(summary),
            pw.SizedBox(height: 16),
            _buildTransactionSection(summary),
            pw.SizedBox(height: 16),
            _buildPaymentMethodSection(summary),
 ],
        ),
      ),
    );

    return doc;
  }

  /// Export tahunan (multi-page PDF).
  static Future<pw.Document> exportLaporanTahunan(
    LaporanSummary summary,
    String year,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          _buildHeader('Laporan Tahunan $year'),
          pw.SizedBox(height: 16),
          _buildSummarySection(summary),
          pw.SizedBox(height: 16),
          _buildYearlyChartSection(summary, year),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF00897B),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Klinik Sin She Jaya Abadi',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(LaporanSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Ringkasan Pendapatan',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Total Pendapatan', _fmt(summary.totalPendapatanKeseluruhan)],
          ['Periode Aktif', _fmt(summary.pendapatanPeriodeAktif)],
          ['Obat', _fmt(summary.pendapatanReadyStock)],
          ['Praktek', _fmt(summary.pendapatanPraktekCustomBundled)],
        ]),
      ],
    );
  }

  static pw.Widget _buildTransactionSection(LaporanSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaksi',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Total Transaksi', '${summary.jumlahTransaksi}'],
          ['Transaksi Obat', '${summary.jumlahTransaksiReadyStock}'],
          ['Transaksi Praktek', '${summary.jumlahTransaksiPraktekCustom}'],
        ]),
      ],
    );
  }

  static pw.Widget _buildPaymentMethodSection(LaporanSummary summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Metode Pembayaran',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _buildTable([
          ['Tunai', '${summary.jumlahTransaksiCash} transaksi (${_fmt(summary.nominalCash)})'],
          ['QRIS', '${summary.jumlahTransaksiQris} transaksi (${_fmt(summary.nominalQris)})'],
        ]),
      ],
    );
  }

  static pw.Widget _buildYearlyChartSection(LaporanSummary summary, String year) {
    final months = List.generate(12, (i) {
      final month = i + 1;
      final monthPoints = summary.chartPoints
          .where((p) => p.date.month == month)
          .toList();
      final total = monthPoints.fold<double>(0, (s, p) => s + p.totalNominal);
      return [
        '$year-${month.toString().padLeft(2, '0')}',
        _fmt(total),
        '${monthPoints.length}',
      ];
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Ringkasan Per Bulan',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _buildTable(
          [['Bulan', 'Total Nominal', 'Jumlah Transaksi'], ...months],
 ),
      ],
    );
  }

  static pw.Widget _buildTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: rows.map((row) {
        return pw.TableRow(
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(cell, style: const pw.TextStyle(fontSize: 10)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static String _fmt(double value) {
    return 'Rp${value.toStringAsFixed(0).replaceAllMapped(
 RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }
}
