import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandableFab extends StatefulWidget {
  final List<FabMenuItem> items;
  final Color? backgroundColor;

  const ExpandableFab({
    Key? key,
    required this.items,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Overlay to close menu when tapped outside
        if (_isExpanded)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        // Menu items
        ...widget.items.asMap().entries.map((entry) {
          int index = entry.key;
          FabMenuItem item = entry.value;

          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              double offset = (index + 1) * 70.0;
              return Transform.translate(
                offset: Offset(0, -offset * _expandAnimation.value),
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isExpanded && _expandAnimation.value > 0.7)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: item.color ?? const Color(0xFFFFA500),
                          onPressed: () {
                            _toggle();
                            item.onPressed();
                          },
                          child: Icon(item.icon, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
        // Main FAB
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) => Transform.rotate(
            angle: _expandAnimation.value * math.pi / 4,
            child: FloatingActionButton(
              backgroundColor: widget.backgroundColor ?? const Color(0xFFFFA500),
              onPressed: _toggle,
              child: Icon(
                _isExpanded ? Icons.close : Icons.add,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FabMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  FabMenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });
}