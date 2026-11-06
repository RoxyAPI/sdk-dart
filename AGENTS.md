# roxyapi - Agent Guide

Dart and Flutter SDK for RoxyAPI. 18+ domains (Western astrology, Vedic astrology, forecast, human design, Chinese astrology, feng shui, Mesoamerican astrology, Vastu, numerology, Kabbalah, tarot, biorhythm, Ayurveda, I Ching, crystals, dreams, angel numbers, location) plus utility namespaces (usage, reports, languages). One API key, fully typed, one runtime dependency (`package:http`).

> Before writing any code with this SDK, read `doc/llms-full.txt` in this package for the complete method reference with examples.

## Install and initialize

```bash
dart pub add roxyapi     # Dart
flutter pub add roxyapi  # Flutter
```

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

`Roxy(apiKey)` sets the base URL (`https://roxyapi.com/api/v2`) and the auth header. Every method returns the typed response and throws `RoxyException` on an error response. Call `roxy.close()` when done.

## Critical rule: geocode before any chart endpoint

Every chart, horoscope, panchang, dasha, dosha, navamsa, KP, synastry, compatibility and natal endpoint needs `latitude`, `longitude` and (for Western) `timezone`. **Never ask the user for coordinates.** Always call `roxy.location.searchCities(q: ...)` first and pass `NumOrString.string(city.timezone)`, the IANA name. The server resolves it to the DST-correct offset for the date of the chart, so a January 1990 New York chart gets EST (-5) even when looked up in July. Never pass `utcOffset` (the offset in force today).

`q` accepts a bare city (`'Paris'`), city plus country (`'Berlin Germany'`), or a comma-qualified name (`'Springfield, Illinois'`). Use the qualified form to disambiguate same-named cities.

## Domains

Type `roxy.` to see every namespace and `roxy.{domain}.` to see every method in it.

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

## Quality guidelines for agents

- **Named, flattened parameters.** Every method takes named arguments: path, body and query fields side by side, `lang` last. Right: `roxy.astrology.getDailyHoroscope(sign: Sign.aries)`. Wrong: a map, a `path:` or `body:` wrapper, or positional arguments. Required parameters are `required`; the compiler rejects a missing one.
- **Fixed value sets are Dart enums.** `Sign.aries`, `HouseSystem.wholeSign`, `Lang.hi`, `Chakra.heart`, `GetNakshatraId.ashwini`. A wire value that is a Dart keyword or starts with a digit gets a `$` suffix or a `v` prefix (`NodeType.true$`, `v81Pada`). Never pass the wire string where an enum is typed.
- **A number-or-string field is `NumOrString`.** `timezone` takes `NumOrString.string('Europe/London')` or `NumOrString.number(5.5)`.
- **Nested request objects are generated classes named `{OperationId}Request{Field}`.** `calculateSynastry` takes `person1: CalculateSynastryRequestPerson1(...)` and `person2: CalculateSynastryRequestPerson2(...)`; `forecastTransits` takes `birthData: ForecastTransitsRequestBirthData(...)`. Each operation has its own class even when the fields match. Let autocomplete name it.
- **Method names match the OpenAPI `operationId` verbatim.** Never invent one from the URL path. The compiler and `doc/llms-full.txt` are the reference.
- **Responses are typed views.** Read fields with dot syntax (`chart.ascendant.sign`, `places.cities.first.timezone`). JSON `number` reads as `num` (use `.toInt()` or `.toStringAsFixed(n)` to format), `integer` as `int`. Lists and maps from a response are read-only. `.json` returns the raw map for caching or passing on, and `X.fromJson(map)` reads it back. **Every method's return type and its fields are listed under that method in `doc/llms-full.txt`**; a getter's dartdoc carries its units and scale.
- **Do not hand-roll requests.** No raw `http.get`, no dio. The SDK adds auth, the base URL, typed decoding and retries.
- **Look up anything beyond this guide** in the combined OpenAPI spec at `https://roxyapi.com/api/v2/openapi.json`, or the keyless Docs MCP server at `https://roxyapi.com/mcp/docs` (one tool, `search_docs`).

## Critical patterns

### One lookup feeds every domain

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

Pass the same `birth` fields to `astrology.generateNatalChart`, `vedicAstrology.generateBirthChart`, `vedicAstrology.getCurrentDasha`, `ayurveda.calculateAyurvedicConstitution` and the `birthData` of `forecast.forecastTransits`; the instant alone (`date`, `time`, `timezone`) to `humanDesign.generateBodygraph`, `chineseAstrology.generateBaziChart` and `kabbalah.generateBirthProfile`. Never look the city up twice for one person.

### Multi-language via `lang`

Ten languages: `Lang.en`, `tr`, `de`, `es`, `fr`, `hi`, `pt`, `ru`, `zhHans`, `zhHant`. Defaults to English. Supported: `astrology`, `vedicAstrology`, `forecast`, `humanDesign`, `chineseAstrology`, `fengShui`, `mesoamericanAstrology`, `vastu`, `numerology`, `kabbalah`, `tarot`, `biorhythm`, `ayurveda`, `iching`, `crystals`, `angelNumbers`, `languages`. English only: `dreams`, `location`, `usage`. A field with no translation returns English. Canonical fields stay English for comparisons; a `...Localized` sibling carries the translated text for display. Display text such as tarot position names (`Pasado` in Spanish) is translated in place: never switch on it.

## Common tasks

In catalog order. `birth` and `partner` are from the lookup above.

| Task | Code |
|------|------|
| Find city coordinates (do this first) | `roxy.location.searchCities(q: 'Berlin')` |
| Daily horoscope | `roxy.astrology.getDailyHoroscope(sign: Sign.leo)` |
| Natal chart (Western) | `roxy.astrology.generateNatalChart(date: ..., time: ..., latitude: ..., longitude: ..., timezone: ...)` |
| Compatibility score (`overallScore`, 0 to 100, plus categories) | `roxy.astrology.calculateCompatibility(person1: ..., person2: ...)` |
| Synastry (every inter-chart aspect, plus `compatibilityScore` 0 to 100) | `roxy.astrology.calculateSynastry(person1: ..., person2: ...)` |
| Current moon phase | `roxy.astrology.getCurrentMoonPhase()` |
| Kundli (Vedic birth chart) | `roxy.vedicAstrology.generateBirthChart(date: ..., time: ..., latitude: ..., longitude: ...)` |
| Panchang (detailed) | `roxy.vedicAstrology.getDetailedPanchang(date: ..., latitude: ..., longitude: ...)` |
| Current dasha | `roxy.vedicAstrology.getCurrentDasha(date: ..., time: ..., latitude: ..., longitude: ...)` |
| Mangal Dosha | `roxy.vedicAstrology.checkManglikDosha(date: ..., time: ..., latitude: ..., longitude: ...)` |
| Guna Milan (matching) | `roxy.vedicAstrology.calculateGunMilan(person1: ..., person2: ...)` |
| Navamsa (D9) | `roxy.vedicAstrology.generateNavamsa(date: ..., time: ..., latitude: ..., longitude: ...)` |
| KP chart | `roxy.vedicAstrology.generateKpChart(date: ..., time: ..., latitude: ..., longitude: ...)` |
| Nakshatra detail | `roxy.vedicAstrology.getNakshatra(id: GetNakshatraId.ashwini)` |
| Transit forecast | `roxy.forecast.forecastTransits(birthData: ..., startDate: ..., endDate: ...)` |
| Cross-domain timeline | `roxy.forecast.generateTimeline(birthData: ..., startDate: ..., endDate: ...)` |
| Human Design bodygraph | `roxy.humanDesign.generateBodygraph(date: ..., time: ..., timezone: ...)` |
| Human Design connection | `roxy.humanDesign.calculateConnection(personA: ..., personB: ...)` |
| BaZi Four Pillars | `roxy.chineseAstrology.generateBaziChart(date: ..., time: ..., timezone: ...)` |
| Chinese zodiac animal | `roxy.chineseAstrology.calculateZodiacAnimal(date: '1990-01-15')` |
| Almanac day (Tong Shu) | `roxy.chineseAstrology.getAlmanacDay(date: '2026-10-01')` |
| Kua number | `roxy.fengShui.calculateKuaNumber(date: '1990-01-15', gender: Gender.female)` |
| Flying star natal chart | `roxy.fengShui.generateFlyingStarChart(period: 9, facing: GenerateFlyingStarChartFacing.zi)` |
| Tzolkin day sign | `roxy.mesoamericanAstrology.calculateTzolkin(date: '1990-01-15')` |
| Vastu entrance | `roxy.vastu.calculateEntrancePada(plot: ..., facing: ..., doorPosition: 0.4375)` |
| Life path number | `roxy.numerology.calculateLifePath(year: 1990, month: 1, day: 15)` |
| Full numerology chart | `roxy.numerology.generateNumerologyChart(fullName: 'John William Smith', year: 1990, month: 1, day: 15)` |
| Gematria | `roxy.kabbalah.calculateGematria(text: 'shalom')` |
| Daily tarot card | `roxy.tarot.getDailyCard(seed: 'user-42')`, both `seed` and `date` optional: `seed` fixes the card per user, `date` defaults to today in UTC |
| Three-card spread (`positions`, each with `name` and `card`) | `roxy.tarot.castThreeCard(question: 'What should I focus on?')` |
| Celtic Cross | `roxy.tarot.castCelticCross(question: 'What should I focus on?')` |
| Biorhythm reading | `roxy.biorhythm.getReading(birthDate: '1990-01-15')` |
| Ayurvedic constitution | `roxy.ayurveda.calculateAyurvedicConstitution(date: ..., time: ..., latitude: ..., longitude: ...)` |
| Daily hexagram | `roxy.iching.getDailyHexagram(seed: 'user-42')` |
| Hexagram detail | `roxy.iching.getHexagram(number: 1)` |
| Crystals by zodiac | `roxy.crystals.getCrystalsByZodiac(sign: Sign.leo)` |
| Crystals by chakra | `roxy.crystals.getCrystalsByChakra(chakra: Chakra.heart)` |
| Dream symbol | `roxy.dreams.getDreamSymbol(id: 'flying')` |
| Angel number meaning | `roxy.angelNumbers.getAngelNumber(number: '1111')` |
| Any number sequence | `roxy.angelNumbers.analyzeNumberSequence(number: '1234')` |
| Check API usage | `roxy.usage.getUsageStats()` |
| List supported languages | `roxy.languages.listLanguages()` |

## Field formats that trip agents

| Field | Dart type | Good | Bad |
|-------|-----------|------|-----|
| `timezone` (charts) | `NumOrString` | `NumOrString.string('Europe/London')`, `NumOrString.number(5.5)` | `'5:30'`, `'+0530'`, `'GMT-5'`, the `utcOffset` of a city |
| `timezone` (horoscopes, moon phase) | `String` | `'America/New_York'` | a `NumOrString` |
| `date` | `String` | `'1990-01-15'` | `DateTime`, `'15/01/1990'`, `'1990-1-15'` |
| `time` | `String` | `'14:30:00'` | `'2:30 PM'`, `'14:30'` (no seconds) |
| `latitude`, `longitude` | `num` | `51.5074`, `-0.1278` | DMS strings such as `"51°30'N"` |
| `fullName` (numerology) | `String` | Full birth-certificate name | Nickname or partial name |
| `seed` | `String` | `'user-42'`, an email hash | A number |
| `number` (angel numbers) | `String` | `'1111'` | `1111` |
| `id` (dream symbol) | `String` slug | `'flying'` | Display names, spaces |
| `year`, `month`, `day` (numerology) | `int` | `1990`, `1`, `15` | `'01'` |

## Astrology domain gotchas for LLMs

- **Ayanamsa is server-side in Vedic.** Vedic endpoints apply sidereal Lahiri by default; KP endpoints take `Ayanamsa.kpNewcomb` (default), `kpOld`, `lahiri` or `custom`. Never subtract an ayanamsa in client code.
- **Tithi count is 30, not 15.** 15 Shukla plus 15 Krishna; the panchang carries `paksha` beside the tithi number.
- **Rahu and Ketu are lunar nodes, not planets.** `nodeType` selects `NodeType.mean` or `NodeType.true$`.
- **Nakshatra count is 27.** `roxy.vedicAstrology.listNakshatras()` returns 27.
- **Retrograde is per planet.** Natal chart planets and Vedic `meta` carry `isRetrograde`; check the planet in the response.
- **Seeded daily endpoints are deterministic per seed and date.** Same seed, same date, same reading. It is not a cache.
- **Pass the IANA timezone for births.** Western charts must respect the DST in force at birth; the IANA name from the city lookup does that.

## Error handling

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

Switch on `e.code`, never on `e.message`. `e.statusCode`, `e.docUrl` and `e.retryAfter` (a `Duration`, from `Retry-After`) sit beside it. A `validation_error` lists every failing field in `e.issues`, each with `path` (such as `date` or `person1.time`), `message` and `code`; it is empty for any other error. A network failure is not a `RoxyException`: it surfaces as the `ClientException` (or a subclass) of `package:http`, and a `timeout` passed to `Roxy` surfaces as a `TimeoutException` or a `RequestAbortedException`.

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

Retries are on by default: up to twice after a 429, 500, 502, 503 or 504, or a connection that was never made. `maxRetries: 0` turns them off. A `Retry-After` longer than `maxDelay` (30 s) is not waited for. Total requests on a persistent failure = 1 + `maxRetries`.

## MCP equivalents

Every method has a matching tool on the Remote MCP server of its domain at `https://roxyapi.com/mcp/{domain}` (Streamable HTTP, no stdio, no self-hosting). Tool names follow `{method}_{path_snake_case}`: `POST /astrology/natal-chart` is `post_astrology_natal_chart` on `/mcp/astrology`. Use the SDK in Dart and Flutter code; use MCP when an AI agent picks tools by intent.

## Gotchas

- **Flutter name clashes.** `Card`, `Size`, `Theme` and `Element` exist in Flutter and in this package. In Flutter code import it with a prefix: `import 'package:roxyapi/roxyapi.dart' as roxy;`, then `roxy.Roxy(...)`, `roxy.Sign.aries`.
- **Keep the API key off the device.** Call Roxy from a backend you own and send the JSON to the app; read it there with `NatalChartResponse.fromJson(map)`.
- **A city record has `city`, `province`, `country`, `iso2`, `latitude`, `longitude`, `timezone`, `utcOffset` and `population`.** The name is `city`, never `name`.
- **A natal chart `planets` is a list.** Find a body by name: `chart.planets.firstWhere((p) => p.name == 'Moon')`.
- **In a Vedic chart `meta` is a map keyed by graha.** `kundli.meta['Moon']?.rashi` is a `String`, and its `nakshatra` is an object: read `.name`.
- **List endpoints return an envelope**, `total`, `limit`, `offset` plus a named list (`cities`, `crystals`, `hexagrams`, `symbols`), never a bare list. Pass `limit:` to widen a page.
- **`num` prints without a trailing `.0`** only when the API sent an integer; format with `.toStringAsFixed(n)` for display.
- **A wrong-typed field throws `FormatException` naming it** only when that getter is read; decoding never fails up front.

## Links

- Full method reference: `doc/llms-full.txt` (bundled in this package)
- Documentation: https://roxyapi.com/docs
- Interactive API docs: https://roxyapi.com/api-reference
- Pricing and API keys: https://roxyapi.com/pricing
- MCP for AI agents: https://roxyapi.com/docs/mcp
- Charts for the web: https://roxyapi.com/docs/ui
- Source and issues: https://github.com/RoxyAPI/sdk-dart
