// lib/widgets/zmanim_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
// *** מייבאים את הלוגיקה מכאן, ולא מגדירים אותה מחדש ***
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:synagogue_display/widgets/auto_scrolling_list_view.dart';

class ZmanimWidget extends StatelessWidget {
  final String location;
  const ZmanimWidget({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // קריאת תאריך ההדמיה מה-Provider
    final dataProvider = Provider.of<DataProvider>(context);
    final simulationDate = dataProvider.simulationDate;

    // חישוב הזמנים לפי התאריך מה-Provider
    final dailyTimes = ZmanimHelper.calculateDailyTimes(location, date: simulationDate);
    final timesList = dailyTimes.entries.toList();

    const cardBackgroundColor = Color(0xFFB3E5FC);
    const primaryTextColor = Color(0xFF37474F);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'זמני היום',
              style: GoogleFonts.rubik(fontSize: 26, fontWeight: FontWeight.w500, color: primaryTextColor),
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: AutoScrollingListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: timesList.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.rubik(fontSize: 20, color: primaryTextColor.withOpacity(0.9)),
                      ),
                      Text(
                        entry.value,
                        style: GoogleFonts.tinos(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
                        textDirection: TextDirection.ltr,
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