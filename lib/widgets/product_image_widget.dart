import 'dart:convert';
import 'package:flutter/material.dart';

/// Displays a product image.
///
/// Supports two formats transparently, so existing documents created before
/// the Firebase Storage migration keep working without a data backfill:
///   - New format: `image` is an https:// download URL (Firebase Storage)
///   - Legacy format: `image` is a base64-encoded string (pre-migration)
///
/// Falls back to the default inventory icon if no image is available or if
/// loading/decoding fails.
class ProductImage extends StatelessWidget {
  final String? image;
  final double size;
  final double borderRadius;

  const ProductImage({
    super.key,
    required this.image,
    this.size = 64,
    this.borderRadius = 12,
  });

  bool get _isNetworkUrl =>
      image != null && (image!.startsWith('http://') || image!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return _placeholder();
    }

    if (_isNetworkUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          image!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey.shade100,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }

    // Legacy base64 fallback
    try {
      final bytes = base64Decode(image!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFDEECFF),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF2563EB),
        size: 28,
      ),
    );
  }
}
