import 'package:flutter/material.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';

/// Network avatar with an initial-letter fallback, used for podium slots and
/// list rows alike. Unlike [ProfileAvatarCircle], this renders any entry's
/// [url] rather than the signed-in user's own photo notifiers.
class LeaderboardAvatar extends StatelessWidget {
  const LeaderboardAvatar({
    super.key,
    required this.url,
    required this.fallbackName,
  });

  final String? url;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) return _initialCircle(context);
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _initialCircle(context),
    );
  }

  Widget _initialCircle(BuildContext context) {
    final trimmedName = fallbackName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';
    return Container(
      color: context.surfaceColor(const Color(0xFFCFCFEA)),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: context.inkColor(const Color(0xFF5B5B8C)),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
