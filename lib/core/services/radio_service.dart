import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velo/core/models/radio_station.dart';

class RadioService {
  static const String _baseUrl =
      'https://de2.api.radio-browser.info/json/stations/bycountry/myanmar';

  Future<List<RadioStation>> getMyanmarStations() async {
    // final List<RadioStation> popularStations = [
    //   RadioStation(
    //     name: 'BBC Burmese',
    //     url:
    //         'http://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/nonuk/sbr_low/ak/bbc_burmese.m3u8',
    //     favicon:
    //         'https://static.files.bbci.co.uk/ws/simhash/burmese/favicon.ico',
    //     tags: 'News, World, Radio',
    //     country: 'United Kingdom',
    //     language: 'Burmese',
    //     stationuuid: 'popular_bbc_burmese',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'Mizzima TV',
    //     url: 'http://103.215.194.93:8282/hls/mizzimatv/vmix.m3u8',
    //     favicon: 'https://mizzima.com/sites/default/files/mizzima-logo.png',
    //     tags: 'News, Independent, TV',
    //     country: 'Myanmar',
    //     language: 'Burmese',
    //     stationuuid: 'popular_mizzima_tv',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'VOA Burmese',
    //     url:
    //         'https://voa-28.akacast.akamaistream.net/7/88/322045/v1/ibl.akacast.akamaistream.net/voa-28',
    //     favicon: 'https://burmese.voanews.com/img/logo.png',
    //     tags: 'News, World, USA',
    //     country: 'United States',
    //     language: 'Burmese',
    //     stationuuid: 'popular_voa_burmese',
    //     codec: 'MP3',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'DVB TV',
    //     url: 'https://live-stream.dvb.no/hls/stream_src/index.m3u8',
    //     favicon: 'http://dvb.no/wp-content/themes/dvb/images/dvb-logo.png',
    //     tags: 'News, Democratic, TV',
    //     country: 'Norway',
    //     language: 'Burmese',
    //     stationuuid: 'popular_dvb_tv',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'MRTV',
    //     url: 'https://mrtvott.com/cache/MRTV-HD/master.m3u8',
    //     favicon: 'https://i.imgur.com/uyv7oJH.png',
    //     tags: 'News, General, State',
    //     country: 'Myanmar',
    //     language: 'Burmese',
    //     stationuuid: 'popular_mrtv',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'Channel K',
    //     url: 'https://l1-xl1.myanmarnet.com/relay/channelk/ch1/stream.m3u8',
    //     favicon: 'https://i.imgur.com/6PqxuhF.png',
    //     tags: 'Entertainment, Series',
    //     country: 'Myanmar',
    //     language: 'Burmese',
    //     stationuuid: 'popular_channel_k',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'Mahar TV',
    //     url: 'https://tv.mahar.live/mahar/website.stream/playlist.m3u8',
    //     favicon: 'https://i.imgur.com/ig0QECf.png',
    //     tags: 'Movies, Series',
    //     country: 'Myanmar',
    //     language: 'Burmese',
    //     stationuuid: 'popular_mahar_tv',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    //   RadioStation(
    //     name: 'MNTV',
    //     url: 'https://l1-xl1.myanmarnet.com/relay/mntv/ch1/stream.m3u8',
    //     favicon: 'https://i.imgur.com/nssm7QK.png',
    //     tags: 'General, Entertainment',
    //     country: 'Myanmar',
    //     language: 'Burmese',
    //     stationuuid: 'popular_mntv',
    //     codec: 'HLS',
    //     bitrate: 0,
    //   ),
    // ];

    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<RadioStation> apiStations = [];
        for (var item in data) {
          try {
            apiStations
                .add(RadioStation.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('RadioService: Error parsing station: $e');
          }
        }

        debugPrint(
            'RadioService: Parsed ${apiStations.length} stations from API');

        for (var s in apiStations) {
          final customIcon = _customFavicons[s.name.trim().toLowerCase()];
          if (customIcon != null) {
            s.favicon = customIcon;
          }
        }

        final Map<String, RadioStation> merged = {};
        // for (var s in popularStations) {
        //   merged[s.name.toLowerCase()] = s;
        // }
        for (var s in apiStations) {
          final name = s.name.trim().toLowerCase();
          // if (name == 'mandalayfm' || name == 'mandalay fm') continue;

          if (!merged.containsKey(name)) {
            merged[name] = s;
          }
        }
        return merged.values.toList();
      } else {
        debugPrint('Failed to load stations: ${response.statusCode}');
        // return popularStations;
        return [];
      }
    } catch (e) {
      debugPrint('Failed to load stations: $e');
      // return popularStations;
      return [];
    }
  }

  Future<List<RadioStation>> getStationsByCountry(String country) async {
    final baseUrl =
        'https://de2.api.radio-browser.info/json/stations/bycountry/${Uri.encodeComponent(country.toLowerCase())}';
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<RadioStation> apiStations = [];
        for (var item in data) {
          try {
            apiStations
                .add(RadioStation.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('RadioService: Error parsing station: $e');
          }
        }

        debugPrint(
            'RadioService: Parsed ${apiStations.length} stations from API for $country');

        for (var s in apiStations) {
          final customIcon = _customFavicons[s.name.trim().toLowerCase()];
          if (customIcon != null) {
            s.favicon = customIcon;
          }
        }

        final Map<String, RadioStation> merged = {};
        for (var s in apiStations) {
          final name = s.name.trim().toLowerCase();
          if (!merged.containsKey(name)) {
            merged[name] = s;
          }
        }
        return merged.values.toList();
      } else {
        debugPrint(
            'Failed to load stations for $country: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Failed to load stations for $country: $e');
      return [];
    }
  }

  static const String _cacheKey = 'cached_radio_stations';

  Future<List<RadioStation>> getCachedStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final List<dynamic> decoded = json.decode(cachedData);
        return decoded.map((json) => RadioStation.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error reading radio cache: $e');
    }
    return [];
  }

  Future<void> cacheStations(List<RadioStation> stations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          json.encode(stations.map((s) => s.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('Error writing radio cache: $e');
    }
  }

  static final Map<String, String> _customFavicons = {
    'mrtv': 'https://i.imgur.com/uyv7oJH.png',
    'channel k': 'https://i.imgur.com/6PqxuhF.png',
    'mntv': 'https://i.imgur.com/nssm7QK.png',
    'mahar tv': 'https://i.imgur.com/ig0QECf.png',
    'cherry fm':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR005RmEES0rAznIw5lU5Cm7SqhdOKySK5SJg&s',
    'dwg radio bumese': "https://mytunein.com/images/logos/dwgradioburmese.jpg",
    'mandalayfm':
        'https://pyoneplay-library.s3.ap-south-1.amazonaws.com/radios/1687507312CTBVbq.jpeg',
    'city fm': 'https://i.imgur.com/f0iB1R2.png',
    'shwe fm': 'https://i.imgur.com/83p0pP9.png',
    'padamyar fm': 'https://i.imgur.com/O6LdG3C.png',
    'bbc burmese':
        'https://static.files.bbci.co.uk/ws/simhash/burmese/favicon.ico',
    'voa burmese': 'https://burmese.voanews.com/img/logo.png',
    'mizzima tv': 'https://mizzima.com/sites/default/files/mizzima-logo.png',
    'dvb tv': 'http://dvb.no/wp-content/themes/dvb/images/dvb-logo.png',
  };
}
