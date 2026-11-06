# Lamma (لمّة) — Design Handoff for Implementation

Arabic-first (RTL) group party-games app. **Flutter** (iOS + Android) for the app, **Laravel + Filament** for the web admin.
This folder is the single source of truth for the UI. Build the screens to match the PNGs; use the HTML files to read exact values (colors, sizes, radii, spacing, copy).

## Folder contents

| Path | What it is |
|---|---|
| `screens/png/NN-Name.png` | Pixel reference of every screen at @2x (phone frame 390×844 pt; admin 1440 wide). |
| `screens/html/NN-Name.html` | Standalone HTML of each screen. Open in a browser; inspect for exact CSS values and Arabic copy. |
| `assets/*.png` | Illustrations used in the screens (avatars, game icons, scenes). **Low-res placeholders** — see "Assets" below. |
| `fonts/` | Cairo (400/600/700/800/900) + Reem Kufi 700, woff2. In Flutter use `google_fonts` or bundle the TTFs. |
| `design-tokens.json` | Colors, gradients, radii, spacing, type scale, shadows. |
| `lamma_theme.dart` | Starter Flutter `ThemeData` + color/gradient constants built from the tokens. |

## Global rules

- **Direction:** whole app is RTL (`Directionality(textDirection: TextDirection.rtl)`, locale `ar`). Back chevron points **right**. Numbers use Western digits.
- **Font:** Cairo everywhere. Reem Kufi 700 only for the proverb text on the parchment card.
- **Theme:** dark, deep-purple night look. Backgrounds are radial gradients (purple glow near the top) + soft blurred color blobs (bokeh). No light mode in v1 (a light mode toggle exists in Settings for later).
- **Primary CTA ("game button"):** pill, height 60–62, gradient orange→pink (`#FFB25E → #FF8A4C → #F2569A`), **5px darker bottom border `#B83A72`** (3D pressed look), inner top highlight, pink glow shadow, text `#2A0E35` weight 900, 20–22pt. On press: translateY(3px) and shrink the bottom border.
- **Secondary CTA:** same shape, violet gradient (`#B98AFF → #7A2FE0`), bottom border `#4A1690`, white text.
- **Cards:** dark translucent surfaces (`rgba(0,0,0,0.25)` or `#2A1850`) with a 1–1.5px violet border `rgba(163,91,255,0.3–0.4)`, radius 18–24. Selected state = brighter violet gradient + `#B98AFF` border + violet glow.
- **Game tiles:** each game has its own gradient + a 3D icon; radius 22, inner highlight, drop shadow.
- **Touch targets** ≥ 44×44. Every icon-only button needs a semantic label.
- **Motion:** 180–260ms navigation, 100–160ms state changes. Respect "reduce motion" from Settings / OS.

## Screen list & navigation

Numbers match file names.

### Core flow
1. **Main** — Splash / onboarding 1. Lamma wordmark (crown + puffy white text with pink outline and purple 3D depth), tagline, crowd illustration, "ابدأ الآن" → 9 (Onboard2). "تسجيل الدخول" → 11.
2. **Mode** — Choose local vs online (selected card glows + green check). Local → 3, Online → 6.
3. **Home** — Greeting + avatar, notifications bell (→ 23), tabs (الألعاب / التحديات / المفضلة), 2×4 game tile grid (→ 4), bottom nav with raised center "games" button (Home, Friends, Games, Leaderboard → 7, More).
4. **Game** — Game setup (example: أمثال شعبية). Hero scene image, settings rows (players, rounds, difficulty) → opens pickers. "ابدأ اللعبة" → 14 (Players) → 20 (Rules, first time) → 19 (Handoff) → 5 (Play).
5. **Play** — Proverbs round: pause (→ 21), round counter, timer pill, player avatars with scores (leader has crown), parchment card, 3 answer options (single select, selected = violet glow + green check), "التالي".
6. **Room** — Online lobby: room code + copy, QR, players list with connection state text+dot (متصل / بيعيد الاتصال…), host crown, share invite, host "ابدأ اللعبة".
7. **Leaderboard** — Period tabs, top-3 podium (gold/silver/bronze), ranked list, current user row highlighted.
8. **Admin** — Web admin dashboard (Filament): right sidebar, KPI cards, activity chart, content table with status chips (منشور / مراجعة حقوق / مسودة). Responsive: sidebar stacks on narrow screens.

### Onboarding & auth
9. **Onboard2** — "العب أونلاين مع صحابك". Skip → 11.
10. **Onboard3** — "ألعاب ومحتوى بيتجدد". → 11.
11. **Login** — Phone (+country code) → 12. Google / Apple sign-in. **"العب كضيف"** (guest play is required — no forced account) → 3.
12. **Otp** — 4-digit code, active box highlighted gold, resend countdown → 13.
13. **Register** — Pick avatar (5 options, selected = gold ring, big preview with crown), nickname, preferred content dialect (مصري / خليجي / عربي عام) → 3.

### Players, results, profile, settings
14. **Players** — Teams vs solo toggle, two team cards (violet / orange) with removable player chips, add-player input, shuffle teams button, "ابدأ الجولة". 4–12 players. Names stored on device only.
15. **Join** — 6-digit room code boxes, or scan QR → 6.
16. **Results** — End of round: light rays, trophy, winning team, team scores, MVP card, "العب تاني" / change game / share result.
17. **Profile** — Avatar (edit → 13), name, level + XP progress bar, stats (wins / games / points), badges, friends, game history.
18. **Settings** — Content dialect, dark mode, sound effects, timer vibration, reduce motion, family mode (all switches), notifications, privacy, help, logout.

### In-game states
19. **Handoff** — Pass-the-phone screen for local play ("سلّم الموبايل لـ منة") + "others don't look" warning. Prevents revealing the secret card.
20. **Rules** — Bottom sheet: 3 steps + scoring (+3 no hint, +2 with hint, 0 skip), "don't show again".
21. **Pause** — Modal: current scores, resume, rules, sound, restart round, end game.
22. **Disconnect** — Online reconnect state: red status bar, retry attempt counter, host wait timer, per-player status, "round is saved".
23. **Notifs** — Room invite (join / later), new content, new badge, grouped by day; unread dot.

### More games & store
24. **Taboo** (ممنوع تقول) — Circular countdown, explainer chip, word card + 5 forbidden words, buttons: skip (limited), foul (red), correct (green, largest).
25. **Draw** (ارسم وخمّن) — Secret word (hide/show), drawing canvas, live guesses (online), color swatches, eraser, undo, clear, "they guessed it".
26. **Quotes** (جمل مشهورة) — Cinema-marquee card with genre/era hint, 3 options. Copy in the design is a made-up sample; real quotes need rights review.
27. **Store** — "لمّة بلس" premium banner (marked **قريبًا**, feature-flagged off at launch), filter tabs, pack cards (owned / free download / paid). Prices are `[السعر]` placeholders.

## Reusable components to build first

`LammaScaffold` (radial gradient bg + bokeh), `GameButton` (primary/secondary 3D pill), `GlassCard`, `GameTile`, `AvatarCircle` (with crown / status ring), `TimerPill` + `TimerRing`, `AnswerOption` (default / selected / correct / wrong), `SegmentedTabs`, `SettingsRow` + `LammaSwitch`, `CodeInputBoxes` (OTP & room code), `PlayerChip`, `TeamCard`, `BottomSheet`, `LammaDialog`, `StatusBanner`, `LammaWordmark`.

## Architecture notes (from the product doc)

- Games are **data-driven**: a small set of tested game templates (complete-the-phrase, taboo, draw, multiple-choice, voting…). New games/content come from the Filament admin without an app release.
- Local play works offline once content is downloaded. Online rooms: the server is the source of truth for round state, timer, and score; never send the secret answer to clients before the turn ends.
- Room events: `room_created, player_joined, game_started, turn_started, answer_submitted, round_ended, player_reconnected, room_closed`.
- Content items carry: dialect, difficulty, age/sensitivity flags, source & rights. Family mode filters by those flags.

## Assets — important

The PNGs in `assets/` were cropped from the concept mockup, so they are **low resolution placeholders**. Before release, replace each with a high-res export (PNG with transparent background, @3x) keeping the same file names:
`av-ahmed, av-karim, av-mahmoud, av-mena, av-sara` (avatars), `crowd` (splash), `local, online` (mode cards), `proverb` (game hero), `popcorn`, and game icons `ic-quote, ic-film, ic-a, ic-bulb, ic-music, ic-photo, ic-mask, ic-dice`.
The Lamma wordmark is built from text + a crown shape (see `01-Main.html`); a final logo file can replace it later.
