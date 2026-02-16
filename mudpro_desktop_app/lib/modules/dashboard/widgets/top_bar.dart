import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TopHeaderBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo and App Name
          Row(
            children: [
              Icon(Icons.bubble_chart, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "MUDPRO+",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          
          Spacer(),
          
          // Toolbar Icons with animations
          AnimatedToolbarIcons(),
        ],
      ),
    );
  }
}

class AnimatedToolbarIcons extends StatefulWidget {
  @override
  _AnimatedToolbarIconsState createState() => _AnimatedToolbarIconsState();
}

class _AnimatedToolbarIconsState extends State<AnimatedToolbarIcons> {
  int _hoveredIndex = -1;

  Widget _buildToolbarIcon(IconData icon, VoidCallback onPressed, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _hoveredIndex == index 
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
          splashRadius: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildToolbarIcon(Icons.save, () {}, 0),
        _buildToolbarIcon(Icons.print, () {}, 1),
        _buildToolbarIcon(Icons.refresh, () {
          // Add rotation animation
          final animationController = AnimationController(
            duration: Duration(milliseconds: 500),
            vsync: Navigator.of(context),
          );
          final animation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeInOut,
            ),
          );
          animationController.forward().then((_) {
            animationController.dispose();
          });
        }, 2),
        _buildToolbarIcon(Icons.settings, () {}, 3),
        SizedBox(width: 8),
        Container(
          width: 1,
          height: 24,
          color: Colors.white.withOpacity(0.3),
        ),
        SizedBox(width: 12),
        _buildToolbarIcon(Icons.notifications, () {}, 4),
        _buildToolbarIcon(Icons.help_outline, () {}, 5),
      ],
    );
  }
}