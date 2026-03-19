import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:velo/core/controllers/theme_controller.dart';
import 'package:velo/core/models/radio_station.dart';
import 'package:velo/features/radio/radio_controller.dart';
import 'package:velo/widgets/loading_widget.dart';

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _visualizerController;
  final double _viewportFraction = 0.7;
  double _pageOffset = 0.0;

  final themeCtrl = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction)
      ..addListener(() {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
        });
      });

    final controller = Get.find<RadioController>();
    ever(controller.currentIndex, (int index) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RadioController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Radio'.tr,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.normal),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            final selectedCountry = controller.selectedCountry.value;
            final map = controller.availableCountries.firstWhere(
                (c) => c['name'] == selectedCountry,
                orElse: () => controller.availableCountries.first);
            final flag = map['flag'];
            return PopupMenuButton<String>(
              icon: Text(
                flag ?? '🌎',
                style: const TextStyle(fontSize: 24),
              ),
              color: const Color(0xFF2C2C3E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (String countryName) {
                controller.changeCountry(countryName);
              },
              itemBuilder: (BuildContext context) {
                return controller.availableCountries.map((countryMap) {
                  return PopupMenuItem<String>(
                    value: countryMap['name'],
                    child: Row(
                      children: [
                        Text(
                          countryMap['flag'] ?? '🌎',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          countryMap['name'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            );
          }),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: themeCtrl.currentAppTheme.value.gradientColors,
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: LoadingWidget(color: Colors.white));
            }

            if (controller.stations.isEmpty) {
              return const Center(
                  child: Text('No stations found',
                      style: TextStyle(color: Colors.white70)));
            }

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 100),
                      SizedBox(
                        height: 350,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) =>
                              controller.onStationSwiped(index),
                          itemCount: controller.stations.length,
                          itemBuilder: (context, index) {
                            double scale =
                                (1 - (_pageOffset - index).abs() * 0.2)
                                    .clamp(0.8, 1.0);
                            double angle = (_pageOffset - index) * 0.3;

                            final station = controller.stations[index];

                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle)
                                ..scale(scale),
                              alignment: Alignment.center,
                              child: _buildStationCard(station),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      Obx(() {
                        final station =
                            controller.stations[controller.currentIndex.value];
                        return Column(
                          children: [
                            Text(
                              station.tags?.isNotEmpty == true
                                  ? station.tags!
                                      .split(',')
                                      .first
                                      .trim()
                                      .toUpperCase()
                                  : 'RADIO',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                station.name.trim(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStationDetails(station),
                          ],
                        );
                      }),
                      const Spacer(),
                      _buildVisualizer(),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => controller.prevStation(),
                              icon: const Icon(Icons.skip_previous_rounded,
                                  color: Colors.white, size: 40),
                            ),
                            const SizedBox(width: 30),
                            Obx(() => GestureDetector(
                                  onTap: () => controller.togglePlay(),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: themeCtrl.currentAppTheme.value
                                            .gradientColors,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF9D6C)
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      controller.isPlaying.value
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                )),
                            const SizedBox(width: 30),
                            IconButton(
                              onPressed: () => controller.nextStation(),
                              icon: const Icon(Icons.skip_next_rounded,
                                  color: Colors.white, size: 40),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStationCard(RadioStation station) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: station.favicon != null && station.favicon!.isNotEmpty
            ? Container(
                color: const Color(0xFF2C2C3E),
                child: CachedNetworkImage(
                  imageUrl: station.favicon!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildDefaultArtwork(),
                  errorWidget: (context, url, error) => _buildDefaultArtwork(),
                ),
              )
            : _buildDefaultArtwork(),
      ),
    );
  }

  Widget _buildDefaultArtwork() {
    return Container(
      color: const Color(0xFF2C2C3E),
      child: const Center(
        child: Icon(Icons.radio, color: Colors.white24, size: 80),
      ),
    );
  }

  Widget _buildStationDetails(RadioStation station) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Wrap(
        spacing: 15,
        runSpacing: 5,
        alignment: WrapAlignment.center,
        children: [
          if (station.bitrate != null && station.bitrate! > 0)
            _buildDetailItem(Icons.speed, '${station.bitrate} kbps'),
          _buildDetailItem(
              Icons.settings_input_component, station.codec ?? 'MP3'),
          station.language != null && station.language!.isNotEmpty
              ? _buildDetailItem(Icons.language, station.language ?? 'Unknown')
              : const SizedBox.shrink(),
          _buildDetailItem(Icons.public, station.country ?? 'Myanmar'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildVisualizer() {
    final controller = Get.find<RadioController>();

    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(35, (index) {
            return AnimatedBuilder(
              animation: _visualizerController,
              builder: (context, child) {
                double heightFactor = 0.0;
                if (isPlaying) {
                  final wave1 = math.sin(
                          _visualizerController.value * 2 * math.pi +
                              index * 0.8) *
                      0.3;
                  final wave2 = math.cos(
                          _visualizerController.value * 4 * math.pi +
                              index * 0.4) *
                      0.2;
                  final wave3 = math.cos(
                          _visualizerController.value * 6 * math.pi +
                              index * 0.2) *
                      0.2;
                  heightFactor = (0.3 + wave1.abs() + wave2.abs() + wave3.abs())
                      .clamp(0.1, 1.0);
                } else {
                  heightFactor = 0.1;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3,
                  height: 10 + heightFactor * 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isPlaying ? 0.6 : 0.2),
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(isPlaying ? 0.8 : 0.3),
                        Colors.white.withOpacity(isPlaying ? 0.2 : 0.1),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      );
    });
  }
}
