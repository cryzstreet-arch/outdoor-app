import 'package:flutter/material.dart';
import '../config/constants.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget appBar = AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.oscuro,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      iconTheme: IconThemeData(color: AppColors.oscuro),
    );

    return Container(
      color: AppColors.isDark
          ? const Color.fromRGBO(20, 20, 30, 0.75)
          : Color.fromRGBO(232, 220, 200, 0.75),
      child: SafeArea(bottom: false, child: appBar),
    );
  }
}
