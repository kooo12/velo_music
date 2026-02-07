import 'package:get/get.dart';
import 'package:sonus/core/bindings/home_binding.dart';
import 'package:sonus/core/bindings/splash_binding.dart';
import 'package:sonus/features/notifications/notification_request_page.dart';
import 'package:sonus/core/models/playlist_model.dart';
import 'package:sonus/core/models/song_model.dart';
import 'package:sonus/features/home/home.dart';
import 'package:sonus/features/home/home_controller.dart';
import 'package:sonus/features/notifications/notification_settings_page.dart';
import 'package:sonus/features/splash/splash.dart';
import 'package:sonus/features/sub_screens/library_screen/add_songs_to_playlist_screen.dart';
import 'package:sonus/features/sub_screens/library_screen/album_songs_screen.dart';
import 'package:sonus/features/sub_screens/library_screen/artist_songs_screen.dart';
import 'package:sonus/features/sub_screens/library_screen/playlist_songs_screen.dart';
import 'package:sonus/routhing/app_routes.dart';
import 'package:sonus/features/sub_screens/player_screens/full_screen_player.dart';
import 'package:sonus/features/sub_screens/player_screens/full_screen_player_landscape.dart';
import 'package:sonus/features/queue/queue_page.dart';

import '../core/bindings/queue_binding.dart';

class AppPages {
  static final pages = [
    GetPage(
        name: Routes.SPLASH,
        page: () => const SplashScreen(),
        binding: SplashBinding()),
    GetPage(
        name: Routes.HOME,
        page: () => const HomeScreen(),
        binding: HomeBinding()),

// Players -----------------------
    GetPage(
      name: Routes.FULLSCREENPLAYER,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final controller = args['controller'] as HomeController;
        return FullScreenPlayer(controller: controller);
      },
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.FULLSCREENPLAYERLANDSCAPE,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final controller = args['controller'] as HomeController;
        return FullScreenPlayerLandscape(controller: controller);
      },
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.QUEUE,
      page: () => const QueuePage(),
      binding: QueueBinding(),
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),

    GetPage(
      name: Routes.ARTISTSONGSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;

        return ArtistSongsScreen(
          artist: args['artist'] as String,
          songs: args['songs'] as List<SongModel>,
          controller: args['controller'] as HomeController,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.ALBUMSONGSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;

        return AlbumSongsScreen(
          album: args['album'] as String,
          songs: args['songs'] as List<SongModel>,
          controller: args['controller'] as HomeController,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.PLAYLISTSONGSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return PlaylistSongsScreen(
          playlist: args['playlist'] as PlaylistModel,
          songs: args['playlistSongs'] as List<SongModel>,
          controller: args['controller'] as HomeController,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.ADDSONGTOPLAYLISTSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final playlist = args['playlist'] as PlaylistModel;
        final controller = args['controller'] as HomeController;
        return AddSongsToPlaylistScreen(
          playlist: playlist,
          controller: controller,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.NOTIFICATIONSREQUESTPAGE,
      page: () => const NotificationRequestPage(),
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
        name: Routes.NOTIFICATIONSETTINGS,
        page: () => NotificationSettingsPage(),
        transition: Transition.rightToLeft),
  ];
}
