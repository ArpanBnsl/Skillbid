import '../config/supabase_config.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class DatabaseService {
  /// Generic method to fetch data from a table
  Future<List<Map<String, dynamic>>> fetchData({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = supabase.from(table).select(select ?? '*');

      // Apply filters
      filters?.forEach((key, value) {
        query = query.eq(key, value);
      });

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: !descending);
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null && limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      return await query;
    } catch (e) {
      AppLogger.logError('Fetch data failed from table: ', e);
      throw AppException(
        message: 'Fetch data failed: $e',
        originalException: e,
      );
    }
  }

  /// Generic method to insert data
  Future<Map<String, dynamic>> insertData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await supabase
          .from(table)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      AppLogger.logError('Insert data failed to table: ', e);
      throw AppException(
        message: 'Insert data failed: $e',
        originalException: e,
      );
    }
  }

  /// Generic method to insert many rows at once
  Future<void> insertMany({
    required String table,
    required List<Map<String, dynamic>> data,
  }) async {
    if (data.isEmpty) return;
    try {
      await supabase.from(table).insert(data);
    } catch (e) {
      AppLogger.logError('Insert many failed to table: ', e);
      throw AppException(
        message: 'Insert many failed: $e',
        originalException: e,
      );
    }
  }

  /// Generic method to upsert a single row
  Future<Map<String, dynamic>> upsertData({
    required String table,
    required Map<String, dynamic> data,
    String? onConflict,
  }) async {
    try {
      final response = await supabase
          .from(table)
          .upsert(data, onConflict: onConflict)
          .select()
          .single();
      return response;
    } catch (e) {
      AppLogger.logError('Upsert data failed in table: ', e);
      throw AppException(
        message: 'Upsert data failed: $e',
        originalException: e,
      );
    }
  }

  /// Generic method to update data
  Future<void> updateData({
    required String table,
    required Map<String, dynamic> data,
    required String id,
    String idColumn = 'id',
  }) async {
    try {
      await supabase.from(table).update(data).eq(idColumn, id);
    } catch (e) {
      AppLogger.logError('Update data failed in table: ', e);
      throw AppException(
        message: 'Update data failed: $e',
        originalException: e,
      );
    }
  }

  /// Generic method to delete data
  Future<void> deleteData({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async {
    try {
      await supabase.from(table).delete().eq(idColumn, id);
    } catch (e) {
      AppLogger.logError('Delete data failed from table: ', e);
      throw AppException(
        message: 'Delete data failed: $e',
        originalException: e,
      );
    }
  }

  /// Generic delete with arbitrary equality filters
  Future<void> deleteWhere({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = supabase.from(table).delete();
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      await query;
    } catch (e) {
      AppLogger.logError('Delete where failed from table: ', e);
      throw AppException(
        message: 'Delete where failed: $e',
        originalException: e,
      );
    }
  }

  /// Soft delete (set is_deleted = true)
  Future<void> softDeleteData({
    required String table,
    required String id,
    String idColumn = 'id',
  }) async {
    try {
      await updateData(
        table: table,
        data: {'is_deleted': true},
        id: id,
        idColumn: idColumn,
      );
    } catch (e) {
      AppLogger.logError('Soft delete failed for table: ', e);
      throw AppException(
        message: 'Soft delete failed: $e',
        originalException: e,
      );
    }
  }
}
