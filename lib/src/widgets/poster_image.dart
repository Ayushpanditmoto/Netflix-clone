import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PosterImage extends StatelessWidget {
  const PosterImage({
    required this.imageUrl,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? imageUrl;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF222222)),
        child: imageUrl == null
            ? const Center(
                child: Icon(
                  Icons.movie_creation_outlined,
                  color: Colors.white38,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: fit,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                  ),
                ),
              ),
      ),
    );
  }
}
