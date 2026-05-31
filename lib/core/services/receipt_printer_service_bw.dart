import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'receipt_printer_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/formatters.dart';
import '../../data/models/stok_alert_item.dart';
import '../../data/models/transaksi_model.dart';

/// Shared types for receipt printer services.
export 'receipt_printer_types.dart'
    show ReceiptPrinterDevice, ReceiptPrinterException;

/// Black-and-white version of ReceiptPrinterService for thermal printers.
///
/// This service generates monochrome receipts without any color styling,
/// suitable for basic thermal printers that only print in black and white.
class ReceiptPrinterServiceBW {
  static const int _lineWidth = 32;
  static const String _lastPrinterNameKey = 'receipt_printer_bw_name';
  static const String _lastPrinterMacKey = 'receipt_printer_bw_mac';

  Future<List<ReceiptPrinterDevice>> scanPairedPrinters() async {
    await _ensureBluetoothReady();

    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths.timeout(
        const Duration(seconds: 12),
      );
      return devices
          .where((device) => device.macAdress.trim().isNotEmpty)
          .map((device) => ReceiptPrinterDevice(
                name: device.name.trim().isNotEmpty ? device.name.trim() : 'Printer',
                macAddress: device.macAdress.trim(),
              ))
          .toList();
    } catch (e) {
      throw ReceiptPrinterException(
        'Gagal membaca perangkat Bluetooth yang sudah dipairing: $e',
      );
    }
  }

  Future<ReceiptPrinterDevice?> loadLastPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_lastPrinterNameKey);
    final macAddress = prefs.getString(_lastPrinterMacKey);

    if (macAddress == null || macAddress.trim().isEmpty) {
      return null;
    }

    return ReceiptPrinterDevice(
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Printer terakhir',
      macAddress: macAddress.trim(),
    );
  }

  Future<void> saveLastPrinter(ReceiptPrinterDevice printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPrinterNameKey, printer.name);
    await prefs.setString(_lastPrinterMacKey, printer.macAddress);
  }

  Future<void> printReceipt({
    required ReceiptPrinterDevice printer,
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    String? namaPasien,
    String? namaAdmin,
  }) async {
    if (printer.macAddress.trim().isEmpty) {
      throw const ReceiptPrinterException('Printer belum dipilih.');
    }

    await _ensureBluetoothReady();

    try {
      await PrintBluetoothThermal.disconnect.timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );

      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAddress,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );

      if (!connected) {
        throw ReceiptPrinterException(
          'Gagal terhubung ke ${printer.name}. Pastikan printer menyala dan sudah dipairing.',
        );
      }

      final bytes = await buildReceiptBytes(
        transaksi: transaksi,
        items: items,
        namaPasien: namaPasien,
        namaAdmin: namaAdmin,
      );
      final printed = await PrintBluetoothThermal.writeBytes(bytes).timeout(
        const Duration(seconds: 20),
        onTimeout: () => false,
      );

      if (!printed) {
        throw const ReceiptPrinterException(
          'Gagal mengirim data struk ke printer.',
        );
      }

      await saveLastPrinter(printer);
    } on ReceiptPrinterException {
      rethrow;
    } catch (e) {
      throw ReceiptPrinterException('Gagal mencetak struk: $e');
    } finally {
      await PrintBluetoothThermal.disconnect.timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
    }
  }

  Future<List<int>> buildReceiptBytes({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    String? namaPasien,
    String? namaAdmin,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final lines = _buildReceiptLines(
      transaksi: transaksi,
      items: items,
      namaPasien: namaPasien,
      namaAdmin: namaAdmin,
    );

    final bytes = <int>[];
    bytes.addAll(generator.reset());

    for (final line in lines) {
      if (line.text.isEmpty) {
        bytes.addAll(generator.emptyLines(1));
        continue;
      }

      bytes.addAll(
        generator.text(
          line.text,
          styles: PosStyles(
            align: line.align,
            bold: line.bold,
            fontType: PosFontType.fontA,
          ),
          maxCharsPerLine: _lineWidth,
        ),
      );
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut(mode: PosCutMode.partial));
    return bytes;
  }

  /// Build plain text receipt (black and white) for preview/sharing.
  String buildReceiptText({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    String? namaPasien,
    String? namaAdmin,
  }) {
    return _buildReceiptLines(
      transaksi: transaksi,
      items: items,
      namaPasien: namaPasien,
      namaAdmin: namaAdmin,
    ).map((line) => line.text).join('\n');
  }

  /// Build black-and-white thermal receipt text for stok alert summary.
  ///
  /// Returns a plain text receipt with ASCII borders and no color,
  /// suitable for monochrome thermal printers.
  Future<String> buildStokAlertReceiptBW(StokAlertSummary summary) async {
    final now = DateTime.now();
    final tanggal = _clean(asMediumDate(now));
    final jam = _formatTime(now) ?? '--:--';

    final lines = <String>[];

    // Header with ASCII box border
    lines.add(_repeat('=', _lineWidth));
    lines.add(_centerLine('SIN SHE JAYA ABADI'));
    lines.add(_centerLine('LAPORAN STOK'));
    lines.add(_repeat('=', _lineWidth));
    lines.add(_pair('Tanggal', tanggal));
    lines.add(_pair('Jam', jam));
    lines.add(_repeat('-', _lineWidth));
    lines.add('');

    // HABIS section
    if (summary.hasHabis) {
      lines.add('[!] STOK HABIS (${summary.totalHabis} item):');
      lines.add(_repeat('-', _lineWidth));
      for (final item in summary.habis) {
        final name = _wrap(item.namaObat, _lineWidth);
        for (final line in name) {
          lines.add('  $line');
        }
        final stokLabel = item.stokSaatIni == 0 ? 'Stok: HABIS' : 'Stok: ${item.stokSaatIni}';
        lines.add('  $stokLabel | Min: ${item.stokMinimum}');
      }
      lines.add('');
    }

    // MENIPIS section
    if (summary.hasMenipis) {
      lines.add('[!] STOK MENIPIS (${summary.totalMenipis} item):');
      lines.add(_repeat('-', _lineWidth));
      for (final item in summary.menipis) {
        final name = _wrap(item.namaObat, _lineWidth);
        for (final line in name) {
          lines.add('  $line');
        }
        lines.add('  Stok: ${item.stokSaatIni} | Min: ${item.stokMinimum}');
      }
      lines.add('');
    }

    // Footer
    lines.add(_repeat('=', _lineWidth));
    lines.add(_centerLine('Terima kasih'));
    lines.add(_centerLine('SinShe Jaya Abadi'));
    lines.add(_repeat('=', _lineWidth));

    return lines.join('\n');
  }

  String _centerLine(String text) {
    final clean = _clean(text);
    if (clean.length >= _lineWidth) return _truncate(clean, _lineWidth);
    final padLeft = ((_lineWidth - clean.length) / 2).floor();
    return '${' ' * padLeft}$clean';
  }

  String _repeat(String char, int times) => char * times;

  Future<bool> openPermissionSettings() => openAppSettings();

  Future<void> _ensureBluetoothReady() async {
    await _ensureBluetoothPermission();

    final enabled = await PrintBluetoothThermal.bluetoothEnabled.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );
    if (!enabled) {
      throw const ReceiptPrinterException(
        'Bluetooth belum aktif. Nyalakan Bluetooth lalu coba lagi.',
      );
    }
  }

  Future<void> _ensureBluetoothPermission() async {
    final alreadyGranted =
        await PrintBluetoothThermal.isPermissionBluetoothGranted.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );

    if (alreadyGranted) {
      return;
    }

    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    final permanentlyDenied = statuses.values.any(
      (status) => status.isPermanentlyDenied || status.isRestricted,
    );

    final grantedAfterRequest =
        await PrintBluetoothThermal.isPermissionBluetoothGranted.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );

    if (!grantedAfterRequest) {
      throw ReceiptPrinterException(
        'Izin Bluetooth/Nearby Devices belum diberikan. Aktifkan izin aplikasi lalu coba lagi.',
        canOpenSettings: permanentlyDenied,
      );
    }
  }

  List<_ReceiptLineBW> _buildReceiptLines({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    String? namaPasien,
    String? namaAdmin,
  }) {
    final lines = <_ReceiptLineBW>[];

    // Header with ASCII box border
    lines
      ..add(_ReceiptLineBW.text(_repeat('=', _lineWidth)))
      ..add(_ReceiptLineBW.center('SIN SHE JAYA ABADI', bold: true))
      ..add(_ReceiptLineBW.center('Struk Pembayaran'))
      ..add(_ReceiptLineBW.text(_repeat('=', _lineWidth)))
      ..add(_ReceiptLineBW.text(_pair('Tanggal', asMediumDate(transaksi.tanggal))));

    final jam = _formatTime(transaksi.createdAt);
    if (jam != null) {
      lines.add(_ReceiptLineBW.text(_pair('Jam', jam)));
    }

    lines
      ..add(_ReceiptLineBW.text(_pair('No', '#${transaksi.idTransaksi}')))
      ..add(_ReceiptLineBW.text(_pair('Jenis', transaksi.jenisTransaksi.label)));

    final pasien = _clean(namaPasien);
    if (pasien.isNotEmpty) {
      lines.add(_ReceiptLineBW.text(_pair('Pasien', pasien)));
    }

    final admin = _clean(namaAdmin);
    if (admin.isNotEmpty) {
      lines.add(_ReceiptLineBW.text(_pair('Petugas', admin)));
    }

    lines.add(_ReceiptLineBW.text(_repeat('-', _lineWidth)));

    if (transaksi.jenisTransaksi == JenisTransaksi.obatReadyStock) {
      if (items.isEmpty) {
        lines.add(_ReceiptLineBW.text('Tidak ada detail item.'));
      } else {
        for (final item in items) {
          final name = _clean(item.namaObat).isNotEmpty
              ? _clean(item.namaObat)
              : 'Obat #${item.idObat}';
          for (final nameLine in _wrap(name, _lineWidth)) {
            lines.add(_ReceiptLineBW.text(nameLine));
          }

          final satuan = _clean(item.satuanTerjual);
          final qty = satuan.isEmpty
              ? '${item.jumlah} x ${rupiah(item.hargaSatuan)}'
              : '${item.jumlah} $satuan x ${rupiah(item.hargaSatuan)}';
          lines.add(_ReceiptLineBW.text(_pair(qty, rupiah(item.subtotal))));
        }
      }
    } else {
      lines.add(_ReceiptLineBW.text('Layanan:'));
      for (final line in _wrap(transaksi.jenisTransaksi.label, _lineWidth)) {
        lines.add(_ReceiptLineBW.text('  $line'));
      }

      final durasi = transaksi.durasiHarian;
      if (durasi != null && durasi > 0) {
        lines.add(_ReceiptLineBW.text(_pair('Durasi', '$durasi hari')));
      }

      final catatan = _clean(transaksi.keterangan);
      if (catatan.isNotEmpty) {
        lines.add(_ReceiptLineBW.text('Catatan:'));
        for (final line in _wrap(catatan, _lineWidth)) {
          lines.add(_ReceiptLineBW.text('  $line'));
        }
      }
    }

    lines
      ..add(_ReceiptLineBW.text(_repeat('-', _lineWidth)))
      ..add(_ReceiptLineBW.text(_pair('TOTAL', rupiah(transaksi.total))))
      ..add(_ReceiptLineBW.text(_pair(
        'Metode',
        transaksi.metodeBayar?.label ?? '-',
      )))
      ..add(_ReceiptLineBW.text(_repeat('-', _lineWidth)))
      ..add(_ReceiptLineBW.center('Terima kasih atas kunjungan Anda'))
      ..add(_ReceiptLineBW.center('(c) 2026 SinShe Jaya Abadi'))
      ..add(_ReceiptLineBW.text(_repeat('=', _lineWidth)))
      ..add(_ReceiptLineBW.text(''));

    return lines;
  }

  String _pair(String left, String right) {
    final cleanLeft = _clean(left);
    final cleanRight = _clean(right);
    if (cleanRight.length >= _lineWidth) {
      return _truncate(cleanRight, _lineWidth);
    }

    final leftWidth = _lineWidth - cleanRight.length - 1;
    final leftText = _truncate(cleanLeft, leftWidth);
    final spaces = _lineWidth - leftText.length - cleanRight.length;
    return '$leftText${' ' * spaces}$cleanRight';
  }

  List<String> _wrap(String raw, int width) {
    final text = _clean(raw);
    if (text.isEmpty) return ['-'];

    final lines = <String>[];
    var current = '';

    for (final word in text.split(' ')) {
      if (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        for (var start = 0; start < word.length; start += width) {
          final end =
              (start + width) > word.length ? word.length : start + width;
          lines.add(word.substring(start, end));
        }
        continue;
      }

      if (current.isEmpty) {
        current = word;
      } else if ('$current $word'.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }

    if (current.isNotEmpty) {
      lines.add(current);
    }

    return lines;
  }

  String _truncate(String text, int maxLength) {
    if (maxLength <= 0) return '';
    if (text.length <= maxLength) return text;
    if (maxLength <= 3) return text.substring(0, maxLength);
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _clean(String? value) {
    return (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _formatTime(DateTime? value) {
    if (value == null) return null;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ReceiptLineBW {
  const _ReceiptLineBW(
    this.text, {
    this.align = PosAlign.left,
    this.bold = false,
  });

  factory _ReceiptLineBW.text(String text) => _ReceiptLineBW(text);

  factory _ReceiptLineBW.center(String text, {bool bold = false}) {
    return _ReceiptLineBW(
      text,
      align: PosAlign.center,
      bold: bold,
    );
  }

  final String text;
  final PosAlign align;
  final bool bold;
}
