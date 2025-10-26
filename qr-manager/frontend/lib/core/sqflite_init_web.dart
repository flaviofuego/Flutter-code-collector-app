import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Initialize sqflite for web by delegating to the web FFI initializer.
/// Call this early in `main()` before any `openDatabase` calls.
void initSqflite() {
  // The package provides an initializer that wires the global factory.
  // This function name is provided by sqflite_common_ffi_web.
  databaseFactoryFfiWebInit();
}
