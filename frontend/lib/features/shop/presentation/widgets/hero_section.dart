import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onShopPressed});

  final VoidCallback onShopPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 760;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isDesktop ? 610 : 570),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB7D7FF), Color(0xFF8EBCEB), Color(0xFF527FB5)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: isDesktop ? 70 : 55,
            child: Container(
              width: isDesktop ? 480 : 320,
              height: isDesktop ? 480 : 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    const Color(0xFFCCEAFF).withValues(alpha: 0.70),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.75),
                    blurRadius: 90,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: isDesktop ? 85 : 80,
            child: _DeviceArtwork(isDesktop: isDesktop),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: isDesktop ? 48 : 34,
            child: Column(
              children: [
                Text(
                  'Công nghệ. Tỏa sáng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 56 : 36,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  'Khám phá iPhone, Samsung, MacBook và thiết bị '
                  'công nghệ mới nhất.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 21 : 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 23),
                FilledButton(
                  key: const Key('hero-shop-button'),
                  onPressed: onShopPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Mua ngay',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceArtwork extends StatelessWidget {
  const _DeviceArtwork({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final phoneWidth = isDesktop ? 150.0 : 105.0;
    final phoneHeight = isDesktop ? 305.0 : 215.0;

    return SizedBox(
      width: isDesktop ? 510 : 340,
      height: isDesktop ? 350 : 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(isDesktop ? -120 : -82, isDesktop ? 20 : 15),
            child: Transform.rotate(
              angle: -0.12,
              child: _PhoneMockup(
                width: phoneWidth,
                height: phoneHeight,
                colors: const [Color(0xFF121212), Color(0xFF48576A)],
              ),
            ),
          ),

          Transform.translate(
            offset: Offset(isDesktop ? 120 : 82, isDesktop ? 20 : 15),
            child: Transform.rotate(
              angle: 0.12,
              child: _PhoneMockup(
                width: phoneWidth,
                height: phoneHeight,
                colors: const [Color(0xFF15233F), Color(0xFF4A8CCB)],
              ),
            ),
          ),

          _PhoneMockup(
            width: phoneWidth,
            height: phoneHeight,
            colors: const [
              Color(0xFFD7E9FF),
              Color(0xFF456EAE),
              Color(0xFF15284A),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({
    required this.width,
    required this.height,
    required this.colors,
  });

  final double width;
  final double height;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(width * 0.20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 25,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.65),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.16),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 8,
              child: Container(
                width: width * 0.35,
                height: width * 0.10,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            Center(
              child: Icon(
                Icons.bolt_rounded,
                color: Colors.white.withValues(alpha: 0.82),
                size: width * 0.38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
