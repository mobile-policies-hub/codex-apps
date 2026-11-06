import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/core/config/api_config.dart';

void main() {
  test('fromEnvironment uses the documented default URL', () {
    final config = ApiConfig.fromEnvironment();

    expect(config.remoteConfigUri, Uri.parse(ApiConfig.defaultRemoteConfigUrl));
  });

  test('accepts an absolute http URL', () {
    final config = ApiConfig(
      remoteConfigUri: Uri.parse('http://localhost:8080/config'),
    );

    expect(config.remoteConfigUri.port, 8080);
  });

  test('rejects a URL that is not absolute http(s)', () {
    expect(
      () => ApiConfig(remoteConfigUri: Uri.parse('/config')),
      throwsArgumentError,
    );
    expect(
      () => ApiConfig(remoteConfigUri: Uri.parse('ftp://example.com/config')),
      throwsArgumentError,
    );
  });
}
