# NEON RAIL RUSH • Android 3D endless runner

**Original Godot 4.4.1 game.** Inspired by the *endless runner* genre; no Subway Surfers game files, branded characters or licensed music are used.

## Features

- Perspective 3D neon city with procedural buildings, lamps, and subway rails.
- Three lanes, swipe gestures, on-screen controls, keyboard support.
- Jump over barricades, slide below neon gates, dodge trains.
- Gold coin trails, magnet and shield pickups, increasing speed.
- Original synthesized background music and sound effects.
- Pause/restart/main menu, score, persistent personal best.
- Runs offline, no login, no ads, no analytics, no internet permission.
- Low-poly geometry and GLES3 compatibility renderer to help older devices.

## 📱 APK'ni GitHub Actions orqali chiqarish

1. GitHub.com'da **yangi repository** oching, masalan `neon-rail-rush`.
2. Ushbu arxivni extract qiling. **ZIP ichidagi hamma fayllarni** repository root'ga yuklang. `project.godot` root'da bo'lishi shart. `.github/workflows/android-apk.yml`ni ham yuklang. GitHub web upload'da `.github` papkasi yashirin bo'lishi mumkin; faylni alohida yarating: **Add file → Create new file**, name `.github/workflows/android-apk.yml`, ZIPdagi mazmunini paste qiling.
3. Repository → **Actions** → `NEON RAIL RUSH - Android APK` → `Run workflow` → yashil `Run workflow`.
4. Build **Success** bo'lsa, build detail → **Artifacts** → `Neon-Rail-Rush-Android-APK` → ZIP yuklab oling.
5. ZIPdan `neon-rail-rush-debug.apk`ni chiqaring va Android telefoningizga o'rnating.

**Muhim**: bu ZIP — loyiha kodlari, tayyor APK emas. GitHub Actions birinchi marta Docker image (~bir necha GB) yuklagani uchun build sekin bo'lishi mumkin. Kompilyatsiya haqiqiy GitHub runnerda amalga oshiriladi. Shu muhitda Android APK ni kompilyatsiya qilib tekshirish imkoni bo'lmadi. Build logda xato chiqsa `SCRIPT ERROR`, `PARSE ERROR` yoki `Export` qatorlarini yuboring.

### Kompyuterda ishga tushirish

[Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) bilan `project.godot`ni oching, F6 yoki F5 bosing. `File → Export → Android` uchun Android SDK/JDK 17 va matching export templates talab etiladi.

### O'yin boshqaruvi

| Harakat | Telefon | Kompyuter |
|---|---|---|
| Chapga | Chapga swipe / ◀ | A yoki ← |
| O'ngga | O'ngga swipe / ▶ | D yoki → |
| Sakrash | Tepaga swipe / ▲ | W, ↑ yoki Space |
| Sirpanish | Pastga swipe / ▼ | S yoki ↓ |
| Pauza | Ⅱ tugmasi | P yoki Esc |

**To'siqlar**: poyezdni chetlab o'ting; to'q sariq barrikadadan sakrab o'ting; pushti ustki darvozadan sirpanib o'ting. Har to'siq to'lqinida kamida bitta bo'sh yo'lak bor.

**Bonuslar**: magnit tangalarni yaqin yo'laklardan tortadi (9 soniya); himoya bitta to'qnashuvni bekor qiladi (9 soniya).

### Texnik ma'lumotlar

- Godot 4.4.1; GDScript; 3D Compatibility renderer.
- Android export: ARM64, debug signed; Android APK local testing (not signed Play release).
- Package: `com.neonrailrush.runner` (Play Store uchun noyobligini tekshiring).
- Ma'lumotlar `user://neon_rail_rush.cfg` saqlanadi. O'yinni o'chirish progressni o'chirishi mumkin.
- Dizayn, kod, procedurally generated meshes, sound FX and background music are original to this project.

### Cheklovlar

Bu — mustaqil birinchi o'ynaladigan prototip, katta tijoriy o'yin emas. Subway Surfers'ning original 3D modellari, qahramonlari, xaritalari, soundtracki va internet reytingini o'z ichiga olmaydi. Hozircha missions/quests, xarakter shop va multiplayer yo'q. Real qurilma sinovi o'tkazilmagan.
