// lib/widgets/hebcal_widget.dart (קובץ מלא)
import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';
import 'package:synagogue_display/data/data_provider.dart'; // *** שינוי: ייבוא DataProvider ***


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
  
  String toGematria(int number) {
    if (number <= 0) return '';
    if (number >= 1000) return number.toString();

    const hebrewOnes = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
    const hebrewTens = ['', 'י', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'];
    const hebrewHundreds = ['', 'ק', 'ר', 'ש', 'ת'];

    var n = number;
    var str = '';
    
    while(n >= 400) {
        str += 'ת';
        n -= 400;
    }

    if (n >= 100) {
      str += hebrewHundreds[n ~/ 100];
      n %= 100;
    }

    if (n == 15) {
      str += 'ט"ו';
      n = 0;
    } else if (n == 16) {
      str += 'ט"ז';
      n = 0;
    }

    if (n >= 10) {
      str += hebrewTens[n ~/ 10];
      n %= 10;
    }

    if (n > 0) {
      str += hebrewOnes[n];
    }
    
    if (str.length == 1) {
      str += "'";
    } else if (str.length > 1 && !str.contains('"')) {
      str = str.substring(0, str.length - 1) + '"' + str.substring(str.length - 1);
    }
    
    return str;
  }

  String getFormattedHebrewDate(BuildContext context) {
    // *** שינוי: קריאת תאריך ההדמיה מה-Provider ***
    final dataProvider = Provider.of<DataProvider>(context);
    final simulationDate = dataProvider.simulationDate;
    
    final jewishDate = JewishDate.fromDateTime(simulationDate);

    final day = toGematria(jewishDate.getJewishDayOfMonth());
    final month = _getMonthName(jewishDate);
    final year = toGematria(jewishDate.getJewishYear() % 1000);

    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getFormattedHebrewDate(context),
      style: const TextStyle(color: Colors.black87, fontSize: 24),
    );
  }
}