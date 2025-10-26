import 'package:frontend/models/task_model.dart';

class TaskLocalRepository {
  String tableName = "tasks";

  // Web stub - no database operations
  Future<void> insertTask(TaskModel task) async {
    // No-op for web
  }

  Future<void> insertTasks(List<TaskModel> tasks) async {
    // No-op for web
  }

  Future<List<TaskModel>> getTasks() async {
    return [];
  }

  Future<List<TaskModel>> getUnsyncedTasks() async {
    return [];
  }

  Future<void> updateRowValue(String id, int newValue) async {
    // No-op for web
  }
}
