import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:hybrid_app/modules/remote_config/data/remote_config_headers.dart';
import 'package:hybrid_app/modules/remote_config/data/remote_config_parser.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';

/// REST implementation of [RemoteConfigService].
///
/// The caller owns [client] and is responsible for closing it.
/// [timeout] is a single attempt: timeout, offline, and error responses
/// are returned to startup routing, which opens the native screen.
class HttpRemoteConfigService implements RemoteConfigService {
  HttpRemoteConfigService({
    required this.configUrl,
    required this.client,
    this.timeout = remoteConfigFetchTimeout,
    Map<String, String>? headers,
  }) : headers = headers ?? remoteConfigHeaders();

  final Uri configUrl;
  final http.Client client;
  final Duration timeout;
  final Map<String, String> headers;

  @override
  Future<RemoteConfig> fetch() async {
    final response = await _send();
    if (response.statusCode != HttpStatus.ok) {
      throw RemoteConfigException(
        'Remote config responded with status ${response.statusCode}',
      );
    }
    return parseRemoteConfigBody(response.body);
  }

  /// Drops a cached worker response so an edit is visible on the next launch.
  Uri get _requestUri {
    return configUrl.replace(
      queryParameters: {
        ...configUrl.queryParameters,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<http.Response> _send() async {
    try {
      return await client.get(_requestUri, headers: headers).timeout(timeout);
    } on TimeoutException catch (error) {
      throw RemoteConfigException(
        'Remote config request timed out',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw RemoteConfigException('Remote config request failed', cause: error);
    } on IOException catch (error) {
      throw RemoteConfigException('Remote config request failed', cause: error);
    }
  }
}
