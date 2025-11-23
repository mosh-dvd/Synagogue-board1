// lib/widgets/hebcal_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
import 'package:synagogue_display/data/omer_helper.dart'; // וודא שקובץ זה קיים
import 'package:synagogue_display/data/zmanim_helper.dart';

class HebcalWidget extends StatelessWidget {
  const HebcalWidget({Key? key}) : super(key: key);

  String _getMonthName(JewishDate jd) {
    final month = jd.getJewishMonth();
    switch (month) {
      case 1: return 'ניסן';
      case 2: return 'אייר';
      case 3: return 'סיוון';
      case 4: return 'תמוז';
      case 5: return 'אב';
      case 6: return 'אלול';
      case 7: return 'תשרי';
      case 8: return 'חשוון';
      case 9: return 'כסלו';
      case 10: return 'טבת';
      case 11: return 'שבט';
      case 12: return jd.isJewishLeapYear() ? 'אדר א׳' : 'אדר';
      case 13: return 'אדר ב׳';
      default: return '';
    }
  }

  String _getDayName(int weekday, bool isNight) {
    String dayStr;
    switch (weekday) {
      case 7: dayStr = 'ראשון'; break;
      case 1: dayStr = 'שני'; break;
      case 2: dayStr = 'שלישי'; break;
      case 3: dayStr = 'רביעי'; break;
      case 4: dayStr = 'חמישי'; break;
      case 5: dayStr = 'שישי'; break;
      case 6: dayStr = 'שבת קודש'; break;
      default: dayStr = '';
    }

    if (isNight) {
      return 'ליל $dayStr';
    } else {
      if (weekday == 6) return 'יום שבת קודש';
      return 'יום $dayStr';
    }
  }

  String toGematria(int number) {
    if (number <= 0) return '';
    if (number >= 1000) return number.toString();

    const hebrewOnes = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
    const hebrewTens = ['', 'י', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'];
    const hebrewHundreds = ['', 'ק', 'ר', 'ש', 'ת'];

    var n = number;
    var str = '';
    
    while(n >= 400) { str += 'ת'; n -= 400; }
    if (n >= 100) { str += hebrewHundreds[n ~/ 100]; n %= 100; }
    if (n == 15) { str += 'ט"ו'; n = 0; } 
    else if (n == 16) { str += 'ט"ז'; n = 0; }
    if (n >= 10) { str += hebrewTens[n ~/ 10]; n %= 10; }
    if (n > 0) { str += hebrewOnes[n]; }
    
    if (str.length == 1) str += "'";
    else if (str.length > 1 && !str.contains('"')) {
      str = str.substring(0, str.length - 1) + '"' + str.substring(str.length - 1);
    }
    return str;
  }

  List<String> _getTefillaAlerts(BuildContext context, JewishCalendar jd) {
    List<String> alerts = [];
    int yomTovIndex = jd.getYomTovIndex();

    if (jd.isRoshChodesh() || jd.isCholHamoed() || jd.isYomTov()) {
      alerts.add("יעלה ויבוא");
    } else if (jd.isChanukah()) {
       alerts.add("על הניסים");
    } else if (yomTovIndex == JewishCalendar.PURIM || yomTovIndex == JewishCalendar.SHUSHAN_PURIM) {
       alerts.add("על הניסים");
    }

    int month = jd.getJewishMonth();
    int day = jd.getJewishDayOfMonth();
    
    bool isSummer = false;
    
    if (month == 1) { 
       if (day >= 1) isSummer = true; 
    } else if (month > 1 && month < 7) {
       isSummer = true; 
    } else if (month == 7) { 
       if (day < 22) isSummer = true; 
    }

    if (isSummer) {
       alerts.add("מוריד הטל");
    } else {
       alerts.add("משיב הרוח ומוריד הגשם");
    }

    bool askForRain = false;
    if (month == 8) { 
       if (day >= 7) askForRain = true;
    } else if (month > 8 || month < 1) { 
       askForRain = true;
    } else if (month == 1) { 
       askForRain = false; 
    }
    
    if (askForRain) {
      alerts.add("ותן טל ומטר");
    }

    int omer = jd.getDayOfOmer();
    if (omer != -1) {
      final nusach = Provider.of<DataProvider>(context, listen: false).nusach;
      alerts.add(OmerHelper.getOmerText(omer, nusach));
    }
    
    if (yomTovIndex == JewishCalendar.TISHA_BEAV) {
      alerts.add("עננו");
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final simulationDate = dataProvider.simulationDate;
    final location = dataProvider.location;
    final theme = dataProvider.theme;

    final zmanim = ZmanimHelper.getZmanimDateTimes(location, date: simulationDate);
    final sunset = zmanim[RelativeZman.sunset];
    
    bool isNightTime = false;
    
    if (sunset != null) {
      final switchTime = sunset.add(const Duration(minutes: 20));
      if (simulationDate.isAfter(switchTime)) {
        isNightTime = true;
      }
    }
    
    DateTime jewishCalcDate = simulationDate;
    if (isNightTime) {
      jewishCalcDate = simulationDate.add(const Duration(days: 1));
    }
    
    final jewishCalendar = JewishCalendar.fromDateTime(jewishCalcDate);
    jewishCalendar.inIsrael = true; 

    String dayNameText = _getDayName(jewishCalcDate.weekday, isNightTime);

    final day = toGematria(jewishCalendar.getJewishDayOfMonth());
    final month = _getMonthName(jewishCalendar);
    final year = toGematria(jewishCalendar.getJewishYear() % 1000);

    final fullDateString = '$dayNameText, $day $month $year';
    
    final alerts = _getTefillaAlerts(context, jewishCalendar);

    return Column(
      children: [
        Text(
          fullDateString,
          style: GoogleFonts.getFont(
            theme.primaryFont,
            color: theme.primaryTextColor, 
            fontSize: theme.dateFontSize, 
            fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        if (alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 4.0,
              children: alerts.map((alert) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: theme.highlightColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.highlightColor, width: 1),
                ),
                child: Text(
                  alert,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    theme.secondaryFont,
                    color: theme.primaryTextColor,
                    fontSize: theme.dateFontSize * 0.7,
                    fontWeight: FontWeight.bold
                  ),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}