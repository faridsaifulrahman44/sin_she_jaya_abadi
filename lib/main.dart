import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase/schema_guard.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize date formatting
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  // Initialize SharedPreferences (needed for theme persistence)
  await SharedPreferences.getInstance();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  const verifySchema =
      bool.fromEnvironment('VERIFY_SCHEMA_CONTRACT', defaultValue: false);
  if (verifySchema) {
    await SchemaGuard().verifyCriticalContracts();
  }

  runApp(const ProviderScope(child: KlinikApp()));
}
