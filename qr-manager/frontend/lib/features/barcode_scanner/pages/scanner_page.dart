// Conditional export
export 'scanner_page_mobile.dart'
    if (dart.library.html) 'scanner_page_web.dart';
