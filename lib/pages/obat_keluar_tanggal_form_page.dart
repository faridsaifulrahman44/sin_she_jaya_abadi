import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../widgets/page_header.dart';

class ObatKeluarTanggalFormPage extends StatefulWidget {
  const ObatKeluarTanggalFormPage({super.key});

  static const routeName = '/obat-keluar-tanggal-form';

  @override
  State<ObatKeluarTanggalFormPage> createState() =>
      _ObatKeluarTanggalFormPageState();
}

class _ObatKeluarTanggalFormPageState extends State<ObatKeluarTanggalFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, _selectedDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: cprimary(ctx)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader('Pilih Tanggal'),
              const SizedBox(height: 24),
              const Text(
                'Tanggal Pengeluaran',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(AppSymbols.calendarToday),
                  ),
                  child: Text(asDate(_selectedDate)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: Text(_loading ? 'Memproses...' : 'Lanjutkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
