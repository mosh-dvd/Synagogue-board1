import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // <--- הוספת ייבוא ישיר ומפורש
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/models.dart';

class LargeClockWidget extends StatefulWidget {
  final Room roomSettings;
  const LargeClockWidget({Key? key, required this.roomSettings}) : super(key: key);

  @override
  _LargeClockWidgetState createState() => _LargeClockWidgetState();
}

class _LargeClockWidgetState extends State<LargeClockWidget> {
  String _timeString = "";
  Timer? _timer;

  @override
  void initState() {
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<DataProvider>(context, listen: false).theme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.minyanimColumnColor,
        borderRadius: BorderRadius.circular(11),
        border: widget.roomSettings.showBorders
            ? Border.all(
                color: theme.borderColor,
                width: theme.borderWidth,
              )
            : null,
      ),
      child: Center(
        child: Text(
          _timeString,
          style: GoogleFonts.getFont(
            theme.secondaryFont,
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: theme.primaryTextColor,
          ),
          textDirection: ui.TextDirection.ltr, // <--- שימוש בייבוא הישיר
        ),
      ),
    );
  }
}