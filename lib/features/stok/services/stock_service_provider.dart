import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stock_service.dart';

final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});
