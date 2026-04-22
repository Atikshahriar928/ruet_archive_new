import 'dart:convert';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String placeholder;
  final TextEditingController controller;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.placeholder,
    required this.controller,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AppImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const AppImage({
    super.key,
    this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image,
  });

  @override
  Widget build(BuildContext context) {
    if (source == null || source!.isEmpty) {
      return _placeholder();
    }

    try {
      if (source!.startsWith('http') || source!.startsWith('https')) {
        return Image.network(
          source!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      } else {
        // Handle Base64
        final String base64Data = source!.contains(',') ? source!.split(',').last : source!;
        return Image.memory(
          base64Decode(base64Data),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      }
    } catch (e) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1C1C1C),
      child: Icon(placeholderIcon, color: const Color(0xFF71717A), size: 32),
    );
  }
}

class ProfileImage extends StatelessWidget {
  final String? imageSource;
  final double size;
  final double borderRadius;

  const ProfileImage({
    super.key,
    this.imageSource,
    this.size = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AppImage(
        source: imageSource,
        width: size,
        height: size,
        placeholderIcon: Icons.person,
      ),
    );
  }
}
