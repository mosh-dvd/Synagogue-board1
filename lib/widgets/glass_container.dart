import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? color; // הוספנו צבע מותאם אישית
  final Color? borderColor; // הוספנו צבע מסגרת מותאם אישית

  const GlassContainer({
    Key? key,
    required this.child,
    this.opacity = 0.1, // ברירת מחדל אם לא נבחר צבע
    this.blur = 10.0,
    this.padding,
    this.color,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // משתמשים בצבע שהועבר, ואם לא - בלבן עם שקיפות
            color: color != null 
                ? color!.withOpacity(opacity) 
                : Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              // משתמשים בצבע המסגרת שהועבר
              color: borderColor != null 
                  ? borderColor!.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}