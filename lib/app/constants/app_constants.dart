/// App-wide constants for Budget Buddy
class AppConstants {
  AppConstants._();

  // ── Supabase Configuration ──
  static const String supabaseUrl = 'https://zvrgpxcguadpurovvwcy.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2cmdweGNndWFkcHVyb3Z2d2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyMjcwMzgsImV4cCI6MjEwMDgwMzAzOH0.hRh4-sQUT7HBJaVsZZdE-96XYCre31b3LTpQKT_PJ-g';

  // ── App Metadata ──
  static const String appName = 'Budget Buddy';
  static const String appVersion = '1.0.0';
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';
  static const String defaultLanguage = 'en';

  // ── Validation ──
  static const int minPasswordLength = 8;
  static const int maxNoteLength = 200;

  // ── Default Categories ──
  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Food', 'icon': 'restaurant'},
    {'name': 'Transport', 'icon': 'directions_car'},
    {'name': 'Bills', 'icon': 'receipt_long'},
    {'name': 'Shopping', 'icon': 'shopping_bag'},
    {'name': 'Entertainment', 'icon': 'movie'},
    {'name': 'Health', 'icon': 'medical_services'},
    {'name': 'Education', 'icon': 'school'},
    {'name': 'Other', 'icon': 'more_horiz'},
  ];
}
