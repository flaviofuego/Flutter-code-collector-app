import 'package:frontend/models/user_model.dart';

class AuthLocalRepository {
  String tableName = "users";

  // Web stub - no database operations
  Future<void> insertUser(UserModel userModel) async {
    // No-op for web - rely on remote storage
  }

  Future<UserModel?> getUser() async {
    // No-op for web
    return null;
  }

  Future<void> clearUsers() async {
    // No-op for web
  }
}
