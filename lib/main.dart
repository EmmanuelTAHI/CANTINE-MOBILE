import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize locale data for Intl/DateFormat
  await initializeDateFormatting();
  runApp(const App());
}

