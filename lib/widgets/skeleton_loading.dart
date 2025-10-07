import 'package:flutter/material.dart';

/// Skeleton loading animation widget for smoother loading states
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading for student cards (matches fritids/teacher card dimensions)
class SkeletonStudentCard extends StatelessWidget {
  const SkeletonStudentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double maxCardWidth = 170.0;
    final cardWidth = screenWidth * 0.30 < maxCardWidth
        ? screenWidth * 0.30
        : maxCardWidth;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.01 < 10 ? screenWidth * 0.01 : 10,
        vertical: 10,
      ),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile image skeleton
                SkeletonLoader(
                  width: cardWidth * 0.5,
                  height: cardWidth * 0.5,
                  borderRadius: BorderRadius.circular(cardWidth * 0.25),
                ),
                const SizedBox(height: 10),
                // Name skeleton
                SkeletonLoader(
                  width: cardWidth * 0.7,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                // Badge skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonLoader(
                      width: 40,
                      height: 20,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 4),
                    SkeletonLoader(
                      width: 40,
                      height: 20,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading for history list items
class SkeletonHistoryItem extends StatelessWidget {
  const SkeletonHistoryItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon skeleton
            const SkeletonLoader(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            const SizedBox(width: 16),
            // Text content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: 150,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Trailing skeleton
            SkeletonLoader(
              width: 60,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading for search results
class SkeletonSearchItem extends StatelessWidget {
  const SkeletonSearchItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonLoader(
        width: 50,
        height: 50,
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      title: SkeletonLoader(
        width: double.infinity,
        height: 16,
        borderRadius: BorderRadius.circular(4),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SkeletonLoader(
          width: 100,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
