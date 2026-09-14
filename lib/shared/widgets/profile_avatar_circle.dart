import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:islami_app_noorify/shared/services/app_globals.dart';

/// Circular avatar that reflects the signed-in user's photo everywhere it's
/// shown (home header, profile screen, edit-profile screen): a locally
/// picked custom photo ([profilePhotoBase64Notifier]) takes priority,
/// otherwise the REST profile's `avatarUrl` ([profilePhotoUrlNotifier]) is
/// shown, falling back to a person icon when neither is set or the network
/// image fails to load.
class ProfileAvatarCircle extends StatelessWidget {
  const ProfileAvatarCircle({
    super.key,
    required this.dimension,
    this.backgroundColor = const Color(0xFFB9C36E),
    this.placeholderIconColor = Colors.white,
  });

  final double dimension;
  final Color backgroundColor;
  final Color placeholderIconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        profilePhotoBase64Notifier,
        profilePhotoUrlNotifier,
      ]),
      builder: (context, _) {
        final placeholder = Icon(
          Icons.person_rounded,
          size: dimension * .5,
          color: placeholderIconColor,
        );

        ImageProvider? provider;
        final base64Photo = profilePhotoBase64Notifier.value;
        if (base64Photo != null && base64Photo.isNotEmpty) {
          try {
            provider = MemoryImage(base64Decode(base64Photo));
          } catch (_) {
            provider = null;
          }
        }
        final photoUrl = profilePhotoUrlNotifier.value;
        if (provider == null && photoUrl != null && photoUrl.isNotEmpty) {
          provider = NetworkImage(photoUrl);
        }

        return Container(
          width: dimension,
          height: dimension,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: provider == null
              ? placeholder
              : Image(
                  image: provider,
                  width: dimension,
                  height: dimension,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => placeholder,
                ),
        );
      },
    );
  }
}
