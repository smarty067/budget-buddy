import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the current active tab index of the dashboard shell.
final dashboardTabProvider = StateProvider<int>((ref) => 0);
