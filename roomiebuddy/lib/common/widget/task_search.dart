import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TaskSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final String searchText;

  const TaskSearchBar({
    Key? key,
    required this.onSearch,
    required this.searchText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: 180,
      height: 40,
      decoration: BoxDecoration(
        color: themeProvider.currentInputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.currentBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: themeProvider.currentSecondaryTextColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  hintStyle: TextStyle(
                    color: themeProvider.currentSecondaryTextColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
                style: TextStyle(
                  color: themeProvider.currentTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            if (searchText.isNotEmpty)
              GestureDetector(
                onTap: () => onSearch(''),
                child: Icon(
                  Icons.close,
                  color: themeProvider.currentSecondaryTextColor,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 