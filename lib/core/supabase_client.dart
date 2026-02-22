import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Tables
  static const String tasksTable = 'tasks';
  static const String remindersTable = 'reminders';
  static const String notesTable = 'notes';
  static const String calendarEventsTable = 'calendar_events';
  static const String filesTable = 'files';
  static const String networksTable = 'networks';
  static const String fileConnectionsTable = 'file_connections';
  static const String userProfilesTable = 'user_profiles';
  static const String syncMetadataTable = 'sync_metadata';

  // Storage buckets
  static const String filesBucket = 'user_files';
  static const String backupsBucket = 'user_backups';
  static const String avatarsBucket = 'user_avatars';
}
