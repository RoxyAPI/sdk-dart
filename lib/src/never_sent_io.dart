import 'dart:io';

/// `ECONNREFUSED` on Linux and Android, on macOS and iOS, and on Windows.
const _refused = {111, 61, 10061};

/// Whether [error] is a connection that failed before any byte of the request was sent: a
/// refused connection or a host name that did not resolve.
bool neverSent(Object error) =>
    error is SocketException &&
    (_refused.contains(error.osError?.errorCode) ||
        error.message.startsWith('Failed host lookup'));
