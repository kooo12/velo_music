import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/models/radio_station.dart';
import 'package:velo/core/services/network_manager.dart';
import 'package:velo/features/radio/radio_controller.dart';
import 'package:velo/widgets/loading_widget.dart';
import 'package:velo/widgets/no_connection_widget.dart';

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _visualizerController;
  final ScrollController _scrollController = ScrollController();
  final themeCtrl = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    final controller = Get.put(RadioController());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        controller.fetchMoreStations();
      }
    });

    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RadioController>();
    final network = Get.find<NetworkManager>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        controller.isOverlayExpanded.value = false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Obx(() => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: themeCtrl.currentAppTheme.value.gradientColors,
                    ),
                  ),
                )),

            SafeArea(
              bottom: false,
              child: Obx(
                () {
                  final isOffline =
                      network.networkStatus.value == NetworkStatus.disconnected;
                  final hasData = controller.featuredStations.isNotEmpty;

                  if (isOffline && !hasData) {
                    return NoConnectionWidget(
                        onRetry: () =>
                            controller.fetchStations(fromCache: false));
                  }
                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () =>
                            controller.fetchStations(fromCache: false),
                        color: Colors.white,
                        backgroundColor: const Color(0xFF1E1E2E),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(controller),
                              _buildSearchBar(controller),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
                                child: Text(
                                  'FEATURED STATIONS',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildFeaturedList(controller),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(20, 30, 20, 15),
                                child: Text(
                                  'ALL STATIONS',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildStationsGrid(controller),
                              Obx(() {
                                if (controller.isLoadingMore.value) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                        child: LoadingWidget(
                                            color: Colors.white54)),
                                  );
                                }
                                return const SizedBox(height: 50);
                              }),
                            ],
                          ),
                        ),
                      ),
                      if (isOffline)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_off_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 8),
                                Text(
                                  'Offline Mode • No Internet Connection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Player Overlay
            _buildPersistentPlayer(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RadioController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Radio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              Obx(() => Text(
                    'Explore stations in ${controller.selectedCountry.value}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 14),
                  )),
            ],
          ),
          _buildCountryPicker(controller),
        ],
      ),
    );
  }

  Widget _buildCountryPicker(RadioController controller) {
    return InkWell(
      onTap: () => _showCountryBottomSheet(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Obx(() {
          final country = controller.availableCountries
              .firstWhere((c) => c['name'] == controller.selectedCountry.value);
          return Row(
            children: [
              Text(country['flag']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white, size: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar(RadioController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              onTap: () => controller.isOverlayExpanded.value = false,
              onChanged: (v) => controller.setSearchQuery(v),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search Stations...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedList(RadioController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.featuredStations.isEmpty) {
        return _buildFeaturedShimmer();
      }
      if (controller.featuredStations.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: controller.featuredStations.length,
          itemBuilder: (context, index) {
            final station = controller.featuredStations[index];
            return GestureDetector(
              onTap: () =>
                  controller.onStationSelected(index, fromFeatured: true),
              child: Container(
                width: 260,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: station.favicon != null && station.favicon!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(station.favicon!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.4), BlendMode.darken),
                        )
                      : null,
                  color: const Color(0xFF2C2C3E),
                ),
                child: Stack(
                  children: [
                    if (station.favicon == null || station.favicon!.isEmpty)
                      const Center(
                          child: Icon(Icons.radio,
                              color: Colors.white12, size: 60)),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.transparent
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              station.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  '${station.votes ?? 0} votes',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 10),
                                ),
                                const Spacer(),
                                Text(
                                  station.tags?.split(',').first ?? 'Radio',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildStationsGrid(RadioController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.stations.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemBuilder: (context, index) => _buildGridShimmer(),
          ),
        );
      }

      if (controller.filteredStations.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('No results for your search',
                style: TextStyle(color: Colors.white54)),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredStations.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemBuilder: (context, index) {
          final station = controller.filteredStations[index];
          return GestureDetector(
            onTap: () => controller.onStationSelected(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child:
                          station.favicon != null && station.favicon!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: station.favicon!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      _buildGridPlaceholder(),
                                )
                              : _buildGridPlaceholder(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          station.language ?? 'Unknown',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildPersistentPlayer(RadioController controller) {
    return Obx(() {
      if (!controller.isOverlayVisible.value) return const SizedBox.shrink();

      final isExpanded = controller.isOverlayExpanded.value;
      final station = controller.stations[controller.currentIndex.value];

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        bottom: isExpanded ? 0 : 20,
        left: isExpanded ? 0 : 20,
        right: isExpanded ? 0 : 20,
        height: isExpanded ? MediaQuery.of(context).size.height * 0.75 : 75,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! > 10 && isExpanded) {
              controller.isOverlayExpanded.value = false;
            } else if (details.primaryDelta! < -10 && !isExpanded) {
              controller.isOverlayExpanded.value = true;
            }
          },
          onTap: () {
            if (!isExpanded) controller.isOverlayExpanded.value = true;
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 4, vertical: isExpanded ? 10 : 0),
            child: Container(
              decoration: BoxDecoration(
                color: themeCtrl.currentAppTheme.value.gradientColors.last
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(isExpanded ? 40 : 20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isExpanded ? 40 : 20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: isExpanded
                      ? _buildExpandedOverlay(controller, station)
                      : _buildMiniOverlay(controller, station),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMiniOverlay(RadioController controller, RadioStation station) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Hero(
            tag: 'station_art',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: station.favicon != null && station.favicon!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: station.favicon!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.radio,
                            color: Colors.white24, size: 25),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.white10,
                      child: const Icon(Icons.radio, color: Colors.white38),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
                Text(
                  'Now Playing...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              controller.isPlaying.value
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => controller.togglePlay(),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.white38, size: 24),
            onPressed: () => controller.stop(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedOverlay(
      RadioController controller, RadioStation station) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          Hero(
            tag: 'station_art',
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: station.favicon != null && station.favicon!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: station.favicon!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(Icons.radio,
                              color: Colors.white24, size: 80),
                        ),
                      )
                    : Container(
                        color: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.radio,
                            color: Colors.white24, size: 80),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            station.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            station.tags?.split(',').first.toUpperCase() ?? 'GLOBAL RADIO',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 30),
          _buildWaveform(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => controller.prevStation(),
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Colors.white, size: 40),
                ),
                GestureDetector(
                  onTap: () => controller.togglePlay(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: themeCtrl.currentAppTheme.value.gradientColors,
                      ),
                    ),
                    child: Icon(
                      controller.isPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.nextStation(),
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Colors.white, size: 40),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Obx(() {
      final isPlaying = Get.find<RadioController>().isPlaying.value;
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(25, (index) {
            return AnimatedBuilder(
              animation: _visualizerController,
              builder: (context, child) {
                double heightFactor = 0.1;
                if (isPlaying) {
                  heightFactor = (0.2 +
                          math
                                  .sin(_visualizerController.value *
                                          2 *
                                          math.pi +
                                      index)
                                  .abs() *
                              0.8)
                      .clamp(0.1, 1.0);
                }
                return Container(
                  width: 4,
                  height: 10 + heightFactor * 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isPlaying ? 0.7 : 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            );
          }),
        ),
      );
    });
  }

  Widget _buildFeaturedShimmer() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 260,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildGridPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.02),
      child: const Center(
        child: Icon(Icons.radio, color: Colors.white10, size: 40),
      ),
    );
  }

  Widget _buildGridShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _showCountryBottomSheet(RadioController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Region',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...controller.availableCountries.map((country) {
              return ListTile(
                leading: Text(country['flag']!,
                    style: const TextStyle(fontSize: 24)),
                title: Text(country['name']!,
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  controller.changeCountry(country['name']!);
                  Get.closeAllBottomSheets();
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
