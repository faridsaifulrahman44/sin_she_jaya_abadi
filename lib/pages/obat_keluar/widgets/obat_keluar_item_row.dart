import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_symbols.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/obat_model.dart';
import '../../../features/obat_keluar/obat_keluar_etalase_sync.dart';
import '../../../features/obat_keluar/obat_keluar_form_entry.dart';

class ObatKeluarItemRow extends StatefulWidget {
  const ObatKeluarItemRow({
    super.key,
    required this.index,
    required this.entry,
    required this.totalEntries,
    required this.obatList,
    required this.onRemove,
    required this.onObatChanged,
    required this.onJumlahChanged,
    required this.onHargaChanged,
  });

  final int index;
  final ObatKeluarFormEntry entry;
  final int totalEntries;
  final List<ObatModel> obatList;
  final VoidCallback onRemove;
  final ValueChanged<int?> onObatChanged;
  final ValueChanged<String> onJumlahChanged;
  final ValueChanged<String> onHargaChanged;

  @override
  State<ObatKeluarItemRow> createState() => _ObatKeluarItemRowState();
}

class _ObatKeluarItemRowState extends State<ObatKeluarItemRow> {
  late TextEditingController _jumlahCtrl;
  late TextEditingController _hargaSatuanCtrl;

  @override
  void initState() {
    super.initState();
    _jumlahCtrl = TextEditingController(
      text: widget.entry.jumlah?.toString() ?? '',
    );
    _hargaSatuanCtrl = TextEditingController(
      text: widget.entry.hargaSatuan?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void didUpdateWidget(ObatKeluarItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers when entry values change from outside (e.g. loaded for edit).
    if (widget.entry.jumlah != oldWidget.entry.jumlah) {
      final newText = widget.entry.jumlah?.toString() ?? '';
      if (_jumlahCtrl.text != newText) {
        _jumlahCtrl.text = newText;
      }
    }
    if (widget.entry.hargaSatuan != oldWidget.entry.hargaSatuan) {
      final newText = widget.entry.hargaSatuan?.toStringAsFixed(0) ?? '';
      if (_hargaSatuanCtrl.text != newText) {
        _hargaSatuanCtrl.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _hargaSatuanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cdivider(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cwarning(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Item ${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cwarning(context),
                  ),
                ),
              ),
              const Spacer(),
              if (widget.totalEntries > 1)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(
                      AppSymbols.removeCircle,
                      color: cdanger(context),
                      size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: widget.entry.idObat,
            decoration: _inputDecoration(context, 'Pilih obat').copyWith(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: widget.obatList.map((obat) {
              return DropdownMenuItem<int>(
                value: obat.idObat,
                child: Text(
                  '${obat.namaObat} (Stok: ${obat.stokSaatIni})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            validator: (value) => value == null ? 'Pilih obat' : null,
            onChanged: widget.onObatChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Etalase: ',
                style: TextStyle(
                  fontSize: 11,
                  color: ctextMuted(context),
                ),
              ),
              Text(
                ObatKeluarEtalaseSync.resolveItemEtalaseLabel(
                  idObat: widget.entry.idObat,
                  obatList: widget.obatList,
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ctextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty',
                        style: TextStyle(
                            fontSize: 11, color: ctextMuted(context))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _jumlahCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(context, 'Jumlah').copyWith(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: widget.onJumlahChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga Satuan (Rp)',
                      style:
                          TextStyle(fontSize: 11, color: ctextMuted(context)),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _hargaSatuanCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(context, '0').copyWith(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: widget.onHargaChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Subtotal: ',
                style: TextStyle(
                  fontSize: 12,
                  color: ctextSecondary(context),
                ),
              ),
              Text(
                rupiah(widget.entry.subtotal),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.entry.subtotal > 0
                      ? ctextPrimary(context)
                      : ctextMuted(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: ccardBg(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
