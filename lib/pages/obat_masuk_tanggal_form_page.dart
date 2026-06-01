import 'package:flutter/material.dart';

import '../core/design_system/app_tokens.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../widgets/page_header.dart';

class ObatMasukTanggalFormPage extends StatefulWidget {
  const ObatMasukTanggalFormPage({super.key});

  static const routeName = '/obat-masuk-tanggal-form';

  @override
  State<ObatMasukTanggalFormPage> createState() =>
      _ObatMasukTanggalFormPageState();
}

class _ObatMasukTanggalFormPageState extends State<ObatMasukTanggalFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: cteal(ctx)),
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
      appBar: AppBar(
        title: const Text('Pilih Tanggal'),
        backgroundColor: cteal(context),
        foregroundColor: conPrimary(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader('Pilih Tanggal'),
              const SizedBox(height: AppSpacing.xxl),
              const Text(
                'Tanggal Masuk',
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
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cteal(context),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _selectedDate);
                  },
                  child: const Text('Lanjutkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
