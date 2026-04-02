import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velo/core/models/radio_station.dart';

class RadioService {
  Future<List<RadioStation>> getMyanmarStations(
      {int limit = 50, int offset = 0}) async {
    final url =
        'https://de2.api.radio-browser.info/json/stations/bycountry/myanmar?limit=$limit&offset=$offset&order=votes&reverse=true';
    try {
      final response = await http.get(Uri.parse(url));
      List<RadioStation> apiStations = [];
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var item in data) {
          try {
            apiStations
                .add(RadioStation.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('RadioService: Error parsing station: $e');
          }
        }
      }

      final Map<String, RadioStation> merged = {};

      if (offset == 0) {
        for (var s in _hardcodedPopularMyanmar) {
          merged[s.name.trim().toLowerCase()] = s;
        }
      }

      for (var s in apiStations) {
        final name = s.name.trim().toLowerCase();
        if (!merged.containsKey(name)) {
          merged[name] = s;
        }
      }

      final result = merged.values.toList();
      for (var s in result) {
        final favicon = _getFavicon(s.name);
        if (favicon != null) {
          s.favicon = favicon;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Failed to load stations: $e');
      return offset == 0 ? _hardcodedPopularMyanmar : [];
    }
  }

  static final List<RadioStation> _hardcodedPopularMyanmar = [
    RadioStation(
      name: 'Padamyar FM',
      url:
          'https://stream-154.zeno.fm/og9btsnj00tuv?zt=eyJhbGciOiJIUzI1NiJ9.eyJzdHJlYW0iOiJvZzlidHNuajAwdHV2IiwiaG9zdCI6InN0cmVhbS0xNTQuemVuby5mbSIsInJ0dGwiOjUsImp0aSI6ImRtM1A3SU1SUWxHdENYRkdmVDRtNmciLCJpYXQiOjE3NzQ3OTk2NjAsImV4cCI6MTc3NDc5OTcyMH0.bAfi1GkY8Z-yg9jvWP-1KWm8rPFP45ZbomK9wv33HZk',
      stationuuid: 'padamyar-fm-mp3',
      codec: 'MP3',
      votes: 950000,
      country: 'Myanmar',
      language: 'Burmese',
      favicon:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxfUbHYmSA-IDO6998lfrOJhGoSkazO6yvdQ&s',
    ),
    // RadioStation(
    //   name: 'BBC Burmese',
    //   url:
    //       'http://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/nonuk/sbr_low/ak/bbc_burmese.m3u8',
    //   stationuuid: 'bbc-burmese-hls',
    //   codec: 'HLS',
    //   votes: 1000000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon: 'https://ichef.bbci.co.uk/images/ic/1920x1080/p0l60nsg.jpg',
    // ),
    // RadioStation(
    //   name: 'VOA Burmese',
    //   url:
    //       'https://voa-28.akacast.akamaistream.net/7/88/322045/v1/ibl.akacast.akamaistream.net/voa-28',
    //   stationuuid: 'voa-burmese-mp3',
    //   codec: 'MP3',
    //   votes: 950000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon:
    //       'https://www.radioworld.com/wp-content/uploads/2022/10/voa-logo-5.jpg',
    // ),
    // RadioStation(
    //   name: 'Mizzima TV',
    //   url: 'http://103.215.194.93:8282/hls/mizzimatv/vmix.m3u8',
    //   stationuuid: 'mizzima-tv-hls',
    //   codec: 'HLS',
    //   votes: 900000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon: 'https://mizzima.com/sites/default/files/mizzima-logo.png',
    // ),
    RadioStation(
      name: 'DVB TV',
      url: 'https://live-stream.dvb.no/hls/stream_src/index.m3u8',
      stationuuid: 'dvb-tv-hls',
      codec: 'HLS',
      votes: 850000,
      country: 'Myanmar',
      language: 'Burmese',
      favicon: 'http://dvb.no/wp-content/themes/dvb/images/dvb-logo.png',
    ),
    RadioStation(
      name: 'MRTV News',
      url: 'https://mrtvott.com/cache/MRTV-HD/master.m3u8',
      stationuuid: 'mrtv-news-hls',
      codec: 'HLS',
      votes: 800000,
      country: 'Myanmar',
      language: 'Burmese',
      favicon: 'https://i.imgur.com/uyv7oJH.png',
    ),
    // RadioStation(
    //   name: 'Channel K',
    //   url: 'https://l1-xl1.myanmarnet.com/relay/channelk/ch1/stream.m3u8',
    //   stationuuid: 'channel-k-hls',
    //   codec: 'HLS',
    //   votes: 750000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon: 'https://i.imgur.com/6PqxuhF.png',
    // ),
    // RadioStation(
    //   name: 'MNTV',
    //   url: 'https://l1-xl1.myanmarnet.com/relay/mntv/ch1/stream.m3u8',
    //   stationuuid: 'mntv-hls',
    //   codec: 'HLS',
    //   votes: 700000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon: 'https://i.imgur.com/nssm7QK.png',
    // ),
    RadioStation(
      name: 'Mahar TV',
      url: 'https://tv.mahar.live/mahar/website.stream/playlist.m3u8',
      stationuuid: 'mahar-tv-hls',
      codec: 'HLS',
      votes: 650000,
      country: 'Myanmar',
      language: 'Burmese',
      favicon: 'https://i.imgur.com/ig0QECf.png',
    ),
    // RadioStation(
    //   name: 'Cherry FM',
    //   url: 'https://cherry.akiyaresearch.com:444/stream/89/;',
    //   stationuuid: 'cherry-fm-mp3',
    //   codec: 'MP3',
    //   votes: 600000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon:
    //       'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR005RmEES0rAznIw5lU5Cm7SqhdOKySK5SJg&s',
    // ),
    // RadioStation(
    //   name: 'Mandalay FM',
    //   url: 'https://edge.mixlr.com/channel/nmtev',
    //   stationuuid: 'mandalay-fm-mp3',
    //   codec: 'MP3',
    //   votes: 550000,
    //   country: 'Myanmar',
    //   language: 'Burmese',
    //   favicon:
    //       'https://pyoneplay-library.s3.ap-south-1.amazonaws.com/radios/1687507312CTBVbq.jpeg',
    // ),
  ];

  Future<List<RadioStation>> getStationsByCountry(String country,
      {int limit = 50, int offset = 0}) async {
    final baseUrl =
        'https://de2.api.radio-browser.info/json/stations/bycountry/${Uri.encodeComponent(country.toLowerCase())}?limit=$limit&offset=$offset&order=votes&reverse=true';
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

        for (var s in apiStations) {
          final favicon = _getFavicon(s.name);
          if (favicon != null) {
            s.favicon = favicon;
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
    'padamyar fm':
        'https://images.tuneyou.com/images/logos/500_500/15/13315/PadamyarFM.jpg',
    'mrtv news':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRowreK19orbfPUwxCh4POq3tn2V_IxYFpfg&s',
    'channel k':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSriP_PMbRZ45fiDuy_ItGX6LT1MtCwNczlow&s',
    'mntv':
        'https://yt3.googleusercontent.com/ytc/AIdro_nUKZq06qOOWgMkbJ9ov6cDFEx2g--CekL7SG-jT182Mg=s900-c-k-c0x00ffffff-no-rj',
    'mahar tv':
        'https://images.dwncdn.net/images/t_app-icon-l/p/eb83a46d-d7ed-4ccc-b9c3-5d7ac6522071/2493490419/31711_4-78118578-logo',
    'cherry fm':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR005RmEES0rAznIw5lU5Cm7SqhdOKySK5SJg&s',
    'dwg radio bumese': "https://mytunein.com/images/logos/dwgradioburmese.jpg",
    'mandalayfm':
        'https://pyoneplay-library.s3.ap-south-1.amazonaws.com/radios/1687507312CTBVbq.jpeg',
    'city fm': 'https://i.imgur.com/f0iB1R2.png',
    'shwe fm': 'https://i.imgur.com/83p0pP9.png',
    'bbc burmese': 'https://ichef.bbci.co.uk/images/ic/1920x1080/p0l60nsg.jpg',
    'voa burmese':
        'https://yt3.googleusercontent.com/VanhAeV8j0IjmMVCNyi0W5q6BfLAzgSuH4kSmEAoyjYi--Ky0iat070ZL0y0qaJYKgQ0IiBWyQ=s900-c-k-c0x00ffffff-no-rj',
    'mizzima tv':
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQfG5zJ0LFjq9M3E-7JnUJMkJ5YzZ_gswR9ng&s',
    'dvb tv':
        'https://yt3.googleusercontent.com/0vp8HDvppekF-aoHV821HWViPlVzej0iDd5FQ75_MyTdX8MQaMw84e83EO9HjGyDL6d-5xRbDg=s900-c-k-c0x00ffffff-no-rj',
  };

  String? _getFavicon(String name) {
    final normalizedName = name.trim().toLowerCase();

    if (_customFavicons.containsKey(normalizedName)) {
      return _customFavicons[normalizedName];
    }
    try {
      final hardcoded = _hardcodedPopularMyanmar.firstWhere(
        (s) => s.name.trim().toLowerCase() == normalizedName,
      );
      return hardcoded.favicon;
    } catch (_) {
      return null;
    }
  }
}
