// lib/data/minyan_logic_helper.dart (קובץ מלא)
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart';

// --- ההגדרה שהייתה חסרה ---
class MinyanWithTime {
  final Minyan minyan;
  final DateTime dateTime;

  MinyanWithTime({required this.minyan, required this.dateTime});
}

class MinyanLogicHelper {
  
  // *** פונקציה חדשה: מציאת מניינים רלוונטיים ליום ספציפי ***
  static List<MinyanWithTime> _getUpcomingMinyanimForDay(
      DateTime day, List<Minyan> allMinyanim, String location, MinyanScheduleType primaryScheduleType, {bool includeRegularInShabbat = false}) {
      
    final zmanimForDay = ZmanimHelper.getZmanimDateTimes(location, date: day); 
    final now = DateTime.now();
    final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
    
    // קביעת סוגי המניינים הנדרשים לחישוב
    List<MinyanScheduleType> scheduleTypesToInclude = [];
    
    if (primaryScheduleType == MinyanScheduleType.REGULAR) {
        scheduleTypesToInclude.add(MinyanScheduleType.REGULAR);
    } else if (primaryScheduleType == MinyanScheduleType.EREV_SHABBAT) {
        scheduleTypesToInclude.addAll([MinyanScheduleType.EREV_SHABBAT, MinyanScheduleType.MOTZEI_SHABBAT]);
    } else if (primaryScheduleType == MinyanScheduleType.SHABBAT_DAY) {
        scheduleTypesToInclude.addAll([MinyanScheduleType.SHABBAT_DAY, MinyanScheduleType.MOTZEI_SHABBAT]);
    } else if (primaryScheduleType == MinyanScheduleType.MOTZEI_SHABBAT) {
        scheduleTypesToInclude.add(MinyanScheduleType.MOTZEI_SHABBAT);
    }
    
    // *** שינוי: הוספת REGULAR בשבת/חג רק לחישוב המניין הבא - נשאר כרגע כהגדרה גלובלית, אך תתוקן בהמשך ב-findNextMinyan ***
    if (includeRegularInShabbat && !scheduleTypesToInclude.contains(MinyanScheduleType.REGULAR)) {
        scheduleTypesToInclude.add(MinyanScheduleType.REGULAR);
    }

    final List<Minyan> relevantMinyanim = allMinyanim.where((m) => scheduleTypesToInclude.contains(m.scheduleType)).toList();

    List<MinyanWithTime> upcomingMinyanim = [];
    for (var minyan in relevantMinyanim) {
      DateTime? minyanTime;
      
      if (minyan.timeType == MinyanTimeType.FIXED && minyan.time != null) {
        final parts = minyan.time!.split(':');
        if (parts.length == 2) {
          minyanTime = DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
        }
      } else if (minyan.timeType == MinyanTimeType.RELATIVE && minyan.relativeZman != null) {
        // חישוב הזמן היחסי ליום הנדרש
        final zmanTime = zmanimForDay[minyan.relativeZman!];
        if (zmanTime != null) {
          final calculatedTime = zmanTime.add(Duration(minutes: minyan.relativeOffsetMinutes ?? 0));
          // ודא שה-DateTime הוא באותו יום כמו ה-day (מטפל במעבר חצות)
          minyanTime = DateTime(day.year, day.month, day.day, calculatedTime.hour, calculatedTime.minute, calculatedTime.second);
        }
      }

      // רק אם המניין הוא להיום ואחרי עכשיו (אם זה היום)
      if (minyanTime != null && (!isToday || minyanTime.isAfter(now))) {
        upcomingMinyanim.add(MinyanWithTime(minyan: minyan, dateTime: minyanTime));
      }
    }
    
    upcomingMinyanim.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcomingMinyanim;
  }
  // *** סוף פונקציה חדשה ***

  static MinyanWithTime? findNextMinyan(List<Minyan> allMinyanim, String location) {
    if (allMinyanim.isEmpty) return null;

    final now = DateTime.now();
    final jewishCalendar = JewishCalendar.fromDateTime(now);
    final zmanimForToday = ZmanimHelper.getZmanimDateTimes(location);
    final sunsetToday = zmanimForToday[RelativeZman.sunset];
    final chatzosToday = zmanimForToday[RelativeZman.chatzos]; 
    
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    
    // 1. קביעת לוח הזמנים העיקרי להיום
    MinyanScheduleType primaryScheduleTypeToday;
    final isShabbat = jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov();
    final isErevShabbat = jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov();
    
    if (isShabbat) { // שבת או יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            primaryScheduleTypeToday = MinyanScheduleType.MOTZEI_SHABBAT;
        } else {
            primaryScheduleTypeToday = MinyanScheduleType.SHABBAT_DAY;
        }
    } else if (isErevShabbat) { // ערב שבת או ערב יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            primaryScheduleTypeToday = MinyanScheduleType.SHABBAT_DAY; 
        } else if (chatzosToday != null && now.isAfter(chatzosToday)) { 
            primaryScheduleTypeToday = MinyanScheduleType.EREV_SHABBAT; 
        } else {
            primaryScheduleTypeToday = MinyanScheduleType.REGULAR; 
        }
    } else { // יום חול רגיל (כולל יום ראשון עד מוצאי שבת קודמת)
        primaryScheduleTypeToday = MinyanScheduleType.REGULAR;
    }
    
    // 2. מציאת מניינים רלוונטיים להיום שטרם התחילו
    List<MinyanWithTime> upcomingToday;
    
    // *** שינוי קריטי: אם זה שבת/חג/מוצ"ש, אנחנו רוצים רק את מנייני השבת/חג/מוצ"ש ***
    // מנייני יום חול (REGULAR) מוצגים רק בלוח המניינים, לא ב"מניין הבא"
    if (primaryScheduleTypeToday == MinyanScheduleType.SHABBAT_DAY || primaryScheduleTypeToday == MinyanScheduleType.MOTZEI_SHABBAT) {
        // בחיפוש המניין הבא בשבת/מוצ"ש, אנחנו מתעלמים מ-REGULAR באופן גורף
        upcomingToday = _getUpcomingMinyanimForDay(
            today, allMinyanim, location, primaryScheduleTypeToday, includeRegularInShabbat: false
        );
    } else {
        // ביום חול וערב שבת, הלוגיקה נשארת כפי שהייתה
        upcomingToday = _getUpcomingMinyanimForDay(
            today, allMinyanim, location, primaryScheduleTypeToday, includeRegularInShabbat: false
        );
    }
    
    if (upcomingToday.isNotEmpty) {
        return upcomingToday.first;
    }
    
    // 3. אם לא נמצא מניין היום (כי הכל עבר, כולל מוצ"ש), עוברים ליום הבא

    // קביעת לוח הזמנים העיקרי למחר
    final jewishCalendarTomorrow = JewishCalendar.fromDateTime(tomorrow);
    MinyanScheduleType primaryScheduleTypeTomorrow;

    if (jewishCalendarTomorrow.getDayOfWeek() == 7 || jewishCalendarTomorrow.isYomTov()) {
        primaryScheduleTypeTomorrow = MinyanScheduleType.SHABBAT_DAY;
    } else if (jewishCalendarTomorrow.getDayOfWeek() == 6 || jewishCalendarTomorrow.isErevYomTov()) {
        primaryScheduleTypeTomorrow = MinyanScheduleType.REGULAR; 
    } else {
        primaryScheduleTypeTomorrow = MinyanScheduleType.REGULAR;
    }
    
    // מציאת המניין הראשון של מחר
    // *** שינוי קריטי: מוסיף את REGULAR אם המניין של מחר אמור להיות REGULAR (שחרית של יום ראשון) ***
    List<MinyanWithTime> upcomingTomorrow = _getUpcomingMinyanimForDay(
        tomorrow, 
        allMinyanim, 
        location, 
        primaryScheduleTypeTomorrow,
        // אם מחר הוא יום חול, אנחנו רוצים את מנייני REGULAR שלו
        includeRegularInShabbat: primaryScheduleTypeTomorrow == MinyanScheduleType.REGULAR 
    );

    if (upcomingTomorrow.isNotEmpty) {
        return upcomingTomorrow.first;
    }

    return null;
  }
}