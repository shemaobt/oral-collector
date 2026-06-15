// Removes a query param from the browser's address bar. The real implementation
// runs only on web (via `history.replaceState`); on every other platform it is a
// no-op. The conditional export keeps `package:web` out of non-web compilations —
// importing it unconditionally breaks the Android/iOS AOT build.
export 'url_history_stub.dart'
    if (dart.library.js_interop) 'url_history_web.dart';
