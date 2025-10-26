// Conditional export to initialize sqflite correctly on web
export 'sqflite_init_io.dart'
    if (dart.library.html) 'sqflite_init_web.dart';
