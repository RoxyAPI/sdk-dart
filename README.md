<p align="center">
  <a href="https://roxyapi.com">
    <img src="https://raw.githubusercontent.com/RoxyAPI/sdk-dart/main/assets/hero.png" alt="RoxyAPI Dart SDK, ship in an afternoon. The Spiritual OS layer for agentic AI. One key, flat pricing." width="100%">
  </a>
</p>

# roxyapi

[![pub](https://img.shields.io/pub/v/roxyapi)](https://pub.dev/packages/roxyapi)
[![Docs](https://img.shields.io/badge/docs-roxyapi.com-blue)](https://roxyapi.com/docs/sdk)
[![API Reference](https://img.shields.io/badge/api%20reference-roxyapi.com-blue)](https://roxyapi.com/api-reference)
[![Pricing](https://img.shields.io/badge/pricing-roxyapi.com-blue)](https://roxyapi.com/pricing)

Dart and Flutter SDK for astrology, Vedic astrology, numerology, tarot, and more.

One API key. Fully typed. Verified against NASA JPL Horizons.

The fastest way to add natal charts, daily horoscopes, synastry, Vedic kundli, tarot spreads, numerology, human design bodygraphs, and transit forecasts to Flutter apps, Dart backends, and AI agents. 18+ domains behind a single [Roxy](https://roxyapi.com) subscription, interpretations in 10+ languages.

## Install

```bash
dart pub add roxyapi
# or
flutter pub add roxyapi
```

## Start with one call

Get real product value with a single typed call. No setup beyond your API key.

<!-- BEGIN:EXAMPLE:start -->
```dart
import 'dart:io';

import 'package:roxyapi/roxyapi.dart';

Future<void> main() async {
  final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '');

  final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.aries);
  print('${horoscope.overview} Lucky number ${horoscope.luckyNumber}');
}
```
<!-- END:EXAMPLE:start -->

Then expand into charts, compatibility, numerology, tarot, and more.

## Quick start

<!-- BEGIN:EXAMPLE:quick-start -->
```dart
// Step 1: geocode the birth city once. Every chart endpoint takes these three values.
final places = await roxy.location.searchCities(q: 'London');
final place = places.cities.first;
print('${place.city}, ${place.country}: ${place.timezone}');

// Step 2: a Western natal chart. The timezone is the IANA name from the lookup; the server
// resolves it to the DST-correct offset for the date of the chart.
final chart = await roxy.astrology.generateNatalChart(
  date: '1990-01-15',
  time: '14:30:00',
  latitude: place.latitude,
  longitude: place.longitude,
  timezone: NumOrString.string(place.timezone),
);
// `planets` is a list: find a body by its `name`.
final moon = chart.planets.firstWhere((p) => p.name == 'Moon');
print('Moon in ${moon.sign}, ${chart.ascendant.sign} rising');

// Step 3: the same birth as a Vedic kundli. Same inputs, sidereal zodiac.
final kundli = await roxy.vedicAstrology.generateBirthChart(
  date: '1990-01-15',
  time: '14:30:00',
  latitude: place.latitude,
  longitude: place.longitude,
  timezone: NumOrString.string(place.timezone),
);
// `meta` is keyed by graha; its `nakshatra` is an object, so read `name`.
final vedicMoon = kundli.meta['Moon'];
print('Rashi ${vedicMoon?.rashi}, nakshatra ${vedicMoon?.nakshatra.name}');
```
<!-- END:EXAMPLE:quick-start -->

`Roxy` sets the base URL (`https://roxyapi.com/api/v2`) and sends the key and an SDK identification header on every request. Every method returns the typed response and throws `RoxyException` on a 4xx or 5xx (see Error handling). A network failure (DNS, timeout, connection reset) is not an API error: it throws the HTTP client exception, so catch it where that matters. Call `close()` when you are done with the client.

## Domains

<!-- BEGIN:DOMAINS -->
| Namespace | What it covers |
|-----------|----------------|
| [`roxy.astrology`](https://roxyapi.com/api-reference/western-astrology) | Western astrology API for natal birth charts, daily, weekly, monthly, and yearly horoscopes with unique content per s... |
| [`roxy.vedicAstrology`](https://roxyapi.com/api-reference/vedic-astrology) | Vedic astrology (Jyotish) and KP API for kundli generation with the sixteen Shodasavarga divisional charts (D1 to D60... |
| [`roxy.forecast`](https://roxyapi.com/api-reference/forecast) | Astrology forecast API that merges upcoming transit aspects, sign ingresses, retrograde stations, new and full moons,... |
| [`roxy.humanDesign`](https://roxyapi.com/api-reference/human-design) | Human Design API that generates the full bodygraph from a birth moment: type, strategy, inner authority, profile, def... |
| [`roxy.chineseAstrology`](https://roxyapi.com/api-reference/chinese-astrology) | Chinese zodiac and BaZi astrology API: Four Pillars charts, Chinese zodiac signs and the Chinese lunisolar calendar f... |
| [`roxy.fengShui`](https://roxyapi.com/api-reference/feng-shui) | Compute classical feng shui from one API: Xuan Kong flying star natal charts for any of the nine periods and 24 mount... |
| [`roxy.mesoamericanAstrology`](https://roxyapi.com/api-reference/mesoamerican-astrology) | Calculate Mayan astrology day signs, the Tzolkin sacred round, the Haab year, the full Long Count and the Aztec tonal... |
| [`roxy.vastu`](https://roxyapi.com/api-reference/vastu) | Vastu Shastra API for directional home and plot analysis: entrance padas with the classical effect of each of the 32... |
| [`roxy.numerology`](https://roxyapi.com/api-reference/numerology) | Numerology API for life path numbers, complete numerology charts and compatibility, in both Pythagorean and Chaldean... |
| [`roxy.kabbalah`](https://roxyapi.com/api-reference/kabbalah) | Kabbalah API for gematria, the 72 names, the Tree of Life and the Hebrew birthday |
| [`roxy.tarot`](https://roxyapi.com/api-reference/tarot) | Tarot reading API with the complete 78-card Rider-Waite-Smith deck and card meanings for love, career, health, and sp... |
| [`roxy.biorhythm`](https://roxyapi.com/api-reference/biorhythm) | Biorhythm API for entertainment and reflection, with 10 model cycle types across 3 primary (physical, emotional, inte... |
| [`roxy.ayurveda`](https://roxyapi.com/api-reference/ayurveda) | Ayurveda API for dosha profiles, the dinacharya daily routine and the ritucharya seasonal regimen, with a verse cited... |
| [`roxy.iching`](https://roxyapi.com/api-reference/i-ching) | I-Ching oracle API with all 64 hexagrams, 384 changing lines, 8 trigrams, and modern interpretations for love, career... |
| [`roxy.crystals`](https://roxyapi.com/api-reference/crystals-and-healing-stones) | Crystal healing API covering the most popular and widely-searched healing crystals and gemstones, from Amethyst and R... |
| [`roxy.dreams`](https://roxyapi.com/api-reference/dreams) | Dream interpretation API with a 2,200+ symbol dream dictionary and psychological meanings covering animals, objects,... |
| [`roxy.angelNumbers`](https://roxyapi.com/api-reference/angel-numbers) | Angel numbers API with meanings for 111, 222, 333, 444, 555, 666, 777, 888, 999, 1111, and 75+ sequences covering eve... |
| [`roxy.location`](https://roxyapi.com/api-reference/location-and-timezone) | Timezone and location API with city search and geocoding across 5,180,000+ cities, towns and villages in 240+ countri... |
| [`roxy.usage`](https://roxyapi.com/api-reference/usage) | Monitor your API usage, check rate limits, and track request consumption |
| [`roxy.reports`](https://roxyapi.com/api-reference/reports) | Branded reports built from the API: a natal chart and more as a print-ready PDF, self-contained HTML or Markdown, whi... |
| [`roxy.languages`](https://roxyapi.com/api-reference/languages) | List the response languages accepted by the `lang` query parameter on every i18n-aware endpoint |
<!-- END:DOMAINS -->

## Most-used endpoints

The highest-demand endpoints by domain, in the order you are most likely to ship them. Every example below reads the same birth through a different domain, and every coordinate comes from one location lookup at the top: one API key, one lookup, and eighteen domains that compose into a single product instead of eighteen separate ones. Full catalog in the [API reference](https://roxyapi.com/api-reference).

### Location first: one lookup feeds every chart

Every chart, horoscope, panchang, dasha, dosha, synastry and compatibility endpoint needs `latitude`, `longitude` and `timezone`. Never ask users to type coordinates. Look the city up once and reuse the result in every domain below.

<!-- BEGIN:EXAMPLE:location-first -->
```dart
/// One birth: the moment, and the place a city search returned.
final class Birth {
  const Birth(this.date, this.time, this.place);
  final String date;
  final String time;
  final SearchCitiesResponseCitiesItem place;

  num get latitude => place.latitude;
  num get longitude => place.longitude;

  /// The IANA name from the city record. The server resolves it to the DST-correct offset
  /// for the date of each chart.
  NumOrString get timezone => NumOrString.string(place.timezone);
}

Future<(Birth, Birth)> location(Roxy roxy) async {
  // One lookup feeds every chart below.
  final newYork = await roxy.location.searchCities(q: 'New York');
  final birth = Birth('1990-01-15', '14:30:00', newYork.cities.first);

  // A second person for the two-chart calls (synastry, Guna Milan, Human Design connection).
  final london = await roxy.location.searchCities(q: 'London');
  final partner = Birth('1992-07-22', '09:00:00', london.cities.first);
  return (birth, partner);
}
```
<!-- END:EXAMPLE:location-first -->

### 1. Western astrology API (natal chart, daily horoscope, synastry)

Natal chart products, daily horoscope features, dating and compatibility apps, and lunar-cycle wellness apps start here.

<!-- BEGIN:EXAMPLE:most-used-astrology -->
```dart
// Natal chart. The most requested Western call, run once at onboarding.
final natal = await roxy.astrology.generateNatalChart(
  date: birth.date,
  time: birth.time,
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('${natal.ascendant.sign} rising, Sun in ${natal.planets.first.sign}');

// Daily horoscope. The highest per-user call frequency in the catalog.
final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.aries);
print('${horoscope.overview} Lucky number ${horoscope.luckyNumber}');

// Synastry. Full inter-aspect analysis between two charts.
final synastry = await roxy.astrology.calculateSynastry(
  person1: CalculateSynastryRequestPerson1(
    date: birth.date,
    time: birth.time,
    latitude: birth.latitude,
    longitude: birth.longitude,
    timezone: birth.timezone,
  ),
  person2: CalculateSynastryRequestPerson2(
    date: partner.date,
    time: partner.time,
    latitude: partner.latitude,
    longitude: partner.longitude,
    timezone: partner.timezone,
  ),
);
print('Compatibility ${synastry.compatibilityScore}');

// Moon phase. A zero-setup GET for wellness, cycle-tracking and meditation apps.
final moon = await roxy.astrology.getCurrentMoonPhase();
print('${moon.phase}, ${moon.illumination}% lit, in ${moon.sign}');
```
<!-- END:EXAMPLE:most-used-astrology -->

### 2. Vedic astrology API (kundli, panchang, dasha, Guna Milan, KP)

Kundli generators, matrimonial matching, muhurta and panchang apps, and KP practitioners. The same birth, read sidereally.

<!-- BEGIN:EXAMPLE:most-used-vedic-astrology -->
```dart
// Vedic kundli. The same birth read sidereally.
final kundli = await roxy.vedicAstrology.generateBirthChart(
  date: birth.date,
  time: birth.time,
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('Moon in ${kundli.meta['Moon']?.rashi}');

// Detailed panchang. Tithi, nakshatra, yoga, karana and the muhurtas for a date and place.
final panchang = await roxy.vedicAstrology.getDetailedPanchang(
  date: '2026-10-01',
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('Tithi ${panchang.tithi.name}, nakshatra ${panchang.nakshatra.name}');

// Vimshottari dasha. The periods running right now.
final dasha = await roxy.vedicAstrology.getCurrentDasha(
  date: birth.date,
  time: birth.time,
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print(
  '${dasha.mahadasha.planet} mahadasha, ${dasha.antardasha.planet} antardasha',
);

// Mangal Dosha. The most asked matrimonial check.
final dosha = await roxy.vedicAstrology.checkManglikDosha(
  date: birth.date,
  time: birth.time,
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('Manglik: ${dosha.present}');

// Guna Milan. The 36-point Ashtakoota score behind kundli matching.
final milan = await roxy.vedicAstrology.calculateGunMilan(
  person1: CompatibilityRequestPerson1(
    date: birth.date,
    time: birth.time,
    latitude: birth.latitude,
    longitude: birth.longitude,
    timezone: birth.timezone,
  ),
  person2: CompatibilityRequestPerson2(
    date: partner.date,
    time: partner.time,
    latitude: partner.latitude,
    longitude: partner.longitude,
    timezone: partner.timezone,
  ),
);
print('Guna Milan ${milan.total} of 36');

// KP ruling planets. Horary answers at the moment of the question.
final kp = await roxy.vedicAstrology.getKpRulingPlanets(
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('Day lord ${kp.dayLord}');
```
<!-- END:EXAMPLE:most-used-vedic-astrology -->

### 3. Astrology forecast API (transit forecast, cross-domain timeline)

Forecast feeds, transit alerts and timing tools. One call returns a dated, significance-scored event list; the timeline variant merges Vedic dasha boundaries and biorhythm critical days into the same list, which no single-domain API can do.

<!-- BEGIN:EXAMPLE:most-used-forecast -->
```dart
// Transit forecast. Transit-to-natal aspects, sign ingresses and retrograde stations.
final transits = await roxy.forecast.forecastTransits(
  birthData: ForecastTransitsRequestBirthData(
    date: birth.date,
    time: birth.time,
    latitude: birth.latitude,
    longitude: birth.longitude,
    timezone: birth.timezone,
  ),
  startDate: '2026-10-01',
  endDate: '2026-10-31',
);
print('${transits.count} transit events');

// Cross-domain timeline. The same window with Vedic dasha boundaries and biorhythm
// critical days merged in.
final timeline = await roxy.forecast.generateTimeline(
  birthData: GenerateTimelineRequestBirthData(
    date: birth.date,
    time: birth.time,
    latitude: birth.latitude,
    longitude: birth.longitude,
    timezone: birth.timezone,
  ),
  startDate: '2026-10-01',
  endDate: '2026-10-31',
);
print('First event: ${timeline.events.first.description}');
```
<!-- END:EXAMPLE:most-used-forecast -->

### 4. Human Design API (bodygraph, connection)

Self-discovery apps, coaching bots and compatibility products. The full bodygraph is one call, and the Design side is solved on the exact 88-degree solar arc rather than approximated as calendar days.

<!-- BEGIN:EXAMPLE:most-used-human-design -->
```dart
// Bodygraph. Type, strategy, authority, profile, centers, channels and gates in one call.
final hd = await roxy.humanDesign.generateBodygraph(
  date: birth.date,
  time: birth.time,
  timezone: birth.timezone,
);
print('${hd.type}, ${hd.strategy}, ${hd.authority}, profile ${hd.profile}');

// Connection. Two bodygraphs combined, each channel classified by how the pair forms it.
final connection = await roxy.humanDesign.calculateConnection(
  personA: CalculateConnectionRequestPersonA(
    date: birth.date,
    time: birth.time,
    timezone: birth.timezone,
  ),
  personB: CalculateConnectionRequestPersonB(
    date: partner.date,
    time: partner.time,
    timezone: partner.timezone,
  ),
);
print('${connection.totalChannels} channels');
```
<!-- END:EXAMPLE:most-used-human-design -->

### 5. Chinese zodiac API (BaZi four pillars, zodiac animal, almanac)

BaZi readings, zodiac content and Tong Shu date pages. The school splits that make two calculators disagree (`dayBoundary`, `yearBoundary`, `hourClock`) are typed request parameters with named defaults.

<!-- BEGIN:EXAMPLE:most-used-chinese-astrology -->
```dart
// BaZi Four Pillars. Each response echoes the conventions it was computed under.
final bazi = await roxy.chineseAstrology.generateBaziChart(
  date: birth.date,
  time: birth.time,
  timezone: birth.timezone,
);
print('Day master ${bazi.dayMaster.element}, ${bazi.zodiacAnimal}');

// Chinese zodiac animal. Defaults to the Lunar New Year boundary.
final animal = await roxy.chineseAstrology.calculateZodiacAnimal(
  date: birth.date,
);
print('${animal.animal.name} (${animal.animal.element})');

// Almanac day. The Tong Shu view of a date.
final almanac = await roxy.chineseAstrology.getAlmanacDay(date: '2026-10-01');
print('Clash animal ${almanac.clashAnimal}');
```
<!-- END:EXAMPLE:most-used-chinese-astrology -->

### 6. Feng shui API (Kua number, flying star chart)

Kua numbers with the Eight Mansions map, Xuan Kong flying star charts for any of the nine periods and 24 mountains, annual and monthly star plates, and the annual afflictions.

<!-- BEGIN:EXAMPLE:most-used-feng-shui -->
```dart
// Kua number. One birth date and a gender give the personal directions.
final kua = await roxy.fengShui.calculateKuaNumber(
  date: birth.date,
  gender: Gender.female,
);
print('Kua ${kua.kua}, ${kua.group} group');

// Flying star natal chart. Period plus facing gives the nine palaces.
final stars = await roxy.fengShui.generateFlyingStarChart(
  period: 9,
  facing: GenerateFlyingStarChartFacing.bing,
);
print('Facing ${stars.facing.label}, ${stars.palaces.length} palaces');
```
<!-- END:EXAMPLE:most-used-feng-shui -->

### 7. Mayan astrology API (Tzolkin day sign, full Maya chart)

Maya day signs, the Haab and Long Count, and the Aztec tonalpohualli, every value a function of the date under a typed `correlation` convention echoed back in `conventions`.

<!-- BEGIN:EXAMPLE:most-used-mesoamerican-astrology -->
```dart
// Tzolkin day sign. The most asked Maya question, answered from a date alone.
final tzolkin = await roxy.mesoamericanAstrology.calculateTzolkin(
  date: birth.date,
);
print('${tzolkin.number} ${tzolkin.daySignName}');

// Full Maya chart. Tzolkin, Haab, Long Count, Calendar Round and Year Bearer.
final maya = await roxy.mesoamericanAstrology.generateMayanChart(
  date: birth.date,
);
print('Long Count ${maya.longCount.formatted}');
```
<!-- END:EXAMPLE:most-used-mesoamerican-astrology -->

### 8. Vastu Shastra API (entrance analysis, room compliance)

Home and plot analysis from typed geometry. Every verdict carries a `source` object naming the text, chapter and verse it rests on, or a convention label where the texts are silent.

<!-- BEGIN:EXAMPLE:most-used-vastu -->
```dart
// Entrance analysis. Plot, facing and door in; the pada, its devata and the effect out.
final entrance = await roxy.vastu.calculateEntrancePada(
  plot: CalculateEntrancePadaRequestPlot(
    width: 30,
    depth: 40,
    unit: Unit.feet,
  ),
  facing: GenerateEightMansionsFacing.north,
  doorPosition: 0.4,
);
print('Pada ${entrance.pada}, ${entrance.devata?.name}: ${entrance.effect}');

// Room compliance. A verdict per room with the verse or convention it rests on.
final rooms = await roxy.vastu.calculateRoomCompliance(
  plot: CalculateRoomComplianceRequestPlot(
    width: 30,
    depth: 40,
    unit: Unit.feet,
  ),
  facing: GenerateEightMansionsFacing.north,
  rooms: [
    CalculateRoomComplianceRequestRoomsItem(
      type: CalculateRoomComplianceType.kitchen,
      direction: Direction.southeast,
    ),
    CalculateRoomComplianceRequestRoomsItem(
      type: CalculateRoomComplianceType.puja,
      direction: Direction.northeast,
    ),
  ],
);
print('Score ${rooms.score}, kitchen ${rooms.rooms.first.verdict}');
```
<!-- END:EXAMPLE:most-used-vastu -->

### 9. Numerology API (life path, full chart, personal year)

Works from the birth date and name alone, no coordinates, which makes it the easiest domain to integrate.

<!-- BEGIN:EXAMPLE:most-used-numerology -->
```dart
// Life Path. The most searched numerology number, from the birth date alone.
final lifePath = await roxy.numerology.calculateLifePath(
  year: 1990,
  month: 1,
  day: 15,
);
print('Life Path ${lifePath.number} (${lifePath.type})');

// Full numerology chart. The core numbers, karmic lessons and pinnacles in one call.
final chart = await roxy.numerology.generateNumerologyChart(
  fullName: 'Jane Smith',
  year: 1990,
  month: 1,
  day: 15,
);
print('Expression ${chart.coreNumbers.expression.number}');

// Personal Year. The annual theme.
final personalYear = await roxy.numerology.calculatePersonalYear(
  month: 1,
  day: 15,
  year: 2026,
);
print('Personal Year ${personalYear.personalYear}: ${personalYear.theme}');
```
<!-- END:EXAMPLE:most-used-numerology -->

### 10. Kabbalah API (gematria, birth profile)

Gematria of a Latin name under a declared transliteration convention, the 72 names, the Tree of Life, and a Hebrew birthday computed from the same birth instant as every chart above.

<!-- BEGIN:EXAMPLE:most-used-kabbalah -->
```dart
// Gematria. A Latin name transliterated under a declared convention, ten ciphers.
final gematria = await roxy.kabbalah.calculateGematria(text: 'Sarah');
print(
  '${gematria.chosen.hebrew}: ${gematria.values.first.name} ${gematria.values.first.value}',
);

// Birth profile. The Hebrew date, the three birth angels and the birth sephirah.
final profile = await roxy.kabbalah.generateBirthProfile(
  date: birth.date,
  time: birth.time,
  timezone: birth.timezone,
);
print('Hebrew date ${profile.hebrewDate.day} ${profile.hebrewDate.month}');
```
<!-- END:EXAMPLE:most-used-kabbalah -->

### 11. Tarot API (daily card, three-card, Celtic Cross, yes or no)

The complete 78-card deck with meanings for love, career, health and spirit. Pass a `seed` per user for deterministic once-per-day draws.

<!-- BEGIN:EXAMPLE:most-used-tarot -->
```dart
// Daily card. The same seed and date always return the same card.
final daily = await roxy.tarot.getDailyCard(seed: 'user-42');
print('${daily.card.name}${daily.card.reversed ? ' (reversed)' : ''}');

// Three-card spread. Past, present, future.
final three = await roxy.tarot.castThreeCard(
  question: 'My next quarter',
  seed: 'user-42',
);
for (final position in three.positions) {
  print('${position.name}: ${position.card.name}');
}

// Celtic Cross. The ten-position professional reading.
final celtic = await roxy.tarot.castCelticCross(
  question: 'What should I focus on?',
);
print(celtic.summary);

// Yes or no. One card, one answer, with its strength.
final answer = await roxy.tarot.castYesNo(
  question: 'Should I take the offer?',
);
print('${answer.answer} (${answer.strength}), ${answer.card.name}');
```
<!-- END:EXAMPLE:most-used-tarot -->

### 12. Biorhythm API (reading, forecast)

Ten cycle types across primary, secondary and extended cycles, for wellness, productivity, sports and couples apps.

<!-- BEGIN:EXAMPLE:most-used-biorhythm -->
```dart
// Biorhythm reading. All ten cycles for a date.
final reading = await roxy.biorhythm.getReading(
  birthDate: birth.date,
  targetDate: '2026-10-01',
);
print(
  'Physical ${reading.cycles['physical']?.value}, energy ${reading.energyRating}',
);

// Forecast. Every cycle for every day of a window, with the best and worst days named.
final window = await roxy.biorhythm.getForecast(
  birthDate: birth.date,
  startDate: '2026-10-01',
  endDate: '2026-10-31',
);
print('Best day ${window.summary.bestDay}');
```
<!-- END:EXAMPLE:most-used-biorhythm -->

### 13. Ayurveda API (dosha constitution, dinacharya)

The dosha profile read from a verified sidereal chart with the verse on each factor, a daily routine anchored on the local sunrise, and the six seasons from real solar ingresses. Every response carries `meta.disclaimer`.

<!-- BEGIN:EXAMPLE:most-used-ayurveda -->
```dart
// Constitution. The dosha profile read from the sidereal chart of the same birth.
final constitution = await roxy.ayurveda.calculateAyurvedicConstitution(
  date: birth.date,
  time: birth.time,
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('Dominant ${constitution.composite.dominant}');

// Dinacharya. Brahma muhurta, the dosha periods and the routine for a date and place.
final dinacharya = await roxy.ayurveda.getDinacharyaSchedule(
  date: '2026-10-01',
  latitude: birth.latitude,
  longitude: birth.longitude,
  timezone: birth.timezone,
);
print('Brahma muhurta ${dinacharya.brahmaMuhurta.start}');
```
<!-- END:EXAMPLE:most-used-ayurveda -->

### 14. I Ching API (cast a reading, hexagram catalog)

All 64 hexagrams, 384 changing lines and 8 trigrams, for meditation apps, decision tools and wisdom chatbots.

<!-- BEGIN:EXAMPLE:most-used-iching -->
```dart
// Cast a reading. The primary hexagram, the changing lines and the resulting hexagram.
final reading = await roxy.iching.castReading(seed: 'user-42');
print('Hexagram ${reading.hexagram?.number}, ${reading.hexagram?.english}');

// Hexagram catalog. Ask for all 64 once and cache them.
final catalog = await roxy.iching.listHexagrams(limit: 64);
print('${catalog.total} hexagrams');
```
<!-- END:EXAMPLE:most-used-iching -->

### 15. Crystal healing API (by zodiac, by chakra, birthstone)

Crystal retail and metaphysical content: "crystals for [sign]" and "[chakra] chakra stones" pages, plus the birthstone for each month.

<!-- BEGIN:EXAMPLE:most-used-crystals -->
```dart
// By zodiac. The most searched crystal query pattern.
final bySign = await roxy.crystals.getCrystalsByZodiac(sign: Sign.scorpio);
print(bySign.crystals.map((c) => c.name).join(', '));

// By chakra. Wellness and yoga content pages.
final byChakra = await roxy.crystals.getCrystalsByChakra(
  chakra: Chakra.heart,
);
print(byChakra.crystals.first.name);

// Birthstone. Evergreen gift and jewelry pages.
final birthstone = await roxy.crystals.getBirthstones(month: 1);
print(birthstone.crystals.first.name);
```
<!-- END:EXAMPLE:most-used-crystals -->

### 16. Dream interpretation API (symbol dictionary, search)

A 2,000+ symbol dream dictionary for journal apps, AI companions and self-discovery products.

<!-- BEGIN:EXAMPLE:most-used-dreams -->
```dart
// Symbol detail. Every "what does it mean to dream about X" page lands here.
final symbol = await roxy.dreams.getDreamSymbol(id: 'flying');
print('${symbol.name}: ${symbol.meaning}');

// Symbol search. Chatbots fetch the dictionary once and keep it locally.
final symbols = await roxy.dreams.searchDreamSymbols(q: 'water');
print(symbols.symbols.map((s) => s.name).join(', '));
```
<!-- END:EXAMPLE:most-used-dreams -->

### 17. Angel numbers API (1111, 222, 333 meanings plus universal lookup)

Meanings for every common sequence, and a lookup that answers any positive integer through its digit root.

<!-- BEGIN:EXAMPLE:most-used-angel-numbers -->
```dart
// By number. Every "meaning of 1111" page is backed by this. The number is a string.
final angel = await roxy.angelNumbers.getAngelNumber(number: '1111');
print('${angel.title}: ${angel.coreMessage}');

// Universal lookup. Any positive integer, the digit root answers when nothing is curated.
final sequence = await roxy.angelNumbers.analyzeNumberSequence(
  number: '4242',
);
print(
  'Digit root ${sequence.digitRoot}, ${sequence.knownMeaning?.title ?? 'not curated'}',
);
```
<!-- END:EXAMPLE:most-used-angel-numbers -->

## Built for AI agents (Cursor, Claude Code, Copilot, Codex, Gemini CLI)

<p align="center">
  <img src="https://raw.githubusercontent.com/RoxyAPI/sdk-dart/main/assets/agents.png" alt="Your coding agent, ready for Dart. The Spiritual OS layer for agentic AI. One key, flat pricing." width="100%">
</p>

This package ships with bundled documentation that AI coding agents read directly from the installed package:

- [AGENTS.md](https://github.com/RoxyAPI/sdk-dart/blob/main/AGENTS.md) for quick start, patterns, gotchas, common-tasks reference
- [doc/llms-full.txt](https://github.com/RoxyAPI/sdk-dart/blob/main/doc/llms-full.txt) for the complete method reference with examples per domain

Point your coding agent to `AGENTS.md` in the installed `roxyapi` package (the package root listed for `roxyapi` in `.dart_tool/package_config.json`) for the installed package guide.

Prefer MCP? Every domain has a [Remote MCP server](https://roxyapi.com/docs/mcp) at `https://roxyapi.com/mcp/{domain}` (Streamable HTTP, no stdio, no self-hosting). One-line Claude Code setup:

```bash
claude mcp add-json --scope user roxy-astrology \
  '{"type":"http","url":"https://roxyapi.com/mcp/astrology","headers":{"X-API-Key":"YOUR_KEY"}}'
```

## Authentication

Get your API key at [roxyapi.com/pricing](https://roxyapi.com/pricing). Instant delivery after checkout.

Never expose your API key client-side. Call Roxy from server code only; a Flutter app gets its data from your backend (see Flutter).

Pass your own HTTP client to share a connection pool, add logging or route through a proxy, and a `timeout` to cap one call with every retry included. `close()` leaves a client you passed open:

<!-- BEGIN:EXAMPLE:authentication -->
```dart
final client = http.Client();
final roxy = Roxy(
  Platform.environment['ROXY_API_KEY'] ?? '',
  client: client,
  timeout: const Duration(seconds: 20),
);
final moon = await roxy.astrology.getCurrentMoonPhase();
print('${moon.phase} in ${moon.sign}');
client.close();
```
<!-- END:EXAMPLE:authentication -->

## Multi-language responses

<!-- BEGIN:LANGS -->
**Multi-language responses.** Interpretations and editorial text are available in 10 languages: `en`, `tr`, `de`, `es`, `hi`, `pt`, `fr`, `ru`, `zh-Hans`, `zh-Hant`. Pass a `Lang` value as `lang` on a supported method. Supported: `astrology`, `vedicAstrology`, `forecast`, `humanDesign`, `chineseAstrology`, `fengShui`, `mesoamericanAstrology`, `vastu`, `numerology`, `kabbalah`, `tarot`, `biorhythm`, `ayurveda`, `iching`, `crystals`, `angelNumbers`, `reports`, `languages`. English-only: `dreams`, `location`, `usage`. A field without a translation in the requested language returns English.
<!-- END:LANGS -->

<!-- BEGIN:EXAMPLE:languages -->
```dart
final card = await roxy.tarot.getDailyCard(
  seed: 'user-42',
  date: '2026-04-22',
);
final hindi = await roxy.tarot.getDailyCard(
  seed: 'user-42',
  date: '2026-04-22',
  lang: Lang.hi,
);
print('${card.card.name}: ${card.dailyMessage}');
print('${hindi.card.name}: ${hindi.dailyMessage}');
```
<!-- END:EXAMPLE:languages -->

## Error handling

Every method returns the typed response on a 2xx and throws `RoxyException` on a 4xx or 5xx, carrying `statusCode`, `code`, `message`, `docUrl`, `retryAfter`, the decoded `body`, and `issues`: every failing field of a validation error as a typed `ValidationIssue`.

<!-- BEGIN:EXAMPLE:errors -->
```dart
try {
  await roxy.astrology.generateNatalChart(
    date: '1990-13-45',
    time: '14:30:00',
    latitude: 51.5074,
    longitude: -0.1278,
    timezone: const NumOrString.string('Europe/London'),
  );
} on RoxyException catch (e) {
  print('${e.statusCode} ${e.code}: ${e.message} (${e.docUrl})');
  for (final issue in e.issues) {
    print('${issue.path}: ${issue.message}');
  }
}
```
<!-- END:EXAMPLE:errors -->

<!-- BEGIN:ERRORS -->
Every error returns `{ error, code, doc_url }`, thrown as `RoxyException` with `statusCode`, `code`, `message` and `docUrl`. Switch on `code`; `message` is readable text and may change. Each meaning below says whether and when to retry, and `retryAfter` carries the wait when the response sends it. Every code is documented at https://roxyapi.com/docs/errors.

| Status | Code | Meaning |
|--------|------|---------|
| 400 | `validation_error` | A field is missing or invalid. The body lists every failing field at once in issues, each with its path and the expected shape. |
| 400 | `bad_request` | The request was rejected as a whole, for example a body that is not valid JSON or a date range that ends before it starts. |
| 400 | `date_out_of_range` | A date lies outside the span the planetary positions are served for. The error names the supported dates. |
| 400 | `invalid_branding` | The report branding cannot be used, for example a logo that is not a PNG, JPEG, WebP or SVG image. |
| 400 | `logo_fetch_failed` | The report logo could not be fetched: it must be an HTTPS URL on a public host that answers within the size limit. |
| 400 | `unsupported_character` | The report text holds a character no report font draws. The error names it: remove or replace it. |
| 401 | `api_key_required` | No API key was sent. |
| 401 | `invalid_api_key` | The key sent is malformed or cannot be verified. |
| 401 | `api_key_revoked` | The key was valid once and has since been revoked from the account page. |
| 401 | `subscription_not_found` | The key verifies, but the subscription behind it no longer exists. |
| 401 | `subscription_inactive` | The subscription behind the key is cancelled, expired or suspended, or a trial is past its end date. |
| 401 | `publishable_key_not_allowed_on_mcp` | A publishable key was used on a Remote MCP server, which takes a secret key. |
| 401 | `invalid_client_ip` | A keyless request could not be attributed to a caller. |
| 401 | `unauthorized` | Authentication failed with no more specific reason to give. |
| 403 | `forbidden` | The key is valid, but this request is not permitted. |
| 403 | `origin_required` | A publishable key with an origin allowlist was used with no Origin header, as from a server or a native app. |
| 403 | `origin_not_allowed` | The calling site is not on the origin allowlist of this publishable key. |
| 404 | `not_found` | Nothing is served at this path, or the identifier in it does not exist. A path miss adds suggestions, the closest real endpoints. |
| 405 | `method_not_allowed` | The path exists for a different HTTP method. The body lists the accepted methods in allow, as does the Allow header. |
| 409 | `conflict` | The request cannot be applied in the current state. |
| 410 | `gone` | The path was removed permanently. |
| 413 | `payload_too_large` | The request body is larger than the API accepts. A body far over the cap is refused before it reaches the API and returns a bare 413 with no JSON body. |
| 415 | `unsupported_media_type` | A request with a body was sent without Content-Type: application/json. |
| 422 | `unprocessable_entity` | Every field is valid, but the combination cannot be computed. |
| 429 | `rate_limit_exceeded` | The monthly request allowance is used up. Retry-After gives the seconds to the reset. |
| 429 | `rate_limit_per_minute` | The per-minute limit of the plan was reached. Retry-After gives the seconds to the next minute, and the monthly allowance is not charged. |
| 429 | `rate_limited` | A rate limit was reached, reported without the plan detail. |
| 429 | `free_tier_exhausted` | A keyless request has used up its trial allowance. |
| 429 | `reports_rate_limited` | Too many reports were requested this minute. Retry-After gives the seconds to the next minute. |
| 500 | `internal_error` | The request failed inside our service. Retry with exponential backoff. |
| 503 | `compute_saturated` | Heavy calculations are briefly at capacity. Send the same request again after Retry-After seconds. |
| 503 | `reports_busy` | Report rendering is briefly at capacity. Send the same request again after Retry-After seconds. |
| 503 | `report_render_timeout` | The report took too long to render. Send the same request again. |
| Any | `error` | A fallback for a status with no more specific code. The status and the error field carry the signal. |
<!-- END:ERRORS -->

### Retries

Retries are on by default: a request is resent up to twice after a 429, 500, 502, 503 or 504, or after a connection that was never made (refused or unresolvable host). Pass `maxRetries` to change the count, or `maxRetries: 0` to turn retries off. A read timeout is never retried. The wait follows `Retry-After` when the response sends it, and a full-jitter backoff otherwise (`initialDelay` 500 ms, `maxDelay` 30 s by default). A `Retry-After` longer than `maxDelay`, such as the wait for a monthly allowance, is not waited for: the error comes back at once. A `timeout` stops any wait that would outlast it. On a persistent failure the total is 1 + `maxRetries` requests, so 3 by default and exactly 1 with `maxRetries: 0`.

<!-- BEGIN:EXAMPLE:retries -->
```dart
final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '', maxRetries: 4);
try {
  final horoscope = await roxy.astrology.getDailyHoroscope(sign: Sign.leo);
  print(horoscope.love);
} on RoxyException catch (e) {
  if (e.code == ErrorCodes.rateLimitPerMinute ||
      e.code == ErrorCodes.computeSaturated) {
    print('retry in ${e.retryAfter?.inSeconds} seconds');
  } else {
    print('${e.statusCode} ${e.code} ${e.docUrl}');
  }
} finally {
  roxy.close();
}
```
<!-- END:EXAMPLE:retries -->

`ErrorCodes` holds every code as a constant (`ErrorCodes.rateLimitPerMinute` is `'rate_limit_per_minute'`), and `code` stays a plain string, so a code added later still arrives intact. `retryAfter` is the `Retry-After` wait as a `Duration`, or `null` when the response has none.

## Dart

Every request and response is typed. Parameters are named, in the order path, body, query, then `lang`, and a parameter with a fixed set of values is a Dart enum (`Sign.aries`, `HouseSystem.wholeSign`, `Lang.hi`). A response is a zero-copy view over its JSON: getters are typed, a field added to the API later never breaks decoding, and `json` hands back the raw map to cache, log or pass on. `NatalChartResponse.fromJson(map)` reads a response you stored. Runs on every Dart platform: Flutter on Android, iOS, web and desktop, servers, and the command line.

## Flutter

Keep the API key on your backend. The backend calls Roxy with this SDK and returns the response JSON to the app:

<!-- BEGIN:EXAMPLE:flutter-server -->
```dart
final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '');
final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
await for (final request in server) {
  final query = request.uri.queryParameters;
  final places = await roxy.location.searchCities(
    q: query['city'] ?? 'Paris',
  );
  final place = places.cities.first;
  final chart = await roxy.astrology.generateNatalChart(
    date: query['date'] ?? '1990-01-15',
    time: query['time'] ?? '14:30:00',
    latitude: place.latitude,
    longitude: place.longitude,
    timezone: NumOrString.string(place.timezone),
  );
  request.response
    ..headers.contentType = ContentType.json
    ..headers.set('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode(chart.json));
  await request.response.close();
}
```
<!-- END:EXAMPLE:flutter-server -->

The app reads that JSON into the same typed model, with no key inside the app. Import the package with a prefix in Flutter code so its model names sit beside the widget names:

<!-- BEGIN:EXAMPLE:flutter-app -->
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roxyapi/roxyapi.dart' as roxy;

import 'natal_chart_view.dart';

/// Your backend, which holds the API key and returns the chart JSON.
const backend = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:8080',
);

Future<roxy.NatalChartResponse> fetchChart() async {
  final response = await http.get(
    Uri.parse('$backend/?city=Paris&date=1990-01-15'),
  );
  final json = jsonDecode(utf8.decode(response.bodyBytes));
  if (json is! Map<String, Object?>) {
    throw const FormatException('expected a chart object');
  }
  return roxy.NatalChartResponse.fromJson(json);
}
```
<!-- END:EXAMPLE:flutter-app -->

The full app is in [example/flutter_app](https://github.com/RoxyAPI/sdk-dart/tree/main/example/flutter_app).

## Rendering with @roxyapi/ui

[@roxyapi/ui](https://www.npmjs.com/package/@roxyapi/ui) draws a response as a finished, themed chart: fetch with this SDK, hand the JSON to a component such as `roxy-natal-chart`, and the page holds data only, never a key. Every component is listed at [roxyapi.com/docs/ui](https://roxyapi.com/docs/ui).

<!-- BEGIN:EXAMPLE:flutter-render -->
```dart
return Column(
  children: [
    Text('${chart.ascendant.sign} rising'),
    Expanded(child: NatalChartView(chart)),
  ],
);
```
<!-- END:EXAMPLE:flutter-render -->

On Flutter web, `HtmlElementView` creates the element and sets its `data` property; `web/index.html` loads the same script the mobile view uses:

<!-- BEGIN:EXAMPLE:ui-web -->
```dart
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:roxyapi/roxyapi.dart' as roxy;
import 'package:web/web.dart' as web;

@JS('JSON.parse')
external JSAny? _parse(String text);

extension on web.HTMLElement {
  /// The response the component renders.
  external set data(JSAny? value);
}

/// The chart drawn by the `roxy-natal-chart` component, loaded by `web/index.html`.
class NatalChartView extends StatelessWidget {
  const NatalChartView(this.chart, {super.key});

  final roxy.NatalChartResponse chart;

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'roxy-natal-chart',
    onElementCreated: (element) {
      // On the web the created platform view is a DOM element.
      (element as web.HTMLElement).data = _parse(jsonEncode(chart.json));
    },
  );
}
```
<!-- END:EXAMPLE:ui-web -->

On Android and iOS, a WebView renders a page holding the component and the chart data:

<!-- BEGIN:EXAMPLE:ui-mobile -->
```dart
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:roxyapi/roxyapi.dart' as roxy;
import 'package:webview_flutter/webview_flutter.dart';

const roxyUi = 'https://cdn.jsdelivr.net/npm/@roxyapi/ui@1/dist/cdn/roxy-ui.js';

/// The chart drawn by the `roxy-natal-chart` component inside a WebView.
class NatalChartView extends StatefulWidget {
  const NatalChartView(this.chart, {super.key});

  final roxy.NatalChartResponse chart;

  @override
  State<NatalChartView> createState() => _NatalChartViewState();
}

class _NatalChartViewState extends State<NatalChartView> {
  late final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(page(widget.chart));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: controller);
}

/// A page holding the chart data and nothing else: no key ever reaches the WebView.
String page(roxy.NatalChartResponse chart) {
  // Escaped so no string inside the chart can close the data block.
  final data = jsonEncode(chart.json)
      .replaceAll('<', r'\u003c')
      .replaceAll('>', r'\u003e')
      .replaceAll('&', r'\u0026');
  return '<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1">'
      '<script src="$roxyUi" defer></script>'
      '<roxy-natal-chart><script type="application/json" class="roxy-data">$data</script>'
      '</roxy-natal-chart>';
}
```
<!-- END:EXAMPLE:ui-mobile -->

## Links

- [Documentation](https://roxyapi.com/docs)
- [API Reference](https://roxyapi.com/api-reference)
- [Pricing](https://roxyapi.com/pricing)
- [MCP setup for AI agents](https://roxyapi.com/docs/mcp)
- [Templates](https://roxyapi.com/templates)
- [Issues](https://github.com/RoxyAPI/sdk-dart/issues)
- Other SDKs: [TypeScript](https://www.npmjs.com/package/@roxyapi/sdk), [Python](https://pypi.org/project/roxy-sdk/), [PHP](https://packagist.org/packages/roxyapi/sdk), [.NET](https://www.nuget.org/packages/RoxyApi.Sdk), [Go](https://pkg.go.dev/github.com/RoxyAPI/sdk-go), [Rust](https://crates.io/crates/roxyapi)

## License

MIT
