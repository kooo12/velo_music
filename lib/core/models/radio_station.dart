import 'package:velo/core/models/song_model.dart';

class RadioStation {
  final String name;
  final String url;
  final String? urlResolved;
  String? favicon;
  final String? tags;
  final String? country;
  final String? language;
  final String stationuuid;
  final String? codec;
  final int? bitrate;
  final int? votes;

  RadioStation({
    required this.name,
    required this.url,
    this.urlResolved,
    this.favicon,
    this.tags,
    this.country,
    this.language,
    required this.stationuuid,
    this.codec,
    this.bitrate,
    this.votes,
  });

  SongModel toSongModel() {
    return SongModel(
      id: stationuuid.hashCode,
      title: name,
      artist: language ?? country ?? 'Radio',
      album: 'Online Radio',
      duration: 0,
      data: urlResolved ?? url,
      displayName: name,
      albumArtwork: favicon,
      size: 0,
      isMusic: true,
    );
  }

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    final resolvedUrl = json['url_resolved'] ?? json['urlResolved'];
    return RadioStation(
      name: json['name'] ?? 'Unknown',
      url: json['url'] ?? '',
      urlResolved: resolvedUrl != json['url'] ? resolvedUrl : null,
      favicon: json['favicon'] != 'null' ? json['favicon'] : null,
      tags: json['tags'],
      country: json['country'],
      language: json['language'] ?? 'Unknown',
      stationuuid: json['stationuuid'] ?? '',
      codec: json['codec'],
      bitrate: json['bitrate'],
      votes: json['votes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'urlResolved': urlResolved,
      'favicon': favicon,
      'tags': tags,
      'country': country,
      'language': language,
      'stationuuid': stationuuid,
      'codec': codec,
      'bitrate': bitrate,
      'votes': votes,
    };
  }
}
