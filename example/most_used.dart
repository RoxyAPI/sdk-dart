import 'dart:io';

import 'package:roxyapi/roxyapi.dart';

/// Runs every call of the Most-used endpoints section and prints a named field of each.
///
/// ```bash
/// ROXY_API_KEY=your_key dart run example/most_used.dart
/// ```
Future<void> main() async {
  final roxy = Roxy(Platform.environment['ROXY_API_KEY'] ?? '');
  try {
    final (birth, partner) = await location(roxy);
    await astrology(roxy, birth, partner);
    await vedicAstrology(roxy, birth, partner);
    await forecast(roxy, birth);
    await humanDesign(roxy, birth, partner);
    await chineseAstrology(roxy, birth);
    await fengShui(roxy, birth);
    await mesoamericanAstrology(roxy, birth);
    await vastu(roxy);
    await numerology(roxy);
    await kabbalah(roxy, birth);
    await tarot(roxy);
    await biorhythm(roxy, birth);
    await ayurveda(roxy, birth);
    await iching(roxy);
    await crystals(roxy);
    await dreams(roxy);
    await angelNumbers(roxy);
  } finally {
    roxy.close();
  }
}

// #docregion location-first
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
// #enddocregion location-first

Future<void> astrology(Roxy roxy, Birth birth, Birth partner) async {
  // #docregion most-used-astrology
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
  // #enddocregion most-used-astrology
}

Future<void> vedicAstrology(Roxy roxy, Birth birth, Birth partner) async {
  // #docregion most-used-vedic-astrology
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
  // #enddocregion most-used-vedic-astrology
}

Future<void> forecast(Roxy roxy, Birth birth) async {
  // #docregion most-used-forecast
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
  // #enddocregion most-used-forecast
}

Future<void> humanDesign(Roxy roxy, Birth birth, Birth partner) async {
  // #docregion most-used-human-design
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
  // #enddocregion most-used-human-design
}

Future<void> chineseAstrology(Roxy roxy, Birth birth) async {
  // #docregion most-used-chinese-astrology
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
  // #enddocregion most-used-chinese-astrology
}

Future<void> fengShui(Roxy roxy, Birth birth) async {
  // #docregion most-used-feng-shui
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
  // #enddocregion most-used-feng-shui
}

Future<void> mesoamericanAstrology(Roxy roxy, Birth birth) async {
  // #docregion most-used-mesoamerican-astrology
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
  // #enddocregion most-used-mesoamerican-astrology
}

Future<void> vastu(Roxy roxy) async {
  // #docregion most-used-vastu
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
  // #enddocregion most-used-vastu
}

Future<void> numerology(Roxy roxy) async {
  // #docregion most-used-numerology
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
  // #enddocregion most-used-numerology
}

Future<void> kabbalah(Roxy roxy, Birth birth) async {
  // #docregion most-used-kabbalah
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
  // #enddocregion most-used-kabbalah
}

Future<void> tarot(Roxy roxy) async {
  // #docregion most-used-tarot
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
  // #enddocregion most-used-tarot
}

Future<void> biorhythm(Roxy roxy, Birth birth) async {
  // #docregion most-used-biorhythm
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
  // #enddocregion most-used-biorhythm
}

Future<void> ayurveda(Roxy roxy, Birth birth) async {
  // #docregion most-used-ayurveda
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
  // #enddocregion most-used-ayurveda
}

Future<void> iching(Roxy roxy) async {
  // #docregion most-used-iching
  // Cast a reading. The primary hexagram, the changing lines and the resulting hexagram.
  final reading = await roxy.iching.castReading(seed: 'user-42');
  print('Hexagram ${reading.hexagram?.number}, ${reading.hexagram?.english}');

  // Hexagram catalog. Ask for all 64 once and cache them.
  final catalog = await roxy.iching.listHexagrams(limit: 64);
  print('${catalog.total} hexagrams');
  // #enddocregion most-used-iching
}

Future<void> crystals(Roxy roxy) async {
  // #docregion most-used-crystals
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
  // #enddocregion most-used-crystals
}

Future<void> dreams(Roxy roxy) async {
  // #docregion most-used-dreams
  // Symbol detail. Every "what does it mean to dream about X" page lands here.
  final symbol = await roxy.dreams.getDreamSymbol(id: 'flying');
  print('${symbol.name}: ${symbol.meaning}');

  // Symbol search. Chatbots fetch the dictionary once and keep it locally.
  final symbols = await roxy.dreams.searchDreamSymbols(q: 'water');
  print(symbols.symbols.map((s) => s.name).join(', '));
  // #enddocregion most-used-dreams
}

Future<void> angelNumbers(Roxy roxy) async {
  // #docregion most-used-angel-numbers
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
  // #enddocregion most-used-angel-numbers
}
