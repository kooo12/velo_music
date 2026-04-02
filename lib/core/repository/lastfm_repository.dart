import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LastFmArtist {
  final String name;
  final String imageUrl;
  final String url;

  const LastFmArtist({
    required this.name,
    required this.imageUrl,
    required this.url,
  });
}

class LastFmRepository {
  static const _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  late final Dio _dio;
  late final String _apiKey;

  LastFmRepository() {
    _apiKey = dotenv.env['LASTFM_API_KEY'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  Future<List<LastFmArtist>> getSimilarArtists(String artistName,
      {int limit = 10}) async {
    if (_apiKey.isEmpty) return [];
    try {
      final resp = await _dio.get(
        '',
        queryParameters: {
          'method': 'artist.getSimilar',
          'artist': artistName,
          'api_key': _apiKey,
          'format': 'json',
          'limit': limit,
          'autocorrect': 1,
        },
      );
      final rawList = resp.data['similarartists']?['artist'] as List? ?? [];
      return rawList.map((e) {
        final images = e['image'] as List? ?? [];
        // Last.fm returns images smallest → largest, pick last (extralarge)
        final imageUrl =
            images.isNotEmpty ? (images.last['#text'] as String? ?? '') : '';
        return LastFmArtist(
          name: e['name'] as String? ?? '',
          imageUrl: imageUrl,
          url: e['url'] as String? ?? '',
        );
      }).toList();
    } on DioException catch (e) {
      debugPrint('LastFmRepo.getSimilarArtists error: $e');
      return [];
    }
  }
}
