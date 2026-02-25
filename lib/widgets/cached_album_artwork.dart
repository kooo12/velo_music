import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sonus/core/constants/app_colors.dart';
import 'package:sonus/features/home/home_controller.dart';

class CachedAlbumArtwork extends StatefulWidget {
  final int songId;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool highQuality;
  final BoxFit fit;

  const CachedAlbumArtwork({
    super.key,
    required this.songId,
    this.width,
    this.height,
    this.borderRadius = 15,
    this.highQuality = false,
    this.fit = BoxFit.cover,
  });

  @override
  State<CachedAlbumArtwork> createState() => _CachedAlbumArtworkState();
}

class _CachedAlbumArtworkState extends State<CachedAlbumArtwork> {
  Uint8List? _cachedImage;
  bool _isLoading = true;
  String? _artworkUrl;

  static const int _listImageSize = 120;
  static const int _highQualitySize = 1280;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedAlbumArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _cachedImage = null;
      _isLoading = true;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    try {
      final controller = Get.find<HomeController>();

      final artworkUrl = controller.getArtworkUrl(widget.songId);

      if (artworkUrl != null) {
        if (mounted) {
          setState(() {
            _artworkUrl = artworkUrl;
            _isLoading = false;
          });
        }
        return;
      }

      final artwork = await controller.getAlbumArtwork(
        widget.songId,
        highQuality: widget.highQuality,
      );

      if (mounted && artwork != null) {
        setState(() {
          _cachedImage = artwork;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [AppColors.musicPrimary, AppColors.musicSecondary],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 35,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || (_cachedImage == null && _artworkUrl == null)) {
      return _buildPlaceholder();
    }

    if (_artworkUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CachedNetworkImage(
          imageUrl: _artworkUrl!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          memCacheWidth: widget.highQuality ? _highQualitySize : _listImageSize,
          memCacheHeight:
              widget.highQuality ? _highQualitySize : _listImageSize,
          filterQuality: FilterQuality.low,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }

    if (_cachedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.memory(
          _cachedImage!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: widget.highQuality ? _highQualitySize : _listImageSize,
          cacheHeight: widget.highQuality ? _highQualitySize : _listImageSize,
          filterQuality: FilterQuality.low,
        ),
      );
    }

    return _buildPlaceholder();
  }
}
