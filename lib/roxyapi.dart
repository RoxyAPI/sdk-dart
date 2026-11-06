/// RoxyAPI for Dart and Flutter: astrology, Vedic astrology, numerology, tarot, human design
/// and 18+ insight domains behind one API key.
///
/// ```dart
/// import 'package:roxyapi/roxyapi.dart';
///
/// final roxy = Roxy('YOUR_API_KEY');
/// final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.aries);
/// ```
library;

export 'src/api.g.dart' hide apiBaseUrl;
export 'src/client.dart';
export 'src/enums.g.dart';
export 'src/error_codes.g.dart';
export 'src/exception.dart';
export 'src/json.dart' show NumOrString;
export 'src/models.g.dart';
