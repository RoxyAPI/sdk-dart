/// Whether [error] is a connection that failed before any byte of the request was sent. No
/// such failure is told apart on this platform, so none is retried.
bool neverSent(Object error) => false;
