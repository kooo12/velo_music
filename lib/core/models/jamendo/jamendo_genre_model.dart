class JamendoGenre {
  final String id;
  final String name;
  final String displayName;

  const JamendoGenre({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory JamendoGenre.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? json['tag'] as String? ?? '';
    return JamendoGenre(
      id: json['id']?.toString() ?? name,
      name: name,
      displayName: _toDisplay(name),
    );
  }

  static String _toDisplay(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }
}
