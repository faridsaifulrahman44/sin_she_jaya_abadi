import 'package:flutter/material.dart';

import 'package:klinik_mobile_app/core/theme/app_theme.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/data/repositories/transaksi_repository.dart';
import 'package:klinik_mobile_app/pages/transaksi/struk_pembayaran_page.dart';
import 'package:klinik_mobile_app/pages/transaksi_form_page.dart';

/// Halaman list transaksi (hub).
class TransaksiHubPage extends StatefulWidget {
  const TransaksiHubPage({super.key});

  static const routeName = '/transaksi-hub';

  @override
  State<TransaksiHubPage> createState() => _TransaksiHubPageState();
}

class _TransaksiHubPageState extends State<TransaksiHubPage> {
  final _repository = TransaksiRepository();
  List<TransaksiModel> _transaksiList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await _repository.getAllTransaksi();

      if (mounted) {
        setState(() {
          _transaksiList = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat transaksi: $e';
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
        title: const Text('Transaksi',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.12),
            height: 1,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _transaksiList.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaksi,
        backgroundColor: cteal(context),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
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
            onPressed: _loadTransaksi,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: ctextMuted(context)),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ctextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan + untuk menambah transaksi baru',
            style: TextStyle(fontSize: 14, color: ctextMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadTransaksi,
      color: cteal(context),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transaksiList.length,
        itemBuilder: (context, index) {
          final t = _transaksiList[index];
          return _buildTransaksiCard(context, t);
        },
      ),
    );
  }

  Widget _buildTransaksiCard(BuildContext context, TransaksiModel t) {
    final isReadyStock = t.jenisTransaksi == JenisTransaksi.obatReadyStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cdivider(context)),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to receipt
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StrukPembayaranPage(idTransaksi: t.idTransaksi),
            ),
          );
        },
        onLongPress: () {
          // Show options
          _showTransaksiOptions(t);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isReadyStock
                      ? cprimary(context).withValues(alpha: 0.1)
                      : cwarning(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isReadyStock ? Icons.medication : Icons.healing,
                  color: isReadyStock ? cprimary(context) : cwarning(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.jenisTransaksi.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ctextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asMediumDate(t.tanggal),
                      style: TextStyle(
                          fontSize: 12, color: ctextSecondary(context)),
                    ),
                    if (t.metodeBayar != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.metodeBayar!.label,
                        style:
                            TextStyle(fontSize: 12, color: ctextMuted(context)),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rupiah(t.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: csuccess(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransaksiOptions(TransaksiModel t) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Lihat Struk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StrukPembayaranPage(idTransaksi: t.idTransaksi),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Tutup'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaksi() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TransaksiFormPage()),
    );

    if (result == true) {
      _loadTransaksi();
    }
  }
}
