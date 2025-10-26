// Conditional export: use mobile implementation by default, web stub when running in browser.
export 'auth_local_repository_mobile.dart'
    if (dart.library.html) 'auth_local_repository_web.dart';
