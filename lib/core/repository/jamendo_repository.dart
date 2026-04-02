import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:velo/core/models/jamendo/jamendo_album_model.dart';
import 'package:velo/core/models/jamendo/jamendo_artist_model.dart';
import 'package:velo/core/models/jamendo/jamendo_genre_model.dart';
import 'package:velo/core/models/jamendo/jamendo_track_model.dart';

class JamendoRepository {
  static const _baseUrl = 'https://api.jamendo.com/v3.0';
  static const _imageSize = '300';

  late final Dio _dio;
  late final String _clientId;

  JamendoRepository() {
    _clientId = dotenv.env['JAMENDO_CLIENT_ID'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }

  Map<String, dynamic> _base({int limit = 20, int offset = 0}) => {
        'client_id': _clientId,
        'format': 'json',
        'limit': limit,
        'offset': offset,
        'imagesize': _imageSize,
      };

  Future<List<JamendoTrack>> getTopTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/tracks',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'order': 'popularity_total',
          'include': 'musicinfo+stats',
          'audioformat': 'mp32',
        },
      );
      return _parseTracks(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.getTopTracks error: $e');
      return [];
    }
  }

  Future<List<JamendoTrack>> getRecommendedTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/tracks',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'order': 'popularity_week',
          'include': 'musicinfo+stats',
          'audioformat': 'mp32',
        },
      );
      return _parseTracks(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.getRecommendedTracks error: $e');
      return [];
    }
  }

  Future<List<JamendoTrack>> searchTracks({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/tracks',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'search': query,
          'order': 'relevance',
          'include': 'musicinfo',
          'audioformat': 'mp32',
        },
      );
      return _parseTracks(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.searchTracks error: $e');
      return [];
    }
  }

  Future<List<JamendoTrack>> getTracksByTag({
    required String tag,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/tracks',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'tags': tag,
          'order': 'popularity_total',
          'include': 'musicinfo+stats',
          'audioformat': 'mp32',
        },
      );
      return _parseTracks(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.getTracksByTag error: $e');
      return [];
    }
  }

  Future<List<JamendoAlbum>> getNewReleases({
    int limit = 20,
    int offset = 0,
    String? tags,
  }) async {
    try {
      final queryParams = {
        ..._base(limit: limit, offset: offset),
        'order': 'releasedate_desc',
        'datebetween': _lastNMonths(6),
      };
      final String endpoint = (tags != null && tags.isNotEmpty) 
          ? '/albums/musicinfo' 
          : '/albums';
          
      if (tags != null && tags.isNotEmpty) {
        queryParams['tag'] = tags;
      }
      final resp = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _parseAlbums(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.getNewReleases error: $e');
      return [];
    }
  }

  Future<List<JamendoTrack>> getNewReleaseTracks({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/tracks',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'order': 'releasedate_desc',
          'include': 'musicinfo+stats',
          'audioformat': 'mp32',
        },
      );
      return _parseTracks(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.getNewReleaseTracks error: $e');
      return [];
    }
  }

  Future<List<JamendoAlbum>> searchAlbums({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/albums',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'namesearch': query,
          'order': 'relevance',
        },
      );
      return _parseAlbums(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.searchAlbums error: $e');
      return [];
    }
  }

  Future<List<JamendoTrack>> getAlbumTracks(String albumId) async {
    try {
      final resp = await _dio.get(
        '/albums/tracks',
        queryParameters: {
          ..._base(),
          'id': albumId,
          'audioformat': 'mp32',
        },
      );
      final albums = resp.data['results'] as List? ?? [];
      if (albums.isEmpty) return [];
      final tracksRaw = albums.first['tracks'] as List? ?? [];

      final albumName = albums.first['name'] as String? ?? 'Unknown Album';
      final albumImage = albums.first['image'] as String? ?? '';

      return tracksRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return JamendoTrack(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? 'Unknown Track',
          artistName:
              albums.first['artist_name']?.toString() ?? 'Unknown Artist',
          artistId: albums.first['artist_id']?.toString() ?? '',
          albumName: albumName,
          albumId: albumId,
          duration: int.tryParse(map['duration']?.toString() ?? '0') ?? 0,
          audioUrl: map['audio']?.toString() ?? '',
          imageUrl: albumImage,
          tags: [],
          position: int.tryParse(map['position']?.toString() ?? '0') ?? 0,
          shareCount: 0,
          listenCount: 0,
        );
      }).toList();
    } on DioException catch (e) {
      debugPrint('JamendoRepo.getAlbumTracks error: $e');
      return [];
    }
  }

  Future<List<JamendoArtist>> searchArtists({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final resp = await _dio.get(
        '/artists',
        queryParameters: {
          ..._base(limit: limit, offset: offset),
          'namesearch': query,
        },
      );
      return _parseArtists(resp.data);
    } on DioException catch (e) {
      debugPrint('JamendoRepo.searchArtists error: $e');
      return [];
    }
  }

  static const _curatedGenres = [
    'pop',
    'rock',
    'electronic',
    'hiphop',
    'jazz',
    'classical',
    'ambient',
    'metal',
    'reggae',
    'indie',
    'folk',
    'country',
    'blues',
    'latino',
    'rnb',
    'soul',
    'punk',
    'acoustic',
    'chillout',
    'lofi'
  ];

  static const _curatedTrending = [
    'chill',
    'upbeat',
    'acoustic',
    'lofi',
    'workout',
    'study',
    'dance',
    'party'
  ];

  Future<List<JamendoGenre>> getTopGenres({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _curatedGenres
        .take(limit)
        .map((g) => JamendoGenre(
              id: g,
              name: g,
              displayName: g[0].toUpperCase() + g.substring(1),
            ))
        .toList();
  }

  Future<List<JamendoGenre>> getTrendingTags({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _curatedTrending
        .take(limit)
        .map((g) => JamendoGenre(
              id: g,
              name: g,
              displayName: g.toUpperCase(),
            ))
        .toList();
  }

  List<JamendoTrack> _parseTracks(dynamic data) {
    try {
      final results = data['results'] as List? ?? [];
      return results
          .map((e) => JamendoTrack.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('JamendoRepo._parseTracks error: $e');
      return [];
    }
  }

  List<JamendoAlbum> _parseAlbums(dynamic data) {
    try {
      final results = data['results'] as List? ?? [];
      return results
          .map((e) => JamendoAlbum.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('JamendoRepo._parseAlbums error: $e');
      return [];
    }
  }

  List<JamendoArtist> _parseArtists(dynamic data) {
    try {
      final results = data['results'] as List? ?? [];
      return results
          .map((e) => JamendoArtist.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('JamendoRepo._parseArtists error: $e');
      return [];
    }
  }

  // List<JamendoGenre> _parseGenres(dynamic data) {
  //   try {
  //     final results = data['results'] as List? ?? [];
  //     return results
  //         .map((e) => JamendoGenre.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //   } catch (e) {
  //     debugPrint('JamendoRepo._parseGenres error: $e');
  //     return [];
  //   }
  // }

  String _lastNMonths(int n) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - n, now.day);
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(from)}_${fmt(now)}';
  }
}
