import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart';

class ZmanimHelper {
  static const Map<String, Map<String, Map<String, double>>> cityCoordinates = {
    'ארץ ישראל': {
      'ירושלים': {'lat': 31.7683, 'lng': 35.2137, 'elevation': 800.0},
      'תל אביב': {'lat': 32.0853, 'lng': 34.7818, 'elevation': 5.0},
      'חיפה': {'lat': 32.7940, 'lng': 34.9896, 'elevation': 30.0},
      'באר שבע': {'lat': 31.2518, 'lng': 34.7915, 'elevation': 280.0},
      'בני ברק': {'lat': 32.0809, 'lng': 34.8338, 'elevation': 50.0},
      'צפת': {'lat': 32.9650, 'lng': 35.4951, 'elevation': 900.0},
    },
    'ארצות הברית': {
      'ניו יורק': {'lat': 40.7128, 'lng': -74.0060, 'elevation': 10.0},
    },
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

  static Map<String, String> calculateDailyTimes(String city) {
    final cityData = _getCityData(city);
    if (cityData == null) {
      return {};
    }

    // ******** התיקון כאן: חזרה לשיטת ההגדרה הנכונה ********
    final location = GeoLocation();
    location.setLocationName(city);
    location.setLatitude(latitude: cityData['lat']!);
    location.setLongitude(longitude: cityData['lng']!);
    location.setElevation(cityData['elevation']!);
    location.setDateTime(DateTime.now());

    // ******** והתיקון השני כאן: שימוש בפונקציה הסטטית הנכונה ********
    final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(location);

    final jewishCalendar = JewishCalendar.fromDateTime(DateTime.now());
    jewishCalendar.inIsrael = _isCityInIsrael(city);

    final Map<String, String> times = {
      'עלות השחר': _formatTime(zmanimCalendar.getAlosHashachar()),
      'זריחה': _formatTime(zmanimCalendar.getSunrise()),
      'סוף זמן ק"ש (גר"א)': _formatTime(zmanimCalendar.getSofZmanShmaGRA()),
      'סוף זמן תפילה (גר"א)': _formatTime(zmanimCalendar.getSofZmanTfilaGRA()),
      'חצות היום': _formatTime(zmanimCalendar.getChatzos()),
      'מנחה גדולה': _formatTime(zmanimCalendar.getMinchaGedola()),
      'שקיעה': _formatTime(zmanimCalendar.getSunset()),
      'צאת הכוכבים': _formatTime(zmanimCalendar.getTzais()),
    };
    
    if (jewishCalendar.getDayOfWeek() == 6 || jewishCalendar.isErevYomTov()) {
       times['כניסת שבת/חג'] = _formatTime(zmanimCalendar.getCandleLighting());
    }
    if (jewishCalendar.getDayOfWeek() == 7 || jewishCalendar.isYomTov()) {
        times['צאת שבת/חג'] = _formatTime(zmanimCalendar.getTzais());
    }

    return times;
  }
}