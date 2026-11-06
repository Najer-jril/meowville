import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseKey => dotenv.env['SUPABASE_KEY'] ?? '';
}
