import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';

class ModernScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool showGlows;
  final PreferredSizeWidget? bottom;

  const ModernScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
    this.showGlows = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title != null || bottom != null
          ? AppBar(
              title: title != null 
                  ? Text(
                      title!, 
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ) 
                  : null,
              actions: actions,
              bottom: bottom,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (showGlows) ...[
            // Top Right Glow
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Bottom Left Glow
            Positioned(
              bottom: -50,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentMagenta.withValues(alpha: 0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
          SafeArea(
            child: body,
          ),
        ],
      ),
    );
  }
}
