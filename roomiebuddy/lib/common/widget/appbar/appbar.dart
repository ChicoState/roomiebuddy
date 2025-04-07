import 'package:flutter/material.dart';
import 'package:get/get.dart';

double getAppBarHeight() {
  return kToolbarHeight;
}

class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar({
    super.key,
    this.title,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.showBackArrow = false,
  });

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackArrow
          ? IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back))
          : leadingIcon != null
              ? IconButton(onPressed: leadingOnPressed, icon: Icon(leadingIcon))
              : null,
      title: title != null
          ? FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: title!,
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}