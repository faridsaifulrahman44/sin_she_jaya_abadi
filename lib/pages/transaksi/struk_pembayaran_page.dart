import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:klinik_mobile_app/core/theme/app_theme.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/data/repositories/transaksi_repository.dart';
import 'package:klinik_mobile_app/pages/transaksi/widgets/transaction_receipt_view.dart';

/// Halaman preview struk pembayaran.
class StrukPembayaranPage extends StatefulWidget {
  const StrukPembayaranPage({
    super.key,
    required this.idTransaksi,
  });

  final int idTransaksi;

  static const routeName = '/struk-pembayaran';

  @override
  State<StrukPembayaranPage> createState() => _StrukPembayaranPageState();
}

class _StrukPembayaranPageState extends State<StrukPembayaranPage> {
  final _repository = TransaksiRepository();
  TransaksiModel? _transaksi;
  List<TransaksiItemModel> _items = [];
  bool _loading = true;
  String? _error;
  String? _namaPasien;
  String? _namaAdmin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final transaksi = await _repository.getTransaksiById(widget.idTransaksi);
      if (transaksi == null) {
        if (mounted) {
          setState(() {
            _error = 'Transaksi tidak ditemukan';
            _loading = false;
          });
        }
        return;
      }

      // Load items only for ready stock
      List<TransaksiItemModel> items = [];
      if (transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock) {
        items = await _repository.getTransaksiItems(widget.idTransaksi);
      }

      // Load pasien and admin names
      String? namaPasien;
      String? namaAdmin;
      if (transaksi.idPasien != null) {
        namaPasien = await _repository.getNamaPasienById(transaksi.idPasien!);
      }
      namaAdmin = await _repository.getNamaAdminById(transaksi.idAdmin);

      if (mounted) {
        setState(() {
          _transaksi = transaksi;
          _items = items;
          _namaPasien = namaPasien;
          _namaAdmin = namaAdmin;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat struk: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Struk Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_transaksi != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReceipt,
              tooltip: 'Bagikan',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: cdanger(context)),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: cdanger(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final transaksi = _transaksi!;
    final isReadyStock =
        transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Receipt widget
          TransactionReceiptView(
            transaksi: transaksi,
            items: _items,
            namaPasien: _namaPasien,
            namaAdmin: _namaAdmin,
          ),

          const SizedBox(height: 24),

          // Action buttons
          _buildActions(context),

          const SizedBox(height: 16),

          // Quick summary for sharing
          _buildQuickSummary(context, isReadyStock),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copySummary,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Salin Ringkasan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ctextPrimary(context),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareReceipt,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Bagikan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cteal(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSummary(BuildContext context, bool isReadyStock) {
    final t = _transaksi!;
    final itemsList = isReadyStock
        ? _items.map((i) => '- ${i.namaObat ?? 'Obat'} x${i.jumlah}').join('\n')
        : '';

    final summary = '''
${t.jenisTransaksi.label}
Tanggal: ${asMediumDate(t.tanggal)}
${isReadyStock ? 'Item:\n$itemsList' : ''}
Total: ${rupiah(t.total)}
Metode: ${t.metodeBayar?.label ?? '-'}
''';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ctextMuted(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan (untuk berbagi)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ctextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              fontSize: 11,
              color: ctextMuted(context),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copySummary() async {
    final t = _transaksi!;
    final isReadyStock = t.jenisTransaksi == JenisTransaksi.obatReadyStock;

    final itemsList = isReadyStock
        ? _items.map((i) => '- ${i.namaObat ?? 'Obat'} x${i.jumlah}').join('\n')
        : '';

    final summary = '''
Struk Pembayaran - Klinik Sin She Jaya Abadi
=============================================
${t.jenisTransaksi.label}
Transaksi #: ${t.idTransaksi}
Tanggal: ${asMediumDate(t.tanggal)}
${isReadyStock ? 'Item:\n$itemsList' : ''}
Total: ${rupiah(t.total)}
Metode Bayar: ${t.metodeBayar?.label ?? '-'}
=============================================
Terima kasih
''';

    await Clipboard.setData(ClipboardData(text: summary));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ringkasan disalin ke clipboard')),
      );
    }
  }

  void _shareReceipt() {
    // Show share options or just copy to clipboard for now
    _copySummary();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ringkasan disalin, bisa paste ke WhatsApp/dll'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}
