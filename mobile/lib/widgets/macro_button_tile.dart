import 'package:flutter/material.dart';
import '../models/deck_profile.dart';
import '../models/icon_helper.dart';

class MacroButtonTile extends StatefulWidget {
  final MacroButton button;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MacroButtonTile({
    super.key,
    required this.button,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MacroButtonTile> createState() => _MacroButtonTileState();
}

class _MacroButtonTileState extends State<MacroButtonTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = Color(widget.button.colorValue);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF19212D), // Stream Deck key surface
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: buttonColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconHelper.getIcon(widget.button.iconName),
                  size: 28,
                  color: buttonColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.button.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE2E8F0),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
