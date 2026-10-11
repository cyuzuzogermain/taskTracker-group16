import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';

/// A round avatar showing a team member's initials.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.size = 40});

  final TeamMember member;

  /// The avatar's width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryTint,
      child: Text(
        member.initials,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          // The letters scale with the avatar.
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
