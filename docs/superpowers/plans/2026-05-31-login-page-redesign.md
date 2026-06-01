# F6 Login Page Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline execution, no subagent needed for this scope).

**Goal:** Restyle `LoginMobileLayout` di `lib/pages/login/widgets/login_layouts.dart` sesuai mockup `login_app.jpeg` — gradient background gelap + logo + white bottom sheet card.

**Architecture:** Single-widget restyle in-place. Ubah `build()` method `LoginMobileLayout` jadi 2 zona (gradient top + white bottom sheet). Tidak ada params baru, tidak ada logic change, tidak ada file baru.

**Tech Stack:** Flutter/Dart, `Image.asset`, `LinearGradient`, `BoxDecoration`, `BoxShadow`, `TextField` + `InputDecoration`.

---

## File yang Diedit

- `lib/pages/login/widgets/login_layouts.dart` — seluruh `LoginMobileLayout.build()` method di-rewrite

---

## Task 1: Setup — Baca dan Pahami Konteks

**Files:** `lib/pages/login/widgets/login_layouts.dart` (already read, lines 1–761)

- [ ] Baca ulang `login_layouts.dart`, fokus ke `LoginMobileLayout` (baris 7–152)
- [ ] Catat imports yang sudah ada: `app_theme.dart`, `app_legacy_icons.dart`, `app_symbols.dart`
- [ ] Catat semua current params yang diperlukan (sudah match spec — tidak ada yang berubah)

---

## Task 2: Ganti Background & Layout Shell

**Files:** Modify: `lib/pages/login/widgets/login_layouts.dart` — `LoginMobileLayout.build()`

- [ ] Ganti outer `SingleChildScrollView` → `Column` dengan 2 child:
  1. `_GradientHeader()` — expanded, gradient bg + logo + brand text
  2. `_WhiteFormCard()` — white card, form fields + button
- [ ] Hapus `const SizedBox(height: 56)` di atas `_LoginAppIcon()` yang lama
- [ ] Hapus `const Spacer()` di akhir sebelum copyright
- [ ] Wrap keseluruhan dengan `SafeArea` (bottom: false) + `MediaQuery.padding` handling

**Code skeleton:**

```dart
@override
Widget build(BuildContext context) {
  return SafeArea(
    bottom: false,
    child: Column(
      children: [
        // Upper zone — gradient + logo
        Expanded(
          flex: 55,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D1117), Color(0xFF1A2332)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 48),
                Image.asset('assets/logo/logo_sinshe_login.png', height: 100),
                SizedBox(height: 12),
                Text('SinShe Jaya Abadi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 4),
                Text('System Manajemen Klinik Herbal',
                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(127))),
              ],
            ),
          ),
        ),
        // Lower zone — white form card
        Expanded(
          flex: 45,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(31), blurRadius: 24, offset: Offset(0, -8))],
            ),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28, 28, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome text, fields, button, footer — dari Task 3
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

## Task 3: Welcome Text + Bordered Input Fields + Button

**Files:** Modify: `lib/pages/login/widgets/login_layouts.dart` — dalam `_WhiteFormCard` Column

- [ ] **Welcome text** — "Selamat Datang" (20px, font-weight 800, `ctextPrimary`) + "Masuk untuk melanjutkan" (13px, `ctextSecondary`)
- [ ] **Email field** — bordered container style, `AppLegacyIcons.mail`, focus teal
- [ ] **Password field** — bordered container, `AppLegacyIcons.lock`, visibility toggle suffix
- [ ] **Button** — teal `#00897B`, full-width 52px, `AppSymbols.login` icon + "Masuk" text
- [ ] **Footer elements** — "Lupa password?" link, info box, copyright (sama seperti saat ini)

**Bordered field code:**

```dart
// Label
Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ctextSecondary(context))),

// Bordered input container
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
    borderRadius: BorderRadius.circular(10),
  ),
  child: TextField(
    controller: emailController,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      hintText: 'username atau nama@email.com',
      hintStyle: TextStyle(color: ctextMuted(context), fontSize: 14),
      prefixIcon: Icon(AppLegacyIcons.mail, color: ctextMuted(context), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF00897B), width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
  ),
)
```

**Teal button code:**

```dart
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Color(0xFF00897B),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [BoxShadow(color: Color(0xFF00897B).withAlpha(77), blurRadius: 12, offset: Offset(0, 4))],
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: loading ? null : onLogin,
      borderRadius: BorderRadius.circular(10),
      child: Center(
        child: loading
            ? SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(AppSymbols.login, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
      ),
    ),
  ),
)
```

---

## Task 4: Verifikasi & Test

**Files:** Analyze: `lib/pages/login/widgets/login_layouts.dart`

- [ ] Jalankan `flutter analyze lib/pages/login/widgets/login_layouts.dart`
- [ ] Pastikan 0 errors, 0 warnings
- [ ] Jalankan `flutter analyze` seluruh project — pastikan tidak ada regressions

---

## Task 5: Commit

```bash
git add lib/pages/login/widgets/login_layouts.dart
git commit -m "feat(F6): redesign LoginMobileLayout — gradient bg + logo + white bottom sheet"
```