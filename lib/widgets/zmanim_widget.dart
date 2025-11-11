import 'package:flutter/material.dart';
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

    const primaryTextColor = Color(0xFF212529);
    final timeColor = Colors.teal[600];

    final zmanimTiles = _zmanim.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                entry.value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: timeColor),
                textDirection: TextDirection.ltr,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(fontSize: 20, color: primaryTextColor.withOpacity(0.8)),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Container(
      // --- שינוי: הסרת המרווח החיצוני ---
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text("זמני היום (${widget.location})",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(color: Colors.black12, indent: 16, endIndent: 16),
          Expanded(
            child: AutoScrollingListView(children: zmanimTiles),
          ),
        ],
      ),
    );
  }
}