import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../containers/curved_edges/curved_edges_widgets.dart';
import '../providers/theme_provider.dart';
import 'circular_container.dart';

class TPrimaryHeaderContainer extends StatelessWidget {
  const TPrimaryHeaderContainer({
    super.key, required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return TCurvedEdgeWidget(
      child: Container(
        color: themeProvider.primaryHeaderColor,
        padding: const EdgeInsets.all(0),
        child: SizedBox(
          height: 400,
          child: Stack(
            children: [
              Positioned(top: -150, right: -250, child: TCircularContainer(backgroundColor: themeProvider.primaryHeaderOverlayColor)),
              Positioned(top: 100, right: -300, child: TCircularContainer(backgroundColor: themeProvider.primaryHeaderOverlayColor)),
            ],
          ),
        ),
      ),
    );
  }
}

