// lib/widgets/zmanim_widget.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui; // <--- הוספת הייבוא החסר
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:synagogue_display/widgets/auto_scrolling_list_view.dart';

class ZmanimWidget extends StatelessWidget {
  final String location;
  final bool showBorders;

  const ZmanimWidget({
    Key? key,
    required this.location,
    required this.showBorders,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final simulationDate = dataProvider.simulationDate;
    final theme = dataProvider.theme;

    // משתמשים ב-getZmanimDateTimes המלא כדי לקבל אובייקטים של זמן להשוואה
    final rawTimes = ZmanimHelper.getZmanimDateTimes(location, date: simulationDate);
    
    // ממירים לרשימה למיון ותצוגה
    final List<MapEntry<String, DateTime>> sortedTimes = [];
    rawTimes.forEach((key, value) {
      if (value != null && ZmanimHelper.zmanimDisplayNames.containsKey(key)) {
        sortedTimes.add(MapEntry(ZmanimHelper.zmanimDisplayNames[key]!, value));
      }
    });
    
    // מיון לפי זמן
    sortedTimes.sort((a, b) => a.value.compareTo(b.value));

    // מציאת הזמן הבא (הראשון שגדול מעכשיו)
    final now = DateTime.now();
    String? nextZmanKey;
    for (var entry in sortedTimes) {
      if (entry.value.isAfter(now)) {
        nextZmanKey = entry.key;
        break; // מצאנו את הראשון
      }
    }

    final Color textColor = theme.primaryTextColor;
    final Color accentColor = theme.accentColor;
    final Color highlightColor = theme.highlightColor;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Colors.transparent, 
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'זמני היום',
              style: GoogleFonts.getFont(
                theme.primaryFont,
                fontSize: 28,
                fontWeight: FontWeight.w500, 
                color: textColor,
              ),
            ),
          ),
          Divider(thickness: 1, color: textColor.withOpacity(0.3)),
          Expanded(
            child: AutoScrollingListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: sortedTimes.map((entry) {
                final isNext = entry.key == nextZmanKey;
                
                return Container(
                  decoration: isNext ? BoxDecoration(
                    color: highlightColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ) : null,
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.getFont(
                          theme.primaryFont,
                          fontSize: 22,
                          color: isNext ? highlightColor : textColor.withOpacity(0.9),
                          fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(entry.value),
                        style: GoogleFonts.getFont(
                          theme.secondaryFont,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isNext ? highlightColor : accentColor,
                        ),
                        textDirection: ui.TextDirection.ltr, // <--- שימוש ב-ui.TextDirection
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}