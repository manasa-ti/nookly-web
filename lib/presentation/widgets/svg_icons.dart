import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcons {
  static Widget discoverIcon({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/discover.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget likesIcon({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/likes.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget chatsIcon({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/chats.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget premiumIcon({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/premium.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  static Widget profileIcon({double size = 24, Color? color}) {
    return SvgPicture.asset(
      'assets/icons/profile.svg',
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
} 