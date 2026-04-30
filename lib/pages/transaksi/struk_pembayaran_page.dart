import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:klinik_mobile_app/core/services/receipt_printer_service.dart';
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
  final _printerService = ReceiptPrinterService();
  TransaksiModel? _transaksi;
  List<TransaksiItemModel> _items = [];
  bool _loading = true;
  bool _printing = false;
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _printing ? null : _printReceipt,
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print, size: 18),
            label: Text(_printing ? 'Mencetak...' : 'Cetak Struk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: csuccess(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
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
        ),
      ],
    );
  }

  Future<void> _printReceipt() async {
    final transaksi = _transaksi;
    if (transaksi == null) return;

    final receiptText = _buildReceiptText();
    final printer = await showModalBottomSheet<ReceiptPrinterDevice>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PrinterPickerSheet(
        service: _printerService,
        receiptText: receiptText,
      ),
    );

    if (printer == null) {
      return;
    }

    if (mounted) {
      setState(() => _printing = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menghubungkan ke ${printer.name}...')),
      );
    }

    try {
      await _printerService.printReceipt(
        printer: printer,
        transaksi: transaksi,
        items: _items,
        namaPasien: _namaPasien,
        namaAdmin: _namaAdmin,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Struk berhasil dikirim ke printer'),
            backgroundColor: csuccess(context),
          ),
        );
      }
    } on ReceiptPrinterException catch (e) {
      if (mounted) {
        await _showPrinterErrorDialog(e, receiptText);
      }
    } catch (e) {
      if (mounted) {
        await _showPrinterErrorDialog(
          ReceiptPrinterException('Gagal mencetak struk: $e'),
          receiptText,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _showPrinterErrorDialog(
    ReceiptPrinterException error,
    String receiptText,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gagal Cetak Struk'),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showReceiptTextPreview(receiptText);
            },
            child: const Text('Lihat Preview'),
          ),
          if (error.canOpenSettings)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _printerService.openPermissionSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _buildReceiptText() {
    return _printerService.buildReceiptText(
      transaksi: _transaksi!,
      items: _items,
      namaPasien: _namaPasien,
      namaAdmin: _namaAdmin,
    );
  }

  void _showReceiptTextPreview(String receiptText) {
    final pageContext = context;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Teks Struk'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              receiptText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: receiptText));
              if (pageContext.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(content: Text('Preview struk disalin')),
                );
              }
            },
            child: const Text('Salin'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
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
Struk Pembayaran - Sin She Jaya Abadi
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

class _PrinterPickerSheet extends StatefulWidget {
  const _PrinterPickerSheet({
    required this.service,
    required this.receiptText,
  });

  final ReceiptPrinterService service;
  final String receiptText;

  @override
  State<_PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends State<_PrinterPickerSheet> {
  List<ReceiptPrinterDevice> _printers = [];
  ReceiptPrinterDevice? _lastPrinter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lastPrinter = await widget.service.loadLastPrinter();
      final printers = await widget.service.scanPairedPrinters();

      if (!mounted) return;
      setState(() {
        _lastPrinter = lastPrinter;
        _printers = printers;
        _loading = false;
      });
    } on ReceiptPrinterException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal scan printer Bluetooth: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pilih Printer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ctextPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Scan ulang',
                    onPressed: _loading ? null : _loadPrinters,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              Text(
                'Pastikan printer thermal sudah menyala dan dipairing di pengaturan Bluetooth Android.',
                style: TextStyle(
                  fontSize: 12,
                  color: ctextSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showReceiptTextPreview(context),
                icon: const Icon(Icons.article_outlined, size: 18),
                label: const Text('Preview Teks Struk'),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 48, color: cdanger(context)),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: ctextSecondary(context)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadPrinters,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_printers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print_disabled, size: 48, color: ctextMuted(context)),
            const SizedBox(height: 12),
            Text(
              'Belum ada printer Bluetooth yang dipairing.',
              style: TextStyle(color: ctextSecondary(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Pairing printer dari Settings Android, lalu scan ulang.',
              style: TextStyle(fontSize: 12, color: ctextMuted(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _printers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final printer = _printers[index];
        final isLast = _lastPrinter?.hasSameAddress(printer) ?? false;

        return ListTile(
          leading: Icon(
            Icons.print,
            color: isLast ? csuccess(context) : cteal(context),
          ),
          title: Text(printer.name),
          subtitle: Text(printer.macAddress),
          trailing: isLast
              ? Chip(
                  label: const Text('Terakhir'),
                  backgroundColor: csuccess(context).withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: csuccess(context)),
                )
              : null,
          onTap: () => Navigator.pop(context, printer),
        );
      },
    );
  }

  void _showReceiptTextPreview(BuildContext context) {
    final sheetContext = context;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Teks Struk'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              widget.receiptText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.receiptText));
              if (sheetContext.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Preview struk disalin')),
                );
              }
            },
            child: const Text('Salin'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
