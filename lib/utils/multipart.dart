import 'package:http_server/http_server.dart';
import 'package:meta/meta.dart';

import '../hello_aqueduct.dart';

class MultipartsUtils {
  MultipartsUtils({@required this.request});

  final Request request;
  List<HttpMultipartFormData> _mulitparts;

  Future<void> parse() async {
    final transformer = MimeMultipartTransformer(
      request.raw.headers.contentType.parameters['boundary'],
    );
    final bodyStream = Stream.fromIterable(
      [await request.body.decode<List<int>>()],
    );
    _mulitparts = await transformer
        .bind(bodyStream)
        .map(HttpMultipartFormData.parse)
        .toList();

    return Future.value();
  }

  bool containsKey(String key) {
    return _mulitparts.firstWhere(
          (multipart) => multipart.contentDisposition.parameters['name'] == key,
          orElse: () => null,
        ) !=
        null;
  }

  Future<String> getValue(String key) async {
    try {
      final multipart = _mulitparts.firstWhere(
        (multipart) =>
            multipart.isText &&
            multipart.contentDisposition.parameters['name'] == key,
      );
      return await multipart.join();
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> saveFiles(String filesFolderName) async {
    final imagesPath = <String>[];
    await Future.any(
      _mulitparts.where((multipart) => multipart.isBinary).map(
        (multipart) async {
          final content = multipart.cast<List<int>>();

          final fileName = 'image${imagesPath.length}.jpg';

          imagesPath.add(fileName);

          final file = await File(
            'public/images/articles/$filesFolderName/$fileName',
          ).create(recursive: true);

          final sink = file.openWrite();

          await content.forEach(sink.add);

          await sink.flush();
          await sink.close();

          return imagesPath;
        },
      ).toList(),
    );

    return imagesPath;
  }
}
