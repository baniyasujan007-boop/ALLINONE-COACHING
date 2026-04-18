import 'package:flutter/material.dart';

import '../models/app_user.dart';

class UserAvatarButton extends StatelessWidget {
  const UserAvatarButton({required this.user, required this.onTap, super.key});

  final AppUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String imageUrl = user?.profileImage.trim() ?? '';
    final bool hasValidImage = _isValidUrl(imageUrl);
    final String initials = _initialsFor(user?.name ?? '');

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage: hasValidImage ? NetworkImage(imageUrl) : null,
          child: hasValidImage
              ? null
              : Text(
                  initials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
        ),
      ),
    );
  }

  bool _isValidUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  String _initialsFor(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
