import 'dart:convert';
import 'package:flutter/material.dart';

/// Displays a product image from a base64-encoded string stored in Firestore.
/// Falls back to the default inventory icon if no image is available or if
/// decoding fails — this handles gracefully cases where the photo was not
/// captured when the product was added.
class ProductImage extends StatelessWidget {
  final String? imageBase64;
  final double size;
  final double borderRadius;

  const ProductImage({
    super.key,
    required this.imageBase64,
    this.size = 64,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64!);
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
    return _placeholder();
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
