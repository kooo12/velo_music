import 'dart:convert';

class JamendoTrack {
  final String id;
  final String name;
  final String artistId;
  final String artistName;
  final String albumId;
  final String albumName;
  final int duration; // seconds
  final String audioUrl;
  final String imageUrl;
  final List<String> tags;
  final int position;
  final int shareCount;
  final int listenCount;

  // Extended fields
  final String audioDownloadUrl;
  final List<int> waveform;
  final int rateDownloadsTotal;
  final int rateListenedTotal;
  final int playlisted;
  final int favorited;
  final int likes;
  
  final String vocalInstrumental;
  final String speed;
  final List<String> tagsGenres;
  final List<String> tagsVartags;

  const JamendoTrack({
    required this.id,
    required this.name,
    required this.artistId,
    required this.artistName,
    required this.albumId,
    required this.albumName,
    required this.duration,
    required this.audioUrl,
    required this.imageUrl,
    required this.tags,
    required this.position,
    required this.shareCount,
    required this.listenCount,
    this.audioDownloadUrl = '',
    this.waveform = const [],
    this.rateDownloadsTotal = 0,
    this.rateListenedTotal = 0,
    this.playlisted = 0,
    this.favorited = 0,
    this.likes = 0,
    this.vocalInstrumental = '',
    this.speed = '',
    this.tagsGenres = const [],
    this.tagsVartags = const [],
  });

  factory JamendoTrack.fromJson(Map<String, dynamic> json) {
    final tagString = json['tags'] as String? ?? '';
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final musicinfo = json['musicinfo'] as Map<String, dynamic>? ?? {};
    final musicTags = musicinfo['tags'] as Map<String, dynamic>? ?? {};
    
    List<int> parsedWaveform = [];
    try {
      final wfString = json['waveform'] as String?;
      if (wfString != null && wfString.isNotEmpty) {
        final decoded = jsonDecode(wfString) as Map<String, dynamic>;
        final peaks = decoded['peaks'] as List? ?? [];
        parsedWaveform = peaks.map((e) => _parseInt(e)).toList();
      }
    } catch (_) {}

    return JamendoTrack(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name'] as String? ?? '',
      albumId: json['album_id']?.toString() ?? '',
      albumName: json['album_name'] as String? ?? '',
      duration: _parseInt(json['duration']),
      audioUrl: json['audio'] as String? ?? '',
      imageUrl: json['album_image'] as String? ?? json['image'] as String? ?? '',
      tags: tagString.isEmpty ? [] : tagString.split(' '),
      position: _parseInt(json['position']),
      shareCount: _parseInt(json['sharecount']),
      listenCount: _parseInt(json['listencount']),
      audioDownloadUrl: json['audiodownload'] as String? ?? '',
      waveform: parsedWaveform,
      rateDownloadsTotal: _parseInt(stats['rate_downloads_total']),
      rateListenedTotal: _parseInt(stats['rate_listened_total']),
      playlisted: _parseInt(stats['playlisted']),
      favorited: _parseInt(stats['favorited']),
      likes: _parseInt(stats['likes']),
      vocalInstrumental: musicinfo['vocalinstrumental'] as String? ?? '',
      speed: musicinfo['speed'] as String? ?? '',
      tagsGenres: _parseStringList(musicTags['genres']),
      tagsVartags: _parseStringList(musicTags['vartags']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String get formattedDuration {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
