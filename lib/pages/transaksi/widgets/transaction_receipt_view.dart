import 'package:flutter/material.dart';

import 'package:klinik_mobile_app/core/theme/app_theme.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';

/// Widget reusable untuk menampilkan struk pembayaran.
class TransactionReceiptView extends StatelessWidget {
  const TransactionReceiptView({
    super.key,
    required this.transaksi,
    this.items = const [],
    this.namaPasien,
    this.namaAdmin,
  });

  final TransaksiModel transaksi;
  final List<TransaksiItemModel> items;
  final String? namaPasien;
  final String? namaAdmin;

  bool get _isReadyStock =>
      transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cdivider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          const Divider(height: 24),

          // Info Transaksi
          _buildInfo(context),
          const Divider(height: 24),

          // Items / Details
          if (_isReadyStock) ...[
            _buildItemsList(context),
            const Divider(height: 24),
          ] else ...[
            _buildCustomDetails(context),
            const Divider(height: 24),
          ],

          // Total
          _buildTotal(context),
          const SizedBox(height: 8),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Sin She Jaya Abadi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'STRUK PEMBAYARAN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ctextSecondary(context),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '#${transaksi.idTransaksi}',
          style: TextStyle(
            fontSize: 12,
            color: ctextMuted(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    final metode = transaksi.metodeBayar?.label ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Tanggal', asMediumDate(transaksi.tanggal)),
        const SizedBox(height: 4),
        _buildInfoRow('Jam', asTime(transaksi.createdAt)),
        const SizedBox(height: 4),
        _buildInfoRow('Metode Bayar', metode),
        if (namaPasien != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow('Pasien', namaPasien!),
        ],
        if (namaAdmin != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow('Petugas', namaAdmin!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(builder: (context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ctextSecondary(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ctextPrimary(context),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildItemsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Obat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ctextSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        // Header row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Item',
                style: TextStyle(
                  fontSize: 10,
                  color: ctextMuted(context),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Qty',
                style: TextStyle(
                  fontSize: 10,
                  color: ctextMuted(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                'Harga',
                style: TextStyle(
                  fontSize: 10,
                  color: ctextMuted(context),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 10,
                  color: ctextMuted(context),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const Divider(height: 8),

        // Items
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.namaObat ?? 'Obat #${item.idObat}',
                      style: TextStyle(
                        fontSize: 11,
                        color: ctextPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.jumlah}',
                      style: TextStyle(
                        fontSize: 11,
                        color: ctextPrimary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ── Ecer Sederhana (FASE 3, 2026-04-27) ─────────────────────
                  // Tampilkan satuan terjual di belakang jumlah jika ada
                  Expanded(
                    child: Text(
                      '${rupiah(item.hargaSatuan)}'
                      '${item.satuanTerjual != null ? ' / ${item.satuanTerjual}' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: ctextPrimary(context),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rupiah(item.subtotal),
                      style: TextStyle(
                        fontSize: 11,
                        color: ctextPrimary(context),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCustomDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ctextSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cwarning(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            transaksi.jenisTransaksi.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cwarning(context),
            ),
          ),
        ),

        // Optional: durasi harian
        if (transaksi.durasiHarian != null) ...[
          const SizedBox(height: 8),
          Text(
            'Durasi: ${transaksi.durasiHarian} hari',
            style: TextStyle(
              fontSize: 12,
              color: ctextSecondary(context),
            ),
          ),
        ],

        // Optional: keterangan
        if (transaksi.keterangan != null &&
            transaksi.keterangan!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Catatan: ${transaksi.keterangan}',
            style: TextStyle(
              fontSize: 12,
              color: ctextMuted(context),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTotal(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TOTAL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ctextPrimary(context),
          ),
        ),
        Text(
          rupiah(transaksi.total),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: csuccess(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Terima kasih atas kunjungan Anda',
          style: TextStyle(
            fontSize: 11,
            color: ctextMuted(context),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Helper untuk format waktu dari DateTime.
String asTime(DateTime? dt) {
  if (dt == null) return '-';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
