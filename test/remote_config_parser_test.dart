import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/core/config/app_config.dart';
import 'package:hybrid_app/modules/remote_config/data/remote_config_parser.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';

void main() {
  test('parses an enabled config with a target URL', () {
    final config = parseRemoteConfigBody(
      '{"isDynamicContentEnabled":true,"targetUrl":"https://app.example.com/home"}',
    );

    expect(config.isDynamicContentEnabled, isTrue);
    expect(config.targetUrl, 'https://app.example.com/home');
    expect(config.webUri, Uri.parse('https://app.example.com/home'));
  });

  test('parses the gist payload and ignores a URL when web is off', () {
    final enabled = parseRemoteConfigBody(
      '{\n  "isDynamicContentEnabled": true,\n  "targetUrl": "https://google.com"\n}',
    );
    expect(enabled.webUri, Uri.parse('https://google.com'));

    final native = parseRemoteConfigBody(
      '{"isDynamicContentEnabled": false, "targetUrl": "https://google.com"}',
    );
    expect(native.isDynamicContentEnabled, isFalse);
    expect(native.webUri, isNull);
  });

  test('parses a disabled config without a URL', () {
    final config = parseRemoteConfigBody('{"isDynamicContentEnabled":false}');

    expect(config.isDynamicContentEnabled, isFalse);
    expect(config.targetUrl, defaultTargetUrl);
    expect(config.webUri, isNull);
  });

  test('sealed defaults keep dynamic content off', () {
    const config = RemoteConfig();

    expect(config.isDynamicContentEnabled, isFalse);
    expect(config.targetUrl, 'https://google.com');
    expect(config.webUri, isNull);
  });

  test('keeps a non-http URL on the model and hides webUri', () {
    final config = parseRemoteConfigBody(
      '{"isDynamicContentEnabled":true,"targetUrl":"ftp://files.example.com/app"}',
    );

    expect(config.targetUrl, 'ftp://files.example.com/app');
    expect(config.webUri, isNull);
  });

  test('trims a web URL before exposing webUri', () {
    final config = parseRemoteConfigBody(
      '{"isDynamicContentEnabled":true,"targetUrl":"  https://app.example.com/home  "}',
    );

    expect(config.webUri, Uri.parse('https://app.example.com/home'));
  });

  test('maps external audience tokens and falls back to standard', () {
    final extended = parseRemoteConfigBody(
      '{"isDynamicContentEnabled":false,"displayMode":"black","userCategory":"player"}',
    );
    expect(extended.isDynamicContentEnabled, isFalse);
    expect(extended.displayMode, AppDisplayMode.extended);
    expect(extended.userCategory, UserCategory.primaryUser);

    final standard = parseRemoteConfigBody(
      '{"mode":"white","user_type":"organic"}',
    );
    expect(standard.isDynamicContentEnabled, isFalse);
    expect(standard.displayMode, AppDisplayMode.standard);
    expect(standard.userCategory, UserCategory.defaultUser);

    final fallback = parseRemoteConfigBody(
      '{"displayMode":"purple","userCategory":"guest"}',
    );
    expect(fallback.displayMode, AppDisplayMode.standard);
    expect(fallback.userCategory, UserCategory.defaultUser);
    expect(fallback.isDynamicContentEnabled, isFalse);

    final derived = parseRemoteConfigBody('{"isDynamicContentEnabled":true}');
    expect(derived.displayMode, AppDisplayMode.extended);
    expect(derived.userCategory, UserCategory.primaryUser);
    expect(derived.targetUrl, defaultTargetUrl);
    expect(derived.webUri, Uri.parse(defaultTargetUrl));
  });

  test('rejects a payload that breaks the contract', () {
    expect(
      () => parseRemoteConfigBody('[]'),
      throwsA(isA<RemoteConfigException>()),
    );
    expect(
      () => parseRemoteConfigBody('{"isDynamicContentEnabled":"yes"}'),
      throwsA(isA<RemoteConfigException>()),
    );
    expect(
      () => parseRemoteConfigBody(
        '{"isDynamicContentEnabled":true,"targetUrl":1}',
      ),
      throwsA(isA<RemoteConfigException>()),
    );
    expect(
      () => parseRemoteConfigBody('not-json'),
      throwsA(isA<RemoteConfigException>()),
    );
  });
}
