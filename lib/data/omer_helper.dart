// lib/data/omer_helper.dart

import 'package:synagogue_display/data/models.dart';

class OmerHelper {
  
  static String getOmerText(int day, Nusach nusach) {
    if (day < 1 || day > 49) return "";

    String dayStr = _getDayString(day);
    String weeksStr = _getWeeksString(day, nusach);
    
    // בסיס המשפט: "היום X ימים"
    String text = "הַיּוֹם $dayStr";
    
    // קביעת המילה הסופית לפי הנוסח
    String suffixWord;
    if (nusach == Nusach.ASHKENAZ) {
      suffixWord = "בָּעוֹמֶר";
    } else {
      // גם ספרד (חסידים) וגם עדות המזרח אומרים "לעומר"
      suffixWord = "לָעוֹמֶר";
    }
    
    // --- ימים 1-6 (לפני שיש שבוע שלם) ---
    // בשבוע הראשון כולם אומרים את הסיומת מיד אחרי הימים
    if (day < 7) {
      return "$text $suffixWord";
    }
    
    // --- יום 7 והלאה (כולל אזכור שבועות) ---
    
    String prefixShehem = "שֶׁהֵם";
    
    // בדיקת מיקום הסיומת
    if (nusach == Nusach.EDOT_HAMIZRACH) {
      // עדות המזרח: הסיומת "לעומר" מגיעה מיד אחרי הימים (באמצע המשפט)
      // דוגמה: "היום שמונה ימים לעומר, שהם שבוע אחד..."
      return "$text $suffixWord $prefixShehem $weeksStr";
    } else {
      // אשכנז וספרד (חסידים): הסיומת מגיעה בסוף המשפט
      // אשכנז דוגמה: "היום... שהם... בעומר"
      // ספרד דוגמה: "היום... שהם... לעומר"
      return "$text $prefixShehem $weeksStr $suffixWord";
    }
  }

  static String _getDayString(int day) {
    const daysMap = {
      1: "יוֹם אֶחָד", 2: "שְׁנֵי יָמִים", 3: "שְׁלֹשָׁה יָמִים", 4: "אַרְבָּעָה יָמִים", 5: "חֲמִשָּׁה יָמִים", 6: "שִׁשָּׁה יָמִים", 7: "שִׁבְעָה יָמִים",
      8: "שְׁמוֹנָה יָמִים", 9: "תִּשְׁעָה יָמִים", 10: "עֲשָׂרָה יָמִים", 11: "אַחַד עָשָׂר יוֹם", 12: "שְׁנֵים עָשָׂר יוֹם", 13: "שְׁלֹשָׁה עָשָׂר יוֹם", 14: "אַרְבָּעָה עָשָׂר יוֹם",
      15: "חֲמִשָּׁה עָשָׂר יוֹם", 16: "שִׁשָּׁה עָשָׂר יוֹם", 17: "שִׁבְעָה עָשָׂר יוֹם", 18: "שְׁמוֹנָה עָשָׂר יוֹם", 19: "תִּשְׁעָה עָשָׂר יוֹם", 20: "עֶשְׂרִים יוֹם",
      21: "אֶחָד וְעֶשְׂרִים יוֹם", 22: "שְׁנַיִם וְעֶשְׂרִים יוֹם", 23: "שְׁלֹשָׁה וְעֶשְׂרִים יוֹם", 24: "אַרְבָּעָה וְעֶשְׂרִים יוֹם", 25: "חֲמִשָּׁה וְעֶשְׂרִים יוֹם", 26: "שִׁשָּׁה וְעֶשְׂרִים יוֹם", 27: "שִׁבְעָה וְעֶשְׂרִים יוֹם", 28: "שְׁמוֹנָה וְעֶשְׂרִים יוֹם",
      29: "תִּשְׁעָה וְעֶשְׂרִים יוֹם", 30: "שְׁלֹשִׁים יוֹם", 31: "אֶחָד וּשְׁלֹשִׁים יוֹם", 32: "שְׁנַיִם וּשְׁלֹשִׁים יוֹם", 33: "שְׁלֹשָׁה וּשְׁלֹשִׁים יוֹם", 34: "אַרְבָּעָה וּשְׁלֹשִׁים יוֹם", 35: "חֲמִשָּׁה וּשְׁלֹשִׁים יוֹם", 36: "שִׁשָּׁה וּשְׁלֹשִׁים יוֹם", 37: "שִׁבְעָה וּשְׁלֹשִׁים יוֹם", 38: "שְׁמוֹנָה וּשְׁלֹשִׁים יוֹם", 39: "תִּשְׁעָה וּשְׁלֹשִׁים יוֹם", 40: "אַרְבָּעִים יוֹם",
      41: "אֶחָד וְאַרְבָּעִים יוֹם", 42: "שְׁנַיִם וְאַרְבָּעִים יוֹם", 43: "שְׁלֹשָׁה וְאַרְבָּעִים יוֹם", 44: "אַרְבָּעָה וְאַרְבָּעִים יוֹם", 45: "חֲמִשָּׁה וְאַרְבָּעִים יוֹם", 46: "שִׁשָּׁה וְאַרְבָּעִים יוֹם", 47: "שִׁבְעָה וְאַרְבָּעִים יוֹם", 48: "שְׁמוֹנָה וְאַרְבָּעִים יוֹם", 49: "תִּשְׁעָה וְאַרְבָּעִים יוֹם"
    };
    return daysMap[day] ?? "";
  }

  static String _getWeeksString(int day, Nusach nusach) {
    if (day < 7) return "";
    
    int weeks = day ~/ 7;
    int remainder = day % 7;
    
    String shavuaStr;
    
    if (weeks == 1) {
      shavuaStr = "שָׁבוּעַ אֶחָד";
    } else {
      shavuaStr = _getNumberStr(weeks) + " שָׁבוּעוֹת";
    }
    
    if (remainder == 0) {
      return shavuaStr;
    }
    
    String daysRemainderStr = _getDayString(remainder);
    
    // הוספת ו' החיבור לשארית הימים
    daysRemainderStr = _addVav(daysRemainderStr);
    
    return "$shavuaStr $daysRemainderStr";
  }
  
  static String _getNumberStr(int num) {
    const map = {
      2: "שְׁנֵי", 3: "שְׁלֹשָׁה", 4: "אַרְבָּעָה", 5: "חֲמִשָּׁה", 6: "שִׁשָּׁה", 7: "שִׁבְעָה"
    };
    return map[num] ?? "";
  }
  
  static String _addVav(String str) {
     if (str.startsWith("י")) return "וְ" + str;
     if (str.startsWith("שְׁ")) return "וּ" + str;
     if (str.startsWith("אַ")) return "וְ" + str;
     if (str.startsWith("חֲ")) return "וַ" + str;
     if (str.startsWith("שִׁ")) return "וְ" + str;
     if (str.startsWith("תִּ")) return "וְ" + str;
     return "וְ" + str;
  }
}