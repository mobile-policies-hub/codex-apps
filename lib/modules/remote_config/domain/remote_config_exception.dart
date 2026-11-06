/// The remote config endpoint could not be read or did not match the contract.
class RemoteConfigException implements Exception {
  const RemoteConfigException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    final cause = this.cause;
    if (cause == null) return 'RemoteConfigException: $message';
    return 'RemoteConfigException: $message ($cause)';
  }
}
