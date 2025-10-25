import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Servicio para interactuar con Supabase
class SupabaseService {
  // Obtener la instancia del cliente de Supabase
  static final SupabaseClient _client = Supabase.instance.client;

  /// Guardar un código de barras escaneado en Supabase
  /// 
  /// Retorna el ID generado por Supabase o null si hay error
  static Future<String?> saveBarcode({
    required String code,
    required String type,
    required DateTime timestamp,
  }) async {
    try {
      final response = await _client
          .from(SupabaseConfig.barcodesTable)
          .insert({
            'code': code,
            'type': type,
            'timestamp': timestamp.toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error al guardar en Supabase: $e');
      return null;
    }
  }

  /// Obtener todos los códigos de barras desde Supabase
  /// 
  /// Retorna una lista de mapas con los datos
  static Future<List<Map<String, dynamic>>> getAllBarcodes() async {
    try {
      final response = await _client
          .from(SupabaseConfig.barcodesTable)
          .select()
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener códigos de Supabase: $e');
      return [];
    }
  }

  /// Eliminar un código de barras por ID
  static Future<bool> deleteBarcode(String id) async {
    try {
      await _client
          .from(SupabaseConfig.barcodesTable)
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      debugPrint('Error al eliminar código de Supabase: $e');
      return false;
    }
  }

  /// Eliminar todos los códigos de barras
  static Future<bool> deleteAllBarcodes() async {
    try {
      await _client
          .from(SupabaseConfig.barcodesTable)
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000'); // Elimina todos
      
      return true;
    } catch (e) {
      debugPrint('Error al eliminar todos los códigos de Supabase: $e');
      return false;
    }
  }

  /// Buscar códigos de barras por código
  static Future<List<Map<String, dynamic>>> searchByCode(String code) async {
    try {
      final response = await _client
          .from(SupabaseConfig.barcodesTable)
          .select()
          .ilike('code', '%$code%')
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al buscar códigos en Supabase: $e');
      return [];
    }
  }

  /// Obtener estadísticas de códigos escaneados
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _client
          .from(SupabaseConfig.barcodesTable)
          .select('id, type');

      final total = response.length;
      final Map<String, int> typeCount = {};

      for (final item in response) {
        final type = item['type'] as String;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      return {
        'total': total,
        'by_type': typeCount,
      };
    } catch (e) {
      debugPrint('Error al obtener estadísticas de Supabase: $e');
      return {'total': 0, 'by_type': {}};
    }
  }

  /// Verificar si la conexión con Supabase está funcionando
  static Future<bool> testConnection() async {
    try {
      await _client
          .from(SupabaseConfig.barcodesTable)
          .select('id')
          .limit(1);
      
      return true;
    } catch (e) {
      debugPrint('Error de conexión con Supabase: $e');
      return false;
    }
  }

  /// Suscribirse a cambios en tiempo real (opcional)
  /// 
  /// Retorna un Stream que emite eventos cuando hay cambios en la tabla
  static RealtimeChannel subscribeToChanges({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    final channel = _client
        .channel('scanned_barcodes_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.barcodesTable,
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConfig.barcodesTable,
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConfig.barcodesTable,
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();

    return channel;
  }
}
