import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Animated loading indicator using Lottie
class AppLoader extends StatelessWidget {
  final double size;

  const AppLoader({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/loading.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

/// Full screen loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(size: 80),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success animation widget
class AppSuccessAnimation extends StatelessWidget {
  final double size;
  final VoidCallback? onComplete;

  const AppSuccessAnimation({
    super.key,
    this.size = 100,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/success.json',
        fit: BoxFit.contain,
        repeat: false,
        onLoaded: (composition) {
          if (onComplete != null) {
            Future.delayed(composition.duration, onComplete);
          }
        },
      ),
    );
  }
}

/// Empty state animation widget
class AppEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final double size;

  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            'assets/animations/empty.json',
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Upload progress animation
class AppUploadAnimation extends StatelessWidget {
  final double size;

  const AppUploadAnimation({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/upload.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
