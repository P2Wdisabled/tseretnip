import 'package:flutter/material.dart';
import 'package:tseretnip/theme/app_colors.dart';
import 'package:tseretnip/theme/app_theme.dart';
import 'package:tseretnip/widgets/app_icon.dart';

/// Custom bottom navigation bar with glassmorphism effect
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: AppColors.navBarGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                iconName: AppIcon.home,
                activeIconName: AppIcon.homeFilled,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavBarItem(
                iconName: AppIcon.camera,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
                isCenter: true,
              ),
              _NavBarItem(
                iconName: AppIcon.heart,
                activeIconName: AppIcon.heartFilled,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavBarItem(
                iconName: AppIcon.user,
                activeIconName: AppIcon.userFilled,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final String iconName;
  final String? activeIconName;
  final bool isActive;
  final VoidCallback onTap;
  final bool isCenter;

  const _NavBarItem({
    required this.iconName,
    this.activeIconName,
    required this.isActive,
    required this.onTap,
    this.isCenter = false,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
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

    final iconColor = widget.isActive
        ? AppColors.primary
        : Colors.white.withOpacity(0.7);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: AppTheme.animationFast,
              padding: EdgeInsets.all(widget.isCenter ? 12 : 8),
              decoration: widget.isCenter
                  ? BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: AppIcon(
                name: iconName,
                size: widget.isCenter ? 28 : 24,
                color: widget.isCenter ? Colors.white : iconColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
