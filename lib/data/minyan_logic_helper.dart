// lib/data/minyan_logic_helper.dart

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

    if (jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) { // שבת או יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            relevantScheduleType = MinyanScheduleType.MOTZEI_SHABBAT;
        } else {
            relevantScheduleType = MinyanScheduleType.SHABBAT_DAY;
        }
    } else if (jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov()) { // ערב שבת או ערב יום טוב
        if (sunsetToday != null && now.isAfter(sunsetToday)) {
            relevantScheduleType = MinyanScheduleType.SHABBAT_DAY;
        } else {
            relevantScheduleType = MinyanScheduleType.REGULAR;
        }
    } else { // יום חול רגיל
        relevantScheduleType = MinyanScheduleType.REGULAR;
    }

    List<Minyan> relevantMinyanim = allMinyanim.where((m) {
        if (relevantScheduleType == MinyanScheduleType.REGULAR) {
            return m.scheduleType == MinyanScheduleType.REGULAR;
        } else {
            return m.scheduleType == MinyanScheduleType.SHABBAT_DAY || m.scheduleType == MinyanScheduleType.MOTZEI_SHABBAT;
        }
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