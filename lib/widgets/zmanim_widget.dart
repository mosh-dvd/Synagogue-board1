import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final theme = dataProvider.theme; // קבלת העיצוב

    final dailyTimes = ZmanimHelper.calculateDailyTimes(location, date: simulationDate);
    final timesList = dailyTimes.entries.toList();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.zmanimColumnColor,
        borderRadius: BorderRadius.circular(16),
        border: showBorders
            ? Border.all(
                color: theme.borderColor,
                width: theme.borderWidth,
              )
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'זמני היום',
              style: GoogleFonts.getFont(
                theme.primaryFont,
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: theme.primaryTextColor,
              ),
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
                        style: GoogleFonts.getFont(
                          theme.primaryFont,
                          fontSize: 20,
                          color: theme.primaryTextColor.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        entry.value,
                        style: GoogleFonts.getFont(
                          theme.secondaryFont,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryTextColor,
                        ),
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