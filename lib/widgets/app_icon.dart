import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tseretnip/theme/app_colors.dart';

/// Centralized SVG icon widget with theme support
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final bool filled;

  const AppIcon({
    super.key,
    required this.name,
    this.size = 24,
    this.color,
    this.filled = false,
  });

  // Static icon names for autocomplete
  static const String home = 'home';
  static const String homeFilled = 'home_filled';
  static const String camera = 'camera';
  static const String heart = 'heart';
  static const String heartFilled = 'heart_filled';
  static const String user = 'user';
  static const String userFilled = 'user_filled';
  static const String image = 'image';
  static const String grid = 'grid';
  static const String plus = 'plus';
  static const String close = 'close';
  static const String arrowLeft = 'arrow_left';
  static const String arrowRight = 'arrow_right';
  static const String check = 'check';
  static const String edit = 'edit';
  static const String trash = 'trash';
  static const String logout = 'logout';
  static const String settings = 'settings';
  static const String sun = 'sun';
  static const String moon = 'moon';
  static const String refresh = 'refresh';
  static const String reload = 'reload';
  static const String smile = 'smile';
  static const String upload = 'upload';
  static const String clock = 'clock';
  static const String info = 'info';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark 
        ? AppColors.textPrimaryDark 
        : AppColors.textPrimaryLight;
    
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? defaultColor,
        BlendMode.srcIn,
      ),
    );
  }
}

/// Animated icon button with scale effect
class AnimatedIconButton extends StatefulWidget {
  final String iconName;
  final String? activeIconName;
  final bool isActive;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final Color? activeColor;

  const AnimatedIconButton({
    super.key,
    required this.iconName,
    this.activeIconName,
    this.isActive = false,
    required this.onTap,
    this.size = 24,
    this.color,
    this.activeColor,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final iconName = widget.isActive && widget.activeIconName != null
        ? widget.activeIconName!
        : widget.iconName;
    
    final color = widget.isActive
        ? (widget.activeColor ?? AppColors.primary)
        : widget.color;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AppIcon(
              name: iconName,
              size: widget.size,
              color: color,
            ),
          );
        },
      ),
    );
  }
}
