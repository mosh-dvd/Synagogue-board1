// lib/data/zmanim_helper.dart

import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart';

enum RelativeZman {
  alos, // עלות השחר (רגיל/16.1 מעלות)
  alos16point1, // 72 דקות
  alos19point8, // 90 דקות
  sunrise, // זריחה
  sofZmanShmaMGA, // סו"ז ק"ש מג"א
  sofZmanShmaGRA, // סו"ז ק"ש גר"א
  sofZmanTfilaMGA, // סו"ז תפילה מג"א
  sofZmanTfilaGRA, // סו"ז תפילה גר"א
  chatzos, // חצות היום
  minchaGedola, // מנחה גדולה
  minchaKetana, // מנחה קטנה
  plagHamincha, // פלג המנחה
  sunset, // שקיעה
  sunsetRT, // שקיעה רבנו תם (או צאת הכוכבים ר"ת)
  tzais, // צאת הכוכבים (רגיל)
  candleLighting, // הדלקת נרות
  shabbosExit, // צאת שבת רגיל
  shabbosExitChazonIsh, // צאת שבת חזו"א
  sofZmanAchilasChametzMGA,
  sofZmanAchilasChametzGRA,
  sofZmanBiurChametzMGA,
  sofZmanBiurChametzGRA,
  omerCounting, // זמן ספירת העומר
  fastStart, // תחילת צום
  fastEnd, // סוף צום
  kidushLevanaEarliest,
  kidushLevanaLatest,
  chanukahCandles, // הדלקת נרות חנוכה
}

class ZmanimHelper {
  static const Map<RelativeZman, String> zmanimDisplayNames = {
    RelativeZman.alos: 'עלות השחר',
    RelativeZman.alos16point1: 'עלות השחר (72 דק\')',
    RelativeZman.alos19point8: 'עלות השחר (90 דק\')',
    RelativeZman.sunrise: 'זריחה',
    RelativeZman.sofZmanShmaMGA: 'סו"ז ק"ש (מג"א)',
    RelativeZman.sofZmanShmaGRA: 'סו"ז ק"ש (גר"א)',
    RelativeZman.sofZmanTfilaMGA: 'סו"ז תפילה (מג"א)',
    RelativeZman.sofZmanTfilaGRA: 'סו"ז תפילה (גר"א)',
    RelativeZman.chatzos: 'חצות היום',
    RelativeZman.minchaGedola: 'מנחה גדולה',
    RelativeZman.minchaKetana: 'מנחה קטנה',
    RelativeZman.plagHamincha: 'פלג המנחה',
    RelativeZman.sunset: 'שקיעה',
    RelativeZman.sunsetRT: 'צאת הכוכבים (ר"ת)',
    RelativeZman.tzais: 'צאת הכוכבים',
    RelativeZman.candleLighting: 'הדלקת נרות',
    RelativeZman.shabbosExit: 'צאת השבת/חג',
    RelativeZman.shabbosExitChazonIsh: 'צאת השבת (חזו"א)',
    RelativeZman.sofZmanAchilasChametzMGA: 'סו"ז אכילת חמץ (מג"א)',
    RelativeZman.sofZmanAchilasChametzGRA: 'סו"ז אכילת חמץ (גר"א)',
    RelativeZman.sofZmanBiurChametzMGA: 'סו"ז ביעור חמץ (מג"א)',
    RelativeZman.sofZmanBiurChametzGRA: 'סו"ז ביעור חמץ (גר"א)',
    RelativeZman.omerCounting: 'זמן ספירת העומר',
    RelativeZman.fastStart: 'תחילת הצום',
    RelativeZman.fastEnd: 'צאת הצום',
    RelativeZman.kidushLevanaEarliest: 'קידוש לבנה (מוקדם)',
    RelativeZman.kidushLevanaLatest: 'קידוש לבנה (סוף)',
    RelativeZman.chanukahCandles: 'הדלקת נרות חנוכה',
  };

  // העתקתי את הרשימה המלאה שסיפקת
  static const Map<String, Map<String, Map<String, double>>> cityCoordinates = {
  'ארץ ישראל': {
    'אופקים': {'lat': 31.3111, 'lng': 34.6214, 'elevation': 140.0},
    'אילת': {'lat': 29.5581, 'lng': 34.9482, 'elevation': 12.0},
    'אלעד': {'lat': 32.0519, 'lng': 34.9517, 'elevation': 75.0},
    'אריאל': {'lat': 32.1069, 'lng': 35.1897, 'elevation': 650.0},
    'אשדוד': {'lat': 31.8044, 'lng': 34.6553, 'elevation': 50.0},
    'אשקלון': {'lat': 31.6688, 'lng': 34.5742, 'elevation': 50.0},
    'באר שבע': {'lat': 31.2518, 'lng': 34.7915, 'elevation': 280.0},
    'ביתר עילית': {'lat': 31.7025, 'lng': 35.1156, 'elevation': 740.0},
    'בית שמש': {'lat': 31.7245, 'lng': 34.9886, 'elevation': 220.0},
    'בני ברק': {'lat': 32.0809, 'lng': 34.8338, 'elevation': 50.0},
    'בת ים': {'lat': 32.0167, 'lng': 34.7500, 'elevation': 5.0},
    'גבעת זאב': {'lat': 31.8467, 'lng': 35.1667, 'elevation': 600.0},
    'גבעתיים': {'lat': 32.0706, 'lng': 34.8103, 'elevation': 80.0},
    'דימונה': {'lat': 31.0686, 'lng': 35.0333, 'elevation': 550.0},
    'הוד השרון': {'lat': 32.1506, 'lng': 34.8889, 'elevation': 40.0},
    'הרצליה': {'lat': 32.1624, 'lng': 34.8443, 'elevation': 40.0},
    'חיפה': {'lat': 32.7940, 'lng': 34.9896, 'elevation': 30.0},
    'חולון': {'lat': 32.0117, 'lng': 34.7689, 'elevation': 54.0},
    'טבריה': {'lat': 32.7940, 'lng': 35.5308, 'elevation': -200.0},
    'יבנה': {'lat': 31.8781, 'lng': 34.7378, 'elevation': 25.0},
    'ירושלים': {'lat': 31.7683, 'lng': 35.2137, 'elevation': 800.0},
    'כפר סבא': {'lat': 32.1742, 'lng': 34.9067, 'elevation': 75.0},
    'כרמיאל': {'lat': 32.9186, 'lng': 35.2958, 'elevation': 300.0},
    'לוד': {'lat': 31.9516, 'lng': 34.8958, 'elevation': 50.0},
    'מודיעין עילית': {'lat': 31.9254, 'lng': 35.0364, 'elevation': 400.0},
    'מצפה רמון': {'lat': 30.6097, 'lng': 34.8017, 'elevation': 860.0},
    'מעלה אדומים': {'lat': 31.7767, 'lng': 35.2973, 'elevation': 740.0},
    'נתיבות': {'lat': 31.4214, 'lng': 34.5911, 'elevation': 140.0},
    'נתניה': {'lat': 32.3215, 'lng': 34.8532, 'elevation': 30.0},
    'נצרת עילית': {'lat': 32.6992, 'lng': 35.3289, 'elevation': 400.0},
    'עפולה': {'lat': 32.6078, 'lng': 35.2897, 'elevation': 60.0},
    'ערד': {'lat': 31.2592, 'lng': 35.2124, 'elevation': 570.0},
    'פתח תקווה': {'lat': 32.0870, 'lng': 34.8873, 'elevation': 80.0},
    'צפת': {'lat': 32.9650, 'lng': 35.4951, 'elevation': 900.0},
    'קרית אונו': {'lat': 32.0539, 'lng': 34.8581, 'elevation': 75.0},
    'קרית ארבע': {'lat': 31.5244, 'lng': 35.1031, 'elevation': 930.0},
    'קרית גת': {'lat': 31.6100, 'lng': 34.7642, 'elevation': 68.0},
    'קרית מלאכי': {'lat': 31.7289, 'lng': 34.7456, 'elevation': 108.0},
    'קרית שמונה': {'lat': 33.2072, 'lng': 35.5692, 'elevation': 135.0},
    'ראשון לציון': {'lat': 31.9642, 'lng': 34.8047, 'elevation': 68.0},
    'רחובות': {'lat': 31.8947, 'lng': 34.8096, 'elevation': 89.0},
    'רמלה': {'lat': 31.9297, 'lng': 34.8667, 'elevation': 108.0},
    'רמת גן': {'lat': 32.0719, 'lng': 34.8244, 'elevation': 80.0},
    'רעננה': {'lat': 32.1847, 'lng': 34.8706, 'elevation': 45.0},
    'תל אביב': {'lat': 32.0853, 'lng': 34.7818, 'elevation': 5.0},
    'תפרח': {'lat': 31.3889, 'lng': 34.6861, 'elevation': 160.0},
  },
  'ארצות הברית': { 'ניו יורק': {'lat': 40.7128, 'lng': -74.0060, 'elevation': 10.0} }
  };

  static List<String> getAllCities() {
    final List<String> cities = [];
    cityCoordinates.forEach((country, cityMap) {
      cities.addAll(cityMap.keys);
    });
    cities.sort();
    return cities;
  }

  static bool _isCityInIsrael(String cityName) {
    return cityCoordinates['ארץ ישראל']!.containsKey(cityName);
  }

  static Map<String, double>? _getCityData(String cityName) {
    for (var country in cityCoordinates.values) {
      if (country.containsKey(cityName)) {
        return country[cityName];
      }
    }
    return null;
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  static Map<RelativeZman, DateTime?> getZmanimDateTimes(String city, {DateTime? date}) {
    final cityData = _getCityData(city);
    if (cityData == null) return {};

    final targetDate = date ?? DateTime.now();
    
    final location = GeoLocation();
    location.setLocationName(city);
    location.setLatitude(latitude: cityData['lat']!);
    location.setLongitude(longitude: cityData['lng']!);
    location.setElevation(cityData['elevation'] ?? 0);
    location.setDateTime(targetDate);

    final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(location);
    final jewishCalendar = JewishCalendar.fromDateTime(targetDate);
    jewishCalendar.inIsrael = _isCityInIsrael(city);

    final Map<RelativeZman, DateTime?> times = {
      RelativeZman.alos: zmanimCalendar.getAlosHashachar(),
      RelativeZman.alos16point1: zmanimCalendar.getAlos16Point1Degrees(),
      RelativeZman.alos19point8: zmanimCalendar.getAlos19Point8Degrees(),
      RelativeZman.sunrise: zmanimCalendar.getSunrise(),
      RelativeZman.sofZmanShmaMGA: zmanimCalendar.getSofZmanShmaMGA(),
      RelativeZman.sofZmanShmaGRA: zmanimCalendar.getSofZmanShmaGRA(),
      RelativeZman.sofZmanTfilaMGA: zmanimCalendar.getSofZmanTfilaMGA(),
      RelativeZman.sofZmanTfilaGRA: zmanimCalendar.getSofZmanTfilaGRA(),
      RelativeZman.chatzos: zmanimCalendar.getChatzos(),
      RelativeZman.minchaGedola: zmanimCalendar.getMinchaGedola(),
      RelativeZman.minchaKetana: zmanimCalendar.getMinchaKetana(),
      RelativeZman.plagHamincha: zmanimCalendar.getPlagHamincha(),
      RelativeZman.sunset: zmanimCalendar.getSunset(),
      RelativeZman.tzais: zmanimCalendar.getTzais(),
    };

    // חישוב שקיעה רבנו תם (72 דקות)
    if (times[RelativeZman.sunset] != null) {
      times[RelativeZman.sunsetRT] = times[RelativeZman.sunset]!.add(const Duration(minutes: 72));
    }

    // זמנים מיוחדים לערב פסח
    if (jewishCalendar.getYomTovIndex() == JewishCalendar.EREV_PESACH) {
      times[RelativeZman.sofZmanAchilasChametzMGA] = zmanimCalendar.getSofZmanAchilasChametzMGA72Minutes();
      times[RelativeZman.sofZmanAchilasChametzGRA] = zmanimCalendar.getSofZmanAchilasChametzGRA();
      times[RelativeZman.sofZmanBiurChametzMGA] = zmanimCalendar.getSofZmanBiurChametzMGA72Minutes();
      times[RelativeZman.sofZmanBiurChametzGRA] = zmanimCalendar.getSofZmanBiurChametzGRA();
    }

    // הדלקת נרות (לפי עיר)
    if (jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov()) {
       times[RelativeZman.candleLighting] = _calculateCandleLightingTime(zmanimCalendar, city);
    }

    // יציאת שבת/חג
    if (jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) {
      final sunset = zmanimCalendar.getSunset();
      if (sunset != null) {
        times[RelativeZman.shabbosExit] = sunset.add(const Duration(minutes: 34)); // רגיל (בערך)
        times[RelativeZman.shabbosExitChazonIsh] = sunset.add(const Duration(minutes: 38)); // חזו"א
      }
    }

    // צומות
    if (jewishCalendar.isTaanis() && jewishCalendar.getYomTovIndex() != JewishCalendar.YOM_KIPPUR) {
      times[RelativeZman.fastStart] = zmanimCalendar.getAlosHashachar();
      times[RelativeZman.fastEnd] = zmanimCalendar.getTzais();
    }

    // ספירת העומר
    if (jewishCalendar.getDayOfOmer() != -1) {
      times[RelativeZman.omerCounting] = zmanimCalendar.getTzais();
    }

    // חנוכה
    if (jewishCalendar.isChanukah()) {
      times[RelativeZman.chanukahCandles] = zmanimCalendar.getTzais();
    }

    return times;
  }

  static DateTime? _calculateCandleLightingTime(ComplexZmanimCalendar zmanimCalendar, String city) {
    final sunset = zmanimCalendar.getSunset();
    if (sunset == null) return null;
    
    int minutes = 20; // ברירת מחדל
    if (city == 'ירושלים') minutes = 40;
    else if (city == 'בני ברק') minutes = 22;
    else if (city == 'מודיעין עילית') minutes = 30;
    else if (city == 'חיפה') minutes = 30;
    
    return sunset.subtract(Duration(minutes: minutes));
  }

  static Map<String, String> calculateDailyTimes(String city, {DateTime? date}) {
    final rawTimes = getZmanimDateTimes(city, date: date);
    final Map<String, String> formattedTimes = {};
    
    rawTimes.forEach((zman, time) {
      if (time != null) {
        // אנחנו מציגים רק זמנים נבחרים ברשימה הגלובלית כדי לא להעמיס,
        // או שאתה יכול להציג הכל. כרגע נציג את הכל לפי השמות ב-Map
        if (zmanimDisplayNames.containsKey(zman)) {
           formattedTimes[zmanimDisplayNames[zman]!] = _formatTime(time);
        }
      }
    });

    return formattedTimes;
  }
}