import 'dart:convert';
import 'dart:io';

/// A recorded HTTP request received by [FakeSupabaseServer], kept for
/// assertions in integration tests (did the real datasource code build the
/// request we expect: right path, right headers, right body).
class RecordedRequest {
  final String method;
  final String path;
  final String? contentType;
  final int contentLength;
  final String body;

  const RecordedRequest({
    required this.method,
    required this.path,
    required this.contentType,
    required this.contentLength,
    required this.body,
  });
}

class _StubbedResponse {
  final int statusCode;
  final Object? body;

  const _StubbedResponse(this.statusCode, this.body);
}

/// Minimal in-process HTTP server standing in for Supabase (PostgREST +
/// Storage) in integration tests, so the real repository/datasource code can
/// run unmocked against something that behaves like the real backend, without
/// a network connection or a real Supabase project.
///
/// Routes are matched on `METHOD path` (exact path, no query string). Only
/// enough of the multipart upload request is inspected (Content-Type,
/// Content-Length) to confirm a real file was sent — the multipart body
/// itself isn't parsed.
class FakeSupabaseServer {
  final HttpServer _server;
  final Map<String, _StubbedResponse> _stubs = {};
  final List<RecordedRequest> requests = [];

  FakeSupabaseServer._(this._server) {
    _server.listen(_handle);
  }

  static Future<FakeSupabaseServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return FakeSupabaseServer._(server);
  }

  String get url => 'http://127.0.0.1:${_server.port}';

  /// Registers a canned JSON (or raw string) response for `method path`
  /// (path without query string, e.g. `'/rest/v1/documents'`).
  void stub(String method, String path, {required int statusCode, Object? body}) {
    _stubs['$method $path'] = _StubbedResponse(statusCode, body);
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    final bodyBytes = await request.fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );
    final bodyString = request.headers.contentType?.mimeType == 'multipart/form-data'
        ? '<multipart: ${bodyBytes.length} bytes>'
        : utf8.decode(bodyBytes, allowMalformed: true);

    requests.add(RecordedRequest(
      method: request.method,
      path: path,
      contentType: request.headers.contentType?.mimeType,
      contentLength: bodyBytes.length,
      body: bodyString,
    ));

    final stub = _stubs['${request.method} $path'];
    if (stub == null) {
      request.response.statusCode = 404;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'message': 'No stub for ${request.method} $path'}));
      await request.response.close();
      return;
    }

    request.response.statusCode = stub.statusCode;
    request.response.headers.contentType = ContentType.json;
    if (stub.body != null) {
      request.response.write(stub.body is String ? stub.body as String : jsonEncode(stub.body));
    }
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}
