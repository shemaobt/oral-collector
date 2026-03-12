import 'package:flutter/material.dart';

class LoginMobileHero extends StatelessWidget {
  const LoginMobileHero({
    super.key,
    required this.screenHeight,
    required this.topPadding,
    required this.theme,
  });

  final double screenHeight;
  final double topPadding;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: screenHeight * 0.48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            child: Image.asset('assets/hero_heart.png', fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: topPadding + 16,
            left: 24,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 32,
                    height: 32,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Oral Collector',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 28,
            right: 28,
            bottom: 32,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Welcome\n',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  TextSpan(
                    text: 'Back',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: const Color(0xFFFFB380),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
