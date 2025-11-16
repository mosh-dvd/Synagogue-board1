// lib/data/zmanim_helper.dart

import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart';

enum RelativeZman {
  alos,
  sunrise,
  sofZmanShmaGRA,
  sofZmanTfilaGRA,
  chatzos,
  minchaGedola,
  sunset,
  tzais,
  candleLighting
}

class ZmanimHelper {
  static const Map<RelativeZman, String> zmanimDisplayNames = {
    RelativeZman.alos: 'עלות השחר',
    RelativeZman.sunrise: 'זריחה',
    RelativeZman.sofZmanShmaGRA: 'סוף זמן ק"ש (גר"א)',
    RelativeZman.sofZmanTfilaGRA: 'סוף זמן תפילה (גר"א)',
    RelativeZman.chatzos: 'חצות היום',
    RelativeZman.minchaGedola: 'מנחה גדולה',
    RelativeZman.sunset: 'שקיעה',
    RelativeZman.tzais: 'צאת הכוכבים',
    RelativeZman.candleLighting: 'כניסת שבת/חג',
  };

  static const Map<String, Map<String, Map<String, double>>> cityCoordinates = {
    'ארץ ישראל': { 'אופקים': {'lat': 31.3111, 'lng': 34.6214, 'elevation': 140.0}, 'אילת': {'lat': 29.5581, 'lng': 34.9482, 'elevation': 12.0}, 'אריאל': {'lat': 32.1069, 'lng': 35.1897, 'elevation': 650.0}, 'אשדוד': {'lat': 31.8044, 'lng': 34.6553, 'elevation': 50.0}, 'אשקלון': {'lat': 31.6688, 'lng': 34.5742, 'elevation': 50.0}, 'באר שבע': {'lat': 31.2518, 'lng': 34.7915, 'elevation': 280.0}, 'ביתר עילית': {'lat': 31.7025, 'lng': 35.1156, 'elevation': 740.0}, 'בית שמש': {'lat': 31.7245, 'lng': 34.9886, 'elevation': 220.0}, 'בני ברק': {'lat': 32.0809, 'lng': 34.8338, 'elevation': 50.0}, 'בת ים': {'lat': 32.0167, 'lng': 34.7500, 'elevation': 5.0}, 'גבעת זאב': {'lat': 31.8467, 'lng': 35.1667, 'elevation': 600.0}, 'גבעתיים': {'lat': 32.0706, 'lng': 34.8103, 'elevation': 80.0}, 'דימונה': {'lat': 31.0686, 'lng': 35.0333, 'elevation': 550.0}, 'הוד השרון': {'lat': 32.1506, 'lng': 34.8889, 'elevation': 40.0}, 'הרצליה': {'lat': 32.1624, 'lng': 34.8443, 'elevation': 40.0}, 'חיפה': {'lat': 32.7940, 'lng': 34.9896, 'elevation': 30.0}, 'חולון': {'lat': 32.0117, 'lng': 34.7689, 'elevation': 54.0}, 'טבריה': {'lat': 32.7940, 'lng': 35.5308, 'elevation': -200.0}, 'יבנה': {'lat': 31.8781, 'lng': 34.7378, 'elevation': 25.0}, 'ירושלים': {'lat': 31.7683, 'lng': 35.2137, 'elevation': 800.0}, 'כפר סבא': {'lat': 32.1742, 'lng': 34.9067, 'elevation': 75.0}, 'כרמיאל': {'lat': 32.9186, 'lng': 35.2958, 'elevation': 300.0}, 'לוד': {'lat': 31.9516, 'lng': 34.8958, 'elevation': 50.0}, 'מודיעין עילית': {'lat': 31.9254, 'lng': 35.0364, 'elevation': 400.0}, 'מצפה רמון': {'lat': 30.6097, 'lng': 34.8017, 'elevation': 860.0}, 'מעלה אדומים': {'lat': 31.7767, 'lng': 35.2973, 'elevation': 740.0}, 'נתיבות': {'lat': 31.4214, 'lng': 34.5911, 'elevation': 140.0}, 'נתניה': {'lat': 32.3215, 'lng': 34.8532, 'elevation': 30.0}, 'נצרת עילית': {'lat': 32.6992, 'lng': 35.3289, 'elevation': 400.0}, 'עפולה': {'lat': 32.6078, 'lng': 35.2897, 'elevation': 60.0}, 'ערד': {'lat': 31.2592, 'lng': 35.2124, 'elevation': 570.0}, 'פתח תקווה': {'lat': 32.0870, 'lng': 34.8873, 'elevation': 80.0}, 'צפת': {'lat': 32.9650, 'lng': 35.4951, 'elevation': 900.0}, 'קרית אונו': {'lat': 32.0539, 'lng': 34.8581, 'elevation': 75.0}, 'קרית ארבע': {'lat': 31.5244, 'lng': 35.1031, 'elevation': 930.0}, 'קרית גת': {'lat': 31.6100, 'lng': 34.7642, 'elevation': 68.0}, 'קרית מלאכי': {'lat': 31.7289, 'lng': 34.7456, 'elevation': 108.0}, 'קרית שמונה': {'lat': 33.2072, 'lng': 35.5692, 'elevation': 135.0}, 'ראשון לציון': {'lat': 31.9642, 'lng': 34.8047, 'elevation': 68.0}, 'רחובות': {'lat': 31.8947, 'lng': 34.8096, 'elevation': 89.0}, 'רמלה': {'lat': 31.9297, 'lng': 34.8667, 'elevation': 108.0}, 'רמת גן': {'lat': 32.0719, 'lng': 34.8244, 'elevation': 80.0}, 'רעננה': {'lat': 32.1847, 'lng': 34.8706, 'elevation': 45.0}, 'תל אביב': {'lat': 32.0853, 'lng': 34.7818, 'elevation': 5.0}, 'תפרח': {'lat': 31.3889, 'lng': 34.6861, 'elevation': 160.0},
    }, 'ארצות הברית': { 'ניו יורק': {'lat': 40.7128, 'lng': -74.0060, 'elevation': 10.0} }
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
    if (cityData == null) {
      return {};
    }

    final targetDate = date ?? DateTime.now(); 
    
    final location = GeoLocation();
    location.setLocationName(city);
    location.setLatitude(latitude: cityData['lat']!);
    location.setLongitude(longitude: cityData['lng']!);
    location.setElevation(cityData['elevation']!);
    location.setDateTime(targetDate); 

    final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(location);

    final jewishCalendar = JewishCalendar.fromDateTime(targetDate); 
    jewishCalendar.inIsrael = _isCityInIsrael(city);

    final Map<RelativeZman, DateTime?> times = {
      RelativeZman.alos: zmanimCalendar.getAlosHashachar(),
      RelativeZman.sunrise: zmanimCalendar.getSunrise(),
      RelativeZman.sofZmanShmaGRA: zmanimCalendar.getSofZmanShmaGRA(),
      // *** התיקון הקריטי נמצא כאן ***
      RelativeZman.sofZmanTfilaGRA: zmanimCalendar.getSofZmanTfilaGRA(),
      RelativeZman.chatzos: zmanimCalendar.getChatzos(),
      RelativeZman.minchaGedola: zmanimCalendar.getMinchaGedola(),
      RelativeZman.sunset: zmanimCalendar.getSunset(),
      RelativeZman.tzais: zmanimCalendar.getTzais(),
    };

    if (jewishCalendar.isErevYomTov() || jewishCalendar.getDayOfWeek() == 6) {
       times[RelativeZman.candleLighting] = zmanimCalendar.getCandleLighting();
    }
    return times;
  }

  static Map<String, String> calculateDailyTimes(String city, {DateTime? date}) {
    final rawTimes = getZmanimDateTimes(city, date: date);
    final Map<String, String> formattedTimes = {};
    
    rawTimes.forEach((zman, time) {
      if (time != null) {
        formattedTimes[zmanimDisplayNames[zman]!] = _formatTime(time);
      }
    });
    
    final targetDate = date ?? DateTime.now();
    final jewishCalendar = JewishCalendar.fromDateTime(targetDate);
    
    if (rawTimes.containsKey(RelativeZman.tzais)) {
        if (jewishCalendar.isYomTov() || jewishCalendar.getDayOfWeek() == 7) {
            formattedTimes['צאת שבת/חג'] = _formatTime(rawTimes[RelativeZman.tzais]);
        }
    }

    return formattedTimes;
  }
}