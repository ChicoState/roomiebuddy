import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

//To reuse this container for future refrence
class TCircularContainer extends StatelessWidget {
  const TCircularContainer({
    super.key,
    this.child,
    this.width = 400,
    this.height = 400,
    this.radius = 200, // Half of width/height for a circle
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsets padding;
  final Widget? child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = backgroundColor ?? themeProvider.currentBackground;
    
    return Padding(
      padding: padding,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: bgColor, // Use the passed background color or fallback to theme
        ),
        child: child,
      ),
    );
  }
}
