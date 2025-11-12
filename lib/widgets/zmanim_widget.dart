// lib/widgets/zmanim_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:synagogue_display/widgets/auto_scrolling_list_view.dart';

class ZmanimWidget extends StatefulWidget {
  final String location;
  const ZmanimWidget({Key? key, required this.location}) : super(key: key);

  @override
  State<ZmanimWidget> createState() => _ZmanimWidgetState();
}

class _ZmanimWidgetState extends State<ZmanimWidget> {
  Map<String, String> _zmanim = {};

  @override
  void initState() {
    super.initState();
    _loadZmanim();
  }

  @override
  void didUpdateWidget(covariant ZmanimWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      _loadZmanim();
    }
  }

  void _loadZmanim() {
    final calculatedZmanim = ZmanimHelper.calculateDailyTimes(widget.location);
    if (mounted) {
      setState(() {
        _zmanim = calculatedZmanim;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_zmanim.isEmpty) {
      return const SizedBox.shrink();
    }
    
    const columnColor = Color(0xFFB3E5FC);
    const primaryTextColor = Color(0xFF37474F);
    const accentColor = Color(0xFF0D47A1);

    final zmanimTiles = _zmanim.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text( entry.key, style: GoogleFonts.rubik( fontSize: 20, color: primaryTextColor.withOpacity(0.85), ), textAlign: TextAlign.right, ),
            Text( entry.value, style: GoogleFonts.tinos( fontSize: 24, fontWeight: FontWeight.bold, color: accentColor, ), textDirection: TextDirection.ltr, ),
          ],
        ),
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: columnColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: 8, right: 8,
              child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.4), size: 24),
            ),
            Positioned(
              top: 8, left: 8,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: Icon(Icons.spa_outlined, color: primaryTextColor.withOpacity(0.4), size: 24),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                  child: Text(
                    "זמני היום (${widget.location})",
                    style: GoogleFonts.rubik( fontSize: 26, fontWeight: FontWeight.w500, color: primaryTextColor, ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Divider(
                  color: primaryTextColor.withOpacity(0.1),
                  indent: 30,
                  endIndent: 30,
                  thickness: 1,
                ),
                Expanded(
                  child: AutoScrollingListView(
                    pauseDuration: const Duration(seconds: 5),
                    children: zmanimTiles,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}