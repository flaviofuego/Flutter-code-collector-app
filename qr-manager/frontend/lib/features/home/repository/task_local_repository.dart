// Conditional export: mobile implementation by default, web stub when running in browser.
export 'task_local_repository_mobile.dart'
    if (dart.library.html) 'task_local_repository_web.dart';
