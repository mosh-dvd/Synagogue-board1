// lib/widgets/hebcal_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart';
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
      case 12:
        return jd.isJewishLeapYear() ? 'אדר א׳' : 'אדר';
      case 13:
        return 'אדר ב׳';
      default:
        return '';
    }
  }

  String _getDayOfWeekName(int day) {
    switch (day) {
      case 1: return 'יום ראשון';
      case 2: return 'יום שני';
      case 3: return 'יום שלישי';
      case 4: return 'יום רביעי';
      case 5: return 'יום חמישי';
      case 6: return 'יום שישי';
      case 7: return 'שבת קודש';
      default: return '';
    }
  }

  String _getNextDayLeilName(int currentDay) {
    int nextDay = (currentDay % 7) + 1;
    switch (nextDay) {
      case 1: return 'ליל ראשון';
      case 2: return 'ליל שני';
      case 3: return 'ליל שלישי';
      case 4: return 'ליל רביעי';
      case 5: return 'ליל חמישי';
      case 6: return 'ליל שישי';
      case 7: return 'ליל שבת קודש';
      default: return '';
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

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final simulationDate = dataProvider.simulationDate;
    final location = dataProvider.location;
    final theme = dataProvider.theme;

    // חישוב זמנים לקביעת יום/לילה
    final zmanim = ZmanimHelper.getZmanimDateTimes(location, date: simulationDate);
    final sunset = zmanim[RelativeZman.sunset];
    
    bool isNightTime = false;
    
    // הלוגיקה החדשה: 20 דקות אחרי השקיעה = לילה
    if (sunset != null) {
      final switchTime = sunset.add(const Duration(minutes: 20));
      if (simulationDate.isAfter(switchTime)) {
        isNightTime = true;
      }
    }
    
    // אם לילה, מקדמים את התאריך העברי ליום הבא
    DateTime jewishCalcDate = simulationDate;
    if (isNightTime) {
      jewishCalcDate = simulationDate.add(const Duration(days: 1));
    }
    
    final jewishDate = JewishDate.fromDateTime(jewishCalcDate);

    // קביעת הטקסט "יום X" או "ליל X"
    String dayName;
    if (isNightTime) {
       // משתמשים ביום הנוכחי (לפני הקידום) כדי לקבל את "ליל [היום הבא]"
       dayName = _getNextDayLeilName(simulationDate.weekday);
    } else {
       dayName = _getDayOfWeekName(simulationDate.weekday);
    }

    final day = toGematria(jewishDate.getJewishDayOfMonth());
    final month = _getMonthName(jewishDate);
    final year = toGematria(jewishDate.getJewishYear() % 1000);

    final fullDateString = '$dayName, $day $month $year';

    return Text(
      fullDateString,
      style: GoogleFonts.getFont(
        theme.primaryFont,
        color: theme.primaryTextColor, 
        fontSize: 32, 
        fontWeight: FontWeight.bold
      ),
    );
  }
}