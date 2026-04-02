class JamendoArtist {
  final String id;
  final String name;
  final String imageUrl;
  final String website;
  final int joindate;

  const JamendoArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.website,
    required this.joindate,
  });

  factory JamendoArtist.fromJson(Map<String, dynamic> json) {
    return JamendoArtist(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      website: json['website'] as String? ?? '',
      joindate: _parseInt(json['joindate']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
