import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:velo/core/config/app_config.dart';
import 'package:velo/core/models/lyric_model.dart';

class GeniusRepository {
  static const _baseUrl = 'https://api.genius.com';

  late final Dio _apiDio;
  late final Dio _webDio;
  late final String _accessToken;

  GeniusRepository() {
    _accessToken = AppConfig.geniusAccessToken;
    _apiDio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Authorization': 'Bearer $_accessToken'},
    ));
    _webDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (kDebugMode) {
      _apiDio.interceptors.add(LogInterceptor(responseBody: true));
      _webDio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }

  Future<String?> _searchSongUrl(String artist, String title) async {
    if (_accessToken.isEmpty) return null;
    try {
      final safeTitle = title
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .trim();
      final resp = await _apiDio.get(
        '/search',
        queryParameters: {'q': '$artist $safeTitle'},
        // queryParameters: {'q': 'Coldplay+Yellow'},
      );

      final responseBody = resp.data;
      if (responseBody == null) return null;

      final Map<String, dynamic> data = responseBody is String
          ? jsonDecode(responseBody)
          : responseBody as Map<String, dynamic>;

      final responseData = data['response'];
      if (responseData == null || responseData is! Map) return null;

      final hits = responseData['hits'] as List? ?? [];
      if (hits.isEmpty) return null;
      final result = hits.first['result'];
      return result['url'] as String?;
    } on DioException catch (e) {
      debugPrint('GeniusRepo._searchSongUrl error: $e');
      return null;
    }
  }

  Future<List<LyricLine>?> getSyncedLyrics(String artist, String title) async {
    try {
      final safeTitle = title
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .trim();

      final resp = await _webDio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': artist,
          'track_name': safeTitle,
        },
      );

      if (resp.data == null) return null;

      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      final syncedLyrics = data['syncedLyrics'] as String?;

      if (syncedLyrics == null || syncedLyrics.isEmpty) {
        return null;
      }

      return _parseLrc(syncedLyrics);
    } catch (e) {
      debugPrint('GeniusRepo.getSyncedLyrics error: $e');
      return null;
    }
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');

    for (var line in lrc.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final time = Duration(
          minutes: minutes,
          milliseconds: (seconds * 1000).toInt(),
        );
        final text = match.group(3)!.trim();
        if (text.isNotEmpty) {
          lines.add(LyricLine(time: time, text: text));
        }
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  Future<String?> getLyrics(String artist, String title) async {
    if (_accessToken.isEmpty) return null;
    try {
      final url = await _searchSongUrl(artist, title);
      if (url == null) return null;

      final pageResp = await _webDio.get(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      final document = html_parser.parse(pageResp.data as String);
      final containers =
          document.querySelectorAll('[data-lyrics-container="true"]');

      if (containers.isEmpty) return null;

      final buffer = StringBuffer();
      for (final container in containers) {
        for (final br in container.querySelectorAll('br')) {
          br.replaceWith(dom.Text('\n'));
        }
        buffer.writeln(container.text.trim());
      }
      return buffer.toString().trim();
    } on DioException catch (e) {
      debugPrint('GeniusRepo.getLyrics error: $e');
      return null;
    } catch (e) {
      debugPrint('GeniusRepo.getLyrics parse error: $e');
      return null;
    }
  }
}
