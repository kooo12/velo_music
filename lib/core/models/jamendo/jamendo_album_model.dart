class JamendoAlbum {
  final String id;
  final String name;
  final String artistId;
  final String artistName;
  final String releaseDate;
  final String imageUrl;
  final int tracksCount;

  const JamendoAlbum({
    required this.id,
    required this.name,
    required this.artistId,
    required this.artistName,
    required this.releaseDate,
    required this.imageUrl,
    required this.tracksCount,
  });

  factory JamendoAlbum.fromJson(Map<String, dynamic> json) {
    return JamendoAlbum(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name'] as String? ?? '',
      releaseDate: json['releasedate'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      tracksCount: _parseInt(json['tracks'] != null
          ? (json['tracks'] as List?)?.length
          : json['tracks_count']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String get releaseYear =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : releaseDate;
}
