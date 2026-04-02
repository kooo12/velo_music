class LyricLine {
  final Duration time;
  final String text;
  final Duration duration;

  LyricLine({
    required this.time, 
    required this.text,
    this.duration = const Duration(seconds: 4),
  });

  @override
  String toString() => '${time.inSeconds}s (${duration.inSeconds}s): $text';
}
