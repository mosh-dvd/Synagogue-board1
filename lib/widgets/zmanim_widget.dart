// lib/widgets/zmanim_widget.dart

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

    const cardBackgroundColor = Color(0xFF2D3748);
    const primaryTextColor = Color(0xFFE2E8F0);
    const accentColor = Color(0xFFF6E05E);

    final zmanimTiles = _zmanim.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entry.key,
              style: GoogleFonts.rubik(
                fontSize: 20,
                color: primaryTextColor.withOpacity(0.85),
              ),
              textAlign: TextAlign.right,
            ),
            Text(
              entry.value,
              style: GoogleFonts.tinos(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
            child: Text(
              "זמני היום (${widget.location})",
              style: GoogleFonts.rubik(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(
            color: Colors.white12,
            indent: 30,
            endIndent: 30,
          ),
          Expanded(
            child: AutoScrollingListView(
              pauseDuration: const Duration(seconds: 5),
              children: zmanimTiles,
            ),
          ),
        ],
      ),
    );
  }
}