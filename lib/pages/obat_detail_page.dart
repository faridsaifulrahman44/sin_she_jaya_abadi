import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../data/models/obat_etalase.dart';
import '../data/models/obat_model.dart';
import '../widgets/page_header.dart';

class ObatDetailPage extends StatefulWidget {
  const ObatDetailPage({super.key});

  static const routeName = '/obat-detail';

  @override
  State<ObatDetailPage> createState() => _ObatDetailPageState();
}

class _ObatDetailPageState extends State<ObatDetailPage> {
  late ObatModel _obat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ObatModel) {
      _obat = args;
      return;
    }
    if (args is Map<String, dynamic>) {
      _obat = ObatModel.fromMap(args);
      return;
    }
    _obat = ObatModel(
      idObat: 0,
      namaObat: '-',
      stokSaatIni: 0,
      stokMinimum: 10,
      etalase: Etalase.etalase1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text('Detail Obat',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: cprimary(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('Detail Obat'),
            const SizedBox(height: 24),

            // Low stock warning banner
            if (_obat.isLowStock) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cdanger(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cdanger(context).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(AppSymbols.warning, color: cdanger(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stok menipis! Kurang ${_obat.selisihStok} unit dari minimum.',
                        style: TextStyle(
                          color: cdanger(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ccardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cdivider(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Obat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ctextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ObatImage(
                      namaObat: _obat.namaObat,
                      fotoKey: _obat.fotoKey,
                      fotoUpdatedAt: _obat.fotoUpdatedAt,
                      fotoUrl: _obat.fotoUrl,
                      width: 180,
                      height: 180,
                      borderRadius: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Container(
              decoration: BoxDecoration(
                color: ccardBg(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow('Nama Obat', _obat.namaObat),
                  _buildDivider(),
                  _buildDetailRow('Etalase', _obat.etalase.label),
                  _buildDivider(),
                  _buildDetailRow(
                    'Stok Saat Ini',
                    '${_obat.stokSaatIni} ${_obat.satuan ?? ''}',
                    valueColor:
                        _obat.isLowStock ? cdanger(context) : csuccess(context),
                  ),
                  _buildDivider(),
                  _buildDetailRow('Stok Minimum',
                      '${_obat.stokMinimum} ${_obat.satuan ?? ''}'),
                  _buildDivider(),
                  _buildDetailRow('Satuan', _obat.satuan ?? '-'),
                  if (_obat.keterangan != null &&
                      _obat.keterangan!.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Keterangan', _obat.keterangan!),
                  ],
                ],
              ),
            ),

            // ── Harga ────────────────────────────────────────────────────
            if (_obat.hasHargaJual || _obat.hasEceran) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: ccardBg(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Icon(
                            AppSymbols.payment,
                            color: cprimary(context),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Harga',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ctextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_obat.hasHargaJual) ...[
                      _buildDetailRow(
                        'Harga Jual',
                        '${rupiah(_obat.hargaJual!)} ${_obat.satuanJual != null && _obat.satuanJual!.trim().isNotEmpty ? '/ ${_obat.satuanJual}' : ''}',
                        valueColor: cprimary(context),
                      ),
                      if (_obat.hasEceran) _buildDivider(),
                    ],
                    if (_obat.hasEceran) ...[
                      _buildDetailRow(
                        'Harga Ecer',
                        '${rupiah(_obat.hargaEcer!)} ${_obat.satuanEcer != null && _obat.satuanEcer!.trim().isNotEmpty ? '/ ${_obat.satuanEcer}' : ''}',
                        valueColor: csuccess(context),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ctextMuted(context).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ctextMuted(context).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppSymbols.payment,
                      color: ctextMuted(context),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Harga belum diatur',
                      style: TextStyle(
                        fontSize: 13,
                        color: ctextMuted(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── Deskripsi ─────────────────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: ccardBg(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Icon(
                          AppSymbols.description,
                          color: cprimary(context),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ctextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      _obat.deskripsi != null && _obat.deskripsi!.trim().isNotEmpty
                          ? _obat.deskripsi!
                          : 'Deskripsi belum tersedia.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _obat.deskripsi != null && _obat.deskripsi!.trim().isNotEmpty
                            ? ctextPrimary(context)
                            : ctextMuted(context),
                        fontWeight: _obat.deskripsi != null && _obat.deskripsi!.trim().isNotEmpty
                            ? FontWeight.w400
                            : FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1, indent: 16, endIndent: 16, color: cdivider(context));
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ctextSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? ctextPrimary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
