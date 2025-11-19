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
    final theme = dataProvider.theme;

    final dailyTimes = ZmanimHelper.calculateDailyTimes(location, date: simulationDate);
    final timesList = dailyTimes.entries.toList();

    // שימוש בצבעים בהירים עבור העיצוב המודרני (Dark Mode)
    final Color textColor = Colors.white;
    final Color accentColor = Colors.amberAccent;

    return Container(
      padding: const EdgeInsets.all(12.0),
      // ביטלנו את הרקע האטום כדי שיראו את ה-GlassContainer
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
                fontWeight: FontWeight.w300, // פונט דק יותר למראה מודרני
                color: textColor,
              ),
            ),
          ),
          Divider(thickness: 1, color: Colors.white.withOpacity(0.3)),
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
                          fontSize: 22,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        entry.value,
                        style: GoogleFonts.getFont(
                          theme.secondaryFont,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
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