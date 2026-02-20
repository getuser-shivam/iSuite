import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientConfig {
  static const String supabaseUrl = 'https://mvejpfmbymhoamhgeuwa.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12ZWpwZm1ieW1ob2FtaGdldXdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MTA2NjYsImV4cCI6MjA4NzA4NjY2Nn0.h2k2vbOjV524G1a1LFYX5WStG4FGAnP4HNmoxi-bA4c';

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
