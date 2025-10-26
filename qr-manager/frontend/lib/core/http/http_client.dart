// Conditional export: mobile implementation by default, web implementation when running in browser.
export 'http_client_mobile.dart'
    if (dart.library.html) 'http_client_web.dart';
