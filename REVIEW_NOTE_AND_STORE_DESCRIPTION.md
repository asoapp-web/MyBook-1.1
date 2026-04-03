# MyBookShelf — App Review Note & Store Description

## Review Note for 4.3(a) Resubmission

Dear Review Team,

Thank you for your feedback regarding Guideline 4.3(a). We have made significant, substantive changes to MyBookShelf to ensure it stands as a meaningfully unique product:

**Visual identity overhaul.** The entire UI has been redesigned with a distinctive warm-ink palette, amber lantern accents, and serif typography — a "reading by lamplight" aesthetic that sets MyBookShelf apart visually. We removed the generic glass/material card style and replaced it with solid, warm-toned surfaces and a custom atmosphere background layer with subtle ambient animations (paper grain, vignette breathing, horizontal line drift).

**Custom navigation shell.** We replaced the system TabView with a fully custom ZStack-based root and a bespoke floating tab bar. The tab bar features a matched-geometry sliding indicator, live timer arcs during reading sessions, badge overlays driven by screen state, and haptic feedback — none of which are possible with the default system tab bar.

**Unique splash screen.** A custom launch sequence with a fan-of-pages Canvas animation, stage messages ("Opening the shelf…", "Loading your streaks…"), and a smooth progress bar — original to MyBookShelf.

**Custom popup system.** All confirmation dialogs and content previews now use a custom overlay-based popup system (scale+spring animation, backdrop dim, Reduce Motion support) instead of system sheets. Only UIKit-required presentations (camera, photo picker) remain as system sheets.

**Reading timer with session tracking.** Users can now start, pause, and stop a foreground reading timer directly from a book's detail page. Stopping the timer prompts for a page update and persists the session to Core Data. An active session is indicated by a live arc animation on the Shelf tab icon.

**Library export.** Users can export their entire library (books and reading sessions) as a structured JSON file and share it via the system share sheet.

**Privacy Policy via WebView.** The privacy policy is now loaded from a hosted URL through WKWebView, with an offline fallback to the in-app text.

**Global toast feedback.** A themed capsule-style toast system provides contextual feedback after save, export, and reset actions throughout the app.

These changes represent a ground-up visual redesign and the addition of multiple substantive features (timer, export, custom overlays, smart tab bar) that together create a unique user experience not found in other reading tracker apps.

---

## App Store Description

**MyBookShelf — Your Personal Reading Companion**

Track your books, build reading streaks, and watch your library grow — all on your device, with zero accounts or cloud dependency.

**A shelf that feels like yours.**
Browse your collection on a beautifully crafted 3D bookshelf. Tap the glass cabinet to see every volume, or explore your books through filtered lists. The warm, lantern-lit atmosphere makes every session feel cozy.

**Active reading sessions.**
Start a timer when you sit down to read. Pause and resume at will. When you stop, log your pages — MyBookShelf handles the rest: tracking duration, updating progress, and feeding your streak.

**Streaks, quests, and achievements.**
Stay motivated with daily reading streaks, XP-based leveling, time-limited quests, and unlockable achievements. Your reading habit becomes a game you actually want to play.

**Statistics that tell a story.**
See your pages per day, a monthly heatmap of reading activity, top genres, and a 7-day bar chart — all computed locally from your reading sessions.

**Export your library.**
Take your data with you. Export your full library — books, sessions, ratings, and notes — as a structured JSON file, ready to share or archive.

**Built for privacy.**
No accounts. No analytics. No ads. Your books, notes, and reading history stay on your iPhone. Period.

---

**What's New in This Version**

- Complete visual redesign: warm ink palette, amber accents, serif typography, atmosphere background with ambient animations
- Custom tab bar with smart indicators (badges, timer arc, state-driven hints)
- Reading timer: start, pause, stop — with automatic session logging
- Library export (JSON) via share sheet
- Custom popup dialogs replace system sheets for a cohesive experience
- Unique splash screen with animated progress stages
- Privacy policy now loads via web, with offline fallback
- Global toast feedback throughout the app
- Removed placeholder surfaces; polished every screen
