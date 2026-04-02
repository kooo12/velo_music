class SongModel {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final String? albumArtwork;
  final String data;
  final String displayName;
  final String? genre;
  final int? track;
  final int? year;
  final int size;
  final bool isMusic;
  final List<int>? jamendoWaveform;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.albumArtwork,
    required this.data,
    required this.displayName,
    this.genre,
    this.track,
    this.year,
    required this.size,
    this.isMusic = true,
    this.jamendoWaveform,
  });

  factory SongModel.fromAudioQuery(SongModel audioSong) {
    return SongModel(
      id: audioSong.id,
      title: audioSong.title,
      artist: audioSong.artist,
      album: audioSong.album,
      duration: audioSong.duration,
      data: audioSong.data,
      displayName: audioSong.displayName,
      genre: audioSong.genre,
      track: audioSong.track,
      year: audioSong.year,
      size: audioSong.size,
      isMusic: audioSong.isMusic,
      jamendoWaveform: audioSong.jamendoWaveform,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'albumArtwork': albumArtwork,
      'data': data,
      'displayName': displayName,
      'genre': genre,
      'track': track,
      'year': year,
      'size': size,
      'isMusic': isMusic,
      'jamendoWaveform': jamendoWaveform,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      duration: json['duration'] ?? 0,
      albumArtwork: json['albumArtwork'],
      data: json['data'] ?? '',
      displayName: json['displayName'] ?? '',
      genre: json['genre'],
      track: json['track'],
      year: json['year'],
      size: json['size'] ?? 0,
      isMusic: json['isMusic'] ?? true,
      jamendoWaveform: (json['jamendoWaveform'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  String get formattedDuration {
    final minutes = (duration / 60000).floor();
    final seconds = ((duration % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileExtension {
    return data.split('.').last.toUpperCase();
  }

  String get formattedSize {
    final sizeInMB = size / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? albumArtwork,
    String? data,
    String? displayName,
    String? genre,
    int? track,
    int? year,
    int? size,
    bool? isMusic,
    List<int>? jamendoWaveform,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      albumArtwork: albumArtwork ?? this.albumArtwork,
      data: data ?? this.data,
      displayName: displayName ?? this.displayName,
      genre: genre ?? this.genre,
      track: track ?? this.track,
      year: year ?? this.year,
      size: size ?? this.size,
      isMusic: isMusic ?? this.isMusic,
      jamendoWaveform: jamendoWaveform ?? this.jamendoWaveform,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SongModel{id: $id, title: $title, artist: $artist, album: $album}';
  }
}
