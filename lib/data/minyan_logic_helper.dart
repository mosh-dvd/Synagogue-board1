// lib/data/minyan_logic_helper.dart (קובץ מלא)
import 'package:synagogue_display/data/models.dart';
import 'package:synagogue_display/data/zmanim_helper.dart';
import 'package:kosher_dart/kosher_dart.dart';

// --- ההגדרה שהייתה חסרה ---
class MinyanWithTime {
  final Minyan minyan;
  final DateTime dateTime;

  MinyanWithTime({required this.minyan, required this.dateTime});
}

class MinyanLogicHelper {
  static MinyanWithTime? findNextMinyan(List<Minyan> allMinyanim, String location) {
    if (allMinyanim.isEmpty) return null;

    final now = DateTime.now();
    final zmanimForToday = ZmanimHelper.getZmanimDateTimes(location);
    final jewishCalendar = JewishCalendar.fromDateTime(now);
    
    MinyanScheduleType relevantScheduleType;
    final sunsetToday = zmanimForToday[RelativeZman.sunset];
    final chatzosToday = zmanimForToday[RelativeZman.chatzos]; // *** שינוי: הוספת חצות ***
    
    MinyanScheduleType relevantScheduleTypeForFiltering; // ייתכן שנצטרך להציג כמה סוגים, אבל כאן רק את הסוג העיקרי למעבר

    if (jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) { // שבת או יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            relevantScheduleTypeForFiltering = MinyanScheduleType.MOTZEI_SHABBAT;
        } else {
            relevantScheduleTypeForFiltering = MinyanScheduleType.SHABBAT_DAY;
        }
    } else if (jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov()) { // ערב שבת או ערב יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            relevantScheduleTypeForFiltering = MinyanScheduleType.SHABBAT_DAY; // ערבית של שבת כבר נכנסה, מחפשים את תפילת היום של שבת
        } else if (chatzosToday != null && now.isAfter(chatzosToday)) { // *** שינוי: אחרי חצות ביום שישי ***
            relevantScheduleTypeForFiltering = MinyanScheduleType.EREV_SHABBAT; // מנחה/ערבית ערב שבת
        } else {
            relevantScheduleTypeForFiltering = MinyanScheduleType.REGULAR; // שחרית כיום חול
        }
    } else { // יום חול רגיל
        relevantScheduleTypeForFiltering = MinyanScheduleType.REGULAR;
    }

    // קביעת אילו סוגי מניינים רלוונטיים לבדיקה כעת
    List<Minyan> relevantMinyanim = allMinyanim.where((m) {
        if (relevantScheduleTypeForFiltering == MinyanScheduleType.REGULAR) {
            return m.scheduleType == MinyanScheduleType.REGULAR;
        } else if (relevantScheduleTypeForFiltering == MinyanScheduleType.EREV_SHABBAT) {
            // ביום שישי אחרי חצות, אנו בודקים את מנייני ערב שבת וגם את מנייני מוצאי שבת,
            // למקרה שאנחנו קרובים למוצאי שבת (מנחה, ערבית, ומוצאי שבת עצמו)
            return m.scheduleType == MinyanScheduleType.EREV_SHABBAT || m.scheduleType == MinyanScheduleType.MOTZEI_SHABBAT;
        } else if (relevantScheduleTypeForFiltering == MinyanScheduleType.SHABBAT_DAY) {
            // בשבת/חג ובמוצ"ש, אנו בודקים את מנייני שבת ומוצ"ש
            return m.scheduleType == MinyanScheduleType.SHABBAT_DAY || m.scheduleType == MinyanScheduleType.MOTZEI_SHABBAT;
        } else if (relevantScheduleTypeForFiltering == MinyanScheduleType.MOTZEI_SHABBAT) {
             return m.scheduleType == MinyanScheduleType.MOTZEI_SHABBAT;
        }
        return false;
    }).toList();

    List<MinyanWithTime> upcomingMinyanim = [];
    for (var minyan in relevantMinyanim) {
      DateTime? minyanTime;
      if (minyan.timeType == MinyanTimeType.FIXED && minyan.time != null) {
        final parts = minyan.time!.split(':');
        if (parts.length == 2) {
          minyanTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        }
      } else if (minyan.timeType == MinyanTimeType.RELATIVE && minyan.relativeZman != null) {
        final zmanTime = zmanimForToday[minyan.relativeZman!];
        if (zmanTime != null) {
          minyanTime = zmanTime.add(Duration(minutes: minyan.relativeOffsetMinutes ?? 0));
        }
      }

      if (minyanTime != null && minyanTime.isAfter(now)) {
        upcomingMinyanim.add(MinyanWithTime(minyan: minyan, dateTime: minyanTime));
      }
    }
    
    if (upcomingMinyanim.isEmpty) return null;

    upcomingMinyanim.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    return upcomingMinyanim.first;
  }
}