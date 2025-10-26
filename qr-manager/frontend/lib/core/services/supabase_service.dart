import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../../models/barcode_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<String?> saveBarcode({
    required String code,
    required String type,
    required DateTime timestamp,
  }) async {
    if (!EnvConfig.isSupabaseConfigured) {
      debugPrint('Supabase not configured');
      return null;
    }

    try {
      final response = await _client
          .from(EnvConfig.barcodesTable)
          .insert({
            'code': code,
            'type': type,
            'timestamp': timestamp.toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error saving barcode to Supabase: $e');
      return null;
    }
  }

  static Future<List<BarcodeModel>> getAllBarcodes() async {
    if (!EnvConfig.isSupabaseConfigured) return [];

    try {
      final response = await _client
          .from(EnvConfig.barcodesTable)
          .select()
          .order('timestamp', ascending: false);

      return (response as List)
          .map((item) => BarcodeModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error fetching barcodes: $e');
      return [];
    }
  }

  static Future<bool> deleteBarcode(String id) async {
    if (!EnvConfig.isSupabaseConfigured) return false;

    try {
      await _client.from(EnvConfig.barcodesTable).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting barcode: $e');
      return false;
    }
  }

  static Future<bool> testConnection() async {
    if (!EnvConfig.isSupabaseConfigured) return false;

    try {
      await _client.from(EnvConfig.barcodesTable).select().limit(1);
      return true;
    } catch (e) {
      debugPrint('Supabase connection test failed: $e');
      return false;
    }
  }
}
