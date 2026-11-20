// A package repository for tool/pana.sh. It lists each packed package as an
// extra version of that package and forwards every other request to pub.dev,
// so pana can resolve versions that are about to be published together.
//
//     dart run tool/pana_repository.dart <port> <package directory>...
//
// Each directory holds an unpacked archive; the archive itself is
// `<directory>.tar.gz`. When ready the server prints `Listening on <url>
// pid <pid>`; the pid is its own, not that of a launcher such as fvm.
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const _upstream = 'https://pub.dev';
const _mediaType = 'application/vnd.pub.v2+json';

Future<void> main(List<String> args) async {
  final port = int.parse(args.first);
  final base = 'http://127.0.0.1:$port';
  final local = <String, ({Object? pubspec, File archive})>{};
  for (final directory in args.skip(1)) {
    final yaml = loadYaml(File('$directory/pubspec.yaml').readAsStringSync());
    final pubspec = jsonDecode(jsonEncode(yaml)) as Map<String, Object?>;
    local[pubspec['name']! as String] = (
      pubspec: pubspec,
      archive: File('$directory.tar.gz'),
    );
  }

  final client = HttpClient();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Listening on $base pid $pid');
  await for (final request in server) {
    try {
      await _handle(request, client, local, base);
    } on Object catch (error) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('$error');
    }
    await request.response.close();
  }
}

Future<void> _handle(
  HttpRequest request,
  HttpClient client,
  Map<String, ({Object? pubspec, File archive})> local,
  String base,
) async {
  final segments = request.uri.pathSegments;
  final response = request.response;

  if (segments.length == 2 && segments.first == 'archives') {
    final name = segments.last.replaceFirst(RegExp(r'\.tar\.gz$'), '');
    final package = local[name];
    if (package == null) {
      response.statusCode = HttpStatus.notFound;
      return;
    }
    response.headers.contentType = ContentType('application', 'octet-stream');
    await response.addStream(package.archive.openRead());
    return;
  }

  final (status, contentType, body) = await _forward(client, request);
  final package =
      segments.length == 3 && segments[0] == 'api' && segments[1] == 'packages'
      ? local[segments[2]]
      : null;
  if (package == null) {
    response.statusCode = status;
    if (contentType != null) response.headers.contentType = contentType;
    response.add(body);
    return;
  }

  // A package being released: add its packed version to the listing.
  final name = segments[2];
  final listing = status == HttpStatus.ok
      ? jsonDecode(utf8.decode(body)) as Map<String, Object?>
      : <String, Object?>{'name': name, 'versions': <Object?>[]};
  final pubspec = package.pubspec! as Map<String, Object?>;
  final version = <String, Object?>{
    'version': pubspec['version'],
    'pubspec': pubspec,
    'archive_url': '$base/archives/$name.tar.gz',
  };
  final versions = [
    for (final entry in listing['versions']! as List<Object?>)
      if ((entry! as Map<String, Object?>)['version'] != pubspec['version'])
        entry,
    version,
  ];
  listing
    ..['versions'] = versions
    ..['latest'] = version;
  response.headers.contentType = ContentType.parse(_mediaType);
  response.write(jsonEncode(listing));
}

Future<(int, ContentType?, List<int>)> _forward(
  HttpClient client,
  HttpRequest request,
) async {
  final upstream = await client.getUrl(Uri.parse('$_upstream${request.uri}'));
  final accept = request.headers.value(HttpHeaders.acceptHeader);
  if (accept != null) upstream.headers.set(HttpHeaders.acceptHeader, accept);
  final reply = await upstream.close();
  final body = await reply.fold<List<int>>(
    [],
    (all, chunk) => all..addAll(chunk),
  );
  return (reply.statusCode, reply.headers.contentType, body);
}
