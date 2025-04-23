import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../providers/theme_provider.dart';

class RoommateGroupCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> roommateGroups;
  final Function(Map<String, dynamic>)? onGroupTap;
  final Function(Map<String, dynamic>)? onGroupSelected;

  const RoommateGroupCarousel({
    super.key,
    required this.roommateGroups,
    this.onGroupTap,
    this.onGroupSelected,
  });

  @override
  State<RoommateGroupCarousel> createState() => _RoommateGroupCarouselState();
}

class _RoommateGroupCarouselState extends State<RoommateGroupCarousel> {
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Trigger the callback for the initial selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onGroupSelected != null && 
          widget.roommateGroups.isNotEmpty) {
        widget.onGroupSelected!(widget.roommateGroups[_currentCarouselIndex]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: _buildGroupCarousel(),
    );
  }

  Widget _buildGroupCarousel() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return CarouselSlider(
      options: CarouselOptions(
        height: 140.0,
        enlargeCenterPage: true,
        autoPlay: false,
        viewportFraction: 0.8,
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
          
          // Notify the parent widget about the group selection change
          if (widget.onGroupSelected != null && widget.roommateGroups.isNotEmpty) {
            widget.onGroupSelected!(widget.roommateGroups[index]);
          }
        },
      ),
      items: widget.roommateGroups.asMap().entries.map((entry) {
        final int index = entry.key;
        final group = entry.value;
        
        return Builder(
          builder: (BuildContext context) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _currentCarouselIndex == index ? 1.0 : 0.6,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.currentCardBackground,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: themeProvider.themeColor),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode 
                          ? Colors.black12 
                          : Colors.black12,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['groupName'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.currentTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.currentSecondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: themeProvider.themeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group['memberCount'] == 1 
                            ? "Just you" 
                            : "${group['memberCount']} members",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: themeProvider.currentSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
} 