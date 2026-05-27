import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

class NovaImage extends StatelessWidget {
  const NovaImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.error,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    if (value.startsWith('data:image/')) {
      final comma = value.indexOf(',');
      if (comma != -1) {
        try {
          final bytes = base64Decode(value.substring(comma + 1));
          return Image.memory(bytes, fit: fit, width: width, height: height);
        } catch (_) {
          return error ?? const _ImageFallback();
        }
      }
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) =>
            placeholder ?? const ColoredBox(color: AppColors.butter),
        errorWidget: (_, __, ___) => error ?? const _ImageFallback(),
      );
    }
    return error ?? const _ImageFallback();
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.butter,
      child: Icon(Icons.image_outlined),
    );
  }
}
