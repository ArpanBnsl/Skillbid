import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
class SupabaseConfig {
  // TODO: Move these to environment variables in production
  // For local development, these should be in .env file and loaded via flutter_dotenv
  static const String supabaseUrl = 'https://fwsugwyorwnbvzvalykx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ3c3Vnd3lvcnduYnZ6dmFseWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1MzgwNTcsImV4cCI6MjA4NjExNDA1N30.ALJUYXyYthwm0ikm-opCaQrwVbDj-Rs5RCFBg2HhY7A';
}

final supabase = Supabase.instance.client;

/// Get the current authenticated user ID
String? getCurrentUserId() {
  return supabase.auth.currentUser?.id;
}

/// Get the current authenticated user
User? getCurrentUser() {
  return supabase.auth.currentUser;
}

/// Check if user is authenticated
bool isAuthenticated() {
  return supabase.auth.currentSession != null;
}
