import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:velo/core/constants/sizes.dart';
import 'package:velo/core/controllers/language_controller.dart';
import 'package:velo/core/services/playlist_service.dart';

class MusicMoodWidget extends StatelessWidget {
  final bool isCompact;

  const MusicMoodWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final playlistService = Get.find<PlaylistService>();

    return Obx(() {
      final recentSongs = playlistService.recentlyPlayed.take(10).toList();
      final mood = _analyzeMood(recentSongs);

      if (isCompact) {
        return _buildCompactMood(mood);
      }

      return _buildFullMood(mood, recentSongs);
    });
  }

  Widget _buildCompactMood(Map<String, dynamic> mood) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: mood['colors'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: mood['colors'][0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mood['emoji'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Mood'.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mood['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  mood['subtitle'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullMood(Map<String, dynamic> mood, List recentSongs) {
    final languageCtrl = Get.find<LanguageController>();
    final isMyanmar = languageCtrl.currentLocale.languageCode == 'my';

    return Container(
      constraints: BoxConstraints(
        minHeight: 150,
        maxHeight: isMyanmar ? 220 : 200,
      ),
      margin: const EdgeInsets.only(right: AppSizes.defaultSpace),
      padding: EdgeInsets.all(isMyanmar ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: mood['colors'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: mood['colors'][0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMyanmar ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mood['emoji'],
                  style: TextStyle(fontSize: isMyanmar ? 28 : 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your Music Mood'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isMyanmar ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isMyanmar ? 2 : 4),
                    Text(
                      mood['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMyanmar ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mood['subtitle'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMyanmar ? 12 : 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMyanmar ? 12 : 16),
          if (mood['description'] != null) ...[
            Flexible(
              child: Text(
                mood['description'],
                maxLines: isMyanmar ? 2 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isMyanmar ? 11 : 12,
                  height: isMyanmar ? 1.3 : 1.4,
                ),
              ),
            ),
            SizedBox(height: isMyanmar ? 8 : 12),
          ],
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isMyanmar
                      ? "လတ်တလော ဖွင့်ခဲ့သော သီချင်း ${recentSongs.length}ခု ကိုအခြေခံ၍ "
                      : 'Based on ${recentSongs.length} recent songs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isMyanmar ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _analyzeMood(List recentSongs) {
    final languageCtrl = Get.find<LanguageController>();
    if (recentSongs.isEmpty) {
      return {
        'title': 'Discovering'.tr,
        'subtitle': 'Start listening to find your mood'.tr,
        'emoji': '🎵',
        'colors': [
          const Color(0xFF6C63FF).withOpacity(0.3),
          const Color(0xFF4A4AFF).withOpacity(0.3)
        ],
        'description':
            'Your music mood will appear here as you listen to more songs.'.tr,
      };
    }

    final genres = <String, int>{};
    final artists = <String, int>{};
    num totalDuration = 0;

    for (var song in recentSongs) {
      final genre = song.genre ?? 'Unknown';
      final artist = song.artist ?? 'Unknown';
      genres[genre] = (genres[genre] ?? 0) + 1;
      artists[artist] = (artists[artist] ?? 0) + 1;
      totalDuration += song.duration;
    }

    final dominantGenre = genres.entries.isNotEmpty
        ? genres.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'Unknown'.tr;

    final uniqueArtists = artists.length;
    final avgDuration = totalDuration ~/ recentSongs.length;

    if (dominantGenre.toLowerCase().contains('rock') ||
        dominantGenre.toLowerCase().contains('metal')) {
      return _getMoodData(
          'Energetic'.tr,
          'Rocking out!'.tr,
          '🤘',
          [
            const Color(0xFFFF6B6B).withOpacity(0.3),
            const Color(0xFFE53E3E).withOpacity(0.3)
          ],
          languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်သည် $dominantGenre နှင့် အရသာရှိတဲ့ စွမ်းအင်ပြည့် စိတ်အနေအထားဖြစ်နေပါသည်။"
              : 'You\'re in an energetic mood with $dominantGenre vibes!'.tr);
    } else if (dominantGenre.toLowerCase().contains('pop') ||
        dominantGenre.toLowerCase().contains('dance')) {
      return _getMoodData(
          'Upbeat'.tr,
          'Feeling the rhythm!'.tr,
          '💃',
          [
            const Color(0xFFFF9F43).withOpacity(0.3),
            const Color(0xFFFF6B6B).withOpacity(0.3)
          ],
          languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်၏ Playlist သည် $dominantGenre စွမ်းအင်ဖြင့် ပြည့်နှက်နေပါသည်။"
              : 'Your playlist is full of $dominantGenre energy!');
    } else if (dominantGenre.toLowerCase().contains('jazz') ||
        dominantGenre.toLowerCase().contains('blues')) {
      return _getMoodData(
          'Smooth'.tr,
          'Chill vibes'.tr,
          '🎷',
          [
            const Color(0xFF4ECDC4).withOpacity(0.3),
            const Color(0xFF38B2AC).withOpacity(0.3)
          ],
          languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်သည် $dominantGenre ဂီတများ၏ ပြေပြစ်သည့်အသံကို ခံစားနားဆင်နေသည်။"
              : 'You\'re enjoying some smooth $dominantGenre sounds.');
    } else if (dominantGenre.toLowerCase().contains('classical') ||
        dominantGenre.toLowerCase().contains('orchestral')) {
      return _getMoodData(
          'Refined'.tr,
          'Elegant listening'.tr,
          '🎼',
          [
            const Color(0xFF9B59B6).withOpacity(0.3),
            const Color(0xFF8E44AD).withOpacity(0.3)
          ],
          languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်သည် $dominantGenre ဂီတ၏ အနုပညာတန်ဖိုးကို ခံစားနေပါသည်။"
              : 'You\'re appreciating $dominantGenre sophistication.');
    } else if (uniqueArtists >= 8) {
      return _getMoodData(
          'Explorer'.tr,
          'Discovering new sounds'.tr,
          '🔍',
          [
            const Color(0xFF6C63FF).withOpacity(0.3),
            const Color(0xFF4A4AFF).withOpacity(0.3)
          ],
          languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်သည် အနုပညာရှင် $uniqueArtists ယောက်၏ ဂီတများကို ရှာဖွေနေပါသည်။"
              : 'You\'re exploring music from $uniqueArtists different artists!');
    } else if (avgDuration > 300) {
      return _getMoodData(
          'Deep'.tr,
          'Immersive listening'.tr,
          '🌊',
          [
            // Colors.transparent,
            const Color(0xFF2C3E50).withOpacity(0.3),

            const Color(0xFF34495E).withOpacity(0.3),
            // Colors.transparent,
          ],
          'You\'re diving deep into longer musical journeys.'.tr);
    } else {
      return _getMoodData(
          'Balanced'.tr,
          'Mixed vibes'.tr,
          '🎶',
          [
            const Color(0xFF6C63FF).withOpacity(0.3),
            const Color(0xFF4A4AFF).withOpacity(0.3)
          ],
          languageCtrl.currentLocale.languageCode == 'my'
              ? "သင်သည် အမျိုးအစားကွဲကွဲမဲ့သော $dominantGenre ဂီတများကို ခံစားနေပါသည်။"
              : 'You\'re enjoying a diverse mix of $dominantGenre music.');
    }
  }

  Map<String, dynamic> _getMoodData(String title, String subtitle, String emoji,
      List<Color> colors, String description) {
    return {
      'title': title,
      'subtitle': subtitle,
      'emoji': emoji,
      'colors': colors,
      'description': description,
    };
  }
}
