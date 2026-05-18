import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_symbols.dart';

class StockSystemInfoCard extends StatelessWidget {
  const StockSystemInfoCard({
    super.key,
    required this.stokSistem,
    required this.isEdit,
    required this.selectedNamaObat,
  });

  final int stokSistem;
  final bool isEdit;
  final String selectedNamaObat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cteal(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cteal(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(AppSymbols.computer, color: cteal(context), size: 20),
          const SizedBox(width: 10),
          Text(
            'Stok Sistem:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$stokSistem',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cteal(context),
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (isEdit)
            Text(
              'Etalase: ${selectedNamaObat.isNotEmpty ? '' : '-'}',
              style: TextStyle(
                color: ctextSecondary(context),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class StockDifferencePreviewCard extends StatelessWidget {
  const StockDifferencePreviewCard({
    super.key,
    required this.selisih,
    required this.selisihLabel,
  });

  final int selisih;
  final String selisihLabel;

  @override
  Widget build(BuildContext context) {
    final color = _selisihColor(context, selisih);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selisih == 0 ? AppSymbols.checkCircle : AppSymbols.compare,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Selisih: $selisihLabel',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (selisih != 0) ...[
            const SizedBox(width: 8),
            Text(
              '(${selisih > 0 ? 'lebih' : 'kurang'} $selisihLabel dari sistem)',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _selisihColor(BuildContext context, int value) {
    if (value == 0) return ctextSecondary(context);
    if (value > 0) return csuccess(context);
    return cdanger(context);
  }
}
