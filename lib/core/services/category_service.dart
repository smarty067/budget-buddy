import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../app/constants/app_constants.dart';
import '../supabase_client.dart';

/// Service for category CRUD operations — routes to Supabase or Hive (guest mode).
class CategoryService {
  CategoryService._();

  static const _uuid = Uuid();
  static const _guestBoxName = 'guest_categories';

  /// Get all categories. Seeds default categories if none exist.
  static Future<List<Map<String, dynamic>>> getAll({required bool isGuest}) async {
    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      if (box.isEmpty) {
        // Seed default categories for guest
        for (final c in AppConstants.defaultCategories) {
          final id = c['name']!.toLowerCase().replaceAll(' ', '_');
          final data = {
            'id': id,
            'user_id': 'guest',
            'name': c['name'],
            'icon': c['icon'],
            'is_default': true,
            'created_at': DateTime.now().toIso8601String(),
          };
          await box.put(id, data);
        }
      }

      final list = box.values
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return list;
    }

    try {
      final response = await SupabaseClientHelper.client
          .from('categories')
          .select()
          .order('name');
      final list = List<Map<String, dynamic>>.from(response);

      if (list.isEmpty) {
        // Return default list if table has no user-specific rows
        return AppConstants.defaultCategories.map((c) => {
          'id': c['name']!.toLowerCase(),
          'name': c['name'],
          'icon': c['icon'],
          'is_default': true,
        }).toList();
      }
      return list;
    } catch (_) {
      return AppConstants.defaultCategories.map((c) => {
        'id': c['name']!.toLowerCase(),
        'name': c['name'],
        'icon': c['icon'],
        'is_default': true,
      }).toList();
    }
  }

  /// Create a new custom category.
  static Future<Map<String, dynamic>> create({
    required String name,
    required String icon,
    required bool isGuest,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final data = {
      'id': id,
      'name': name.trim(),
      'icon': icon,
      'is_default': false,
      'created_at': now.toIso8601String(),
    };

    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      data['user_id'] = 'guest';
      await box.put(id, data);
      return data;
    }

    data['user_id'] = SupabaseClientHelper.currentUser!.id;
    final response = await SupabaseClientHelper.client
        .from('categories')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Delete a category by ID (only custom categories can be deleted).
  static Future<void> delete({
    required String id,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      await box.delete(id);
      return;
    }

    await SupabaseClientHelper.client
        .from('categories')
        .delete()
        .eq('id', id);
  }
}
