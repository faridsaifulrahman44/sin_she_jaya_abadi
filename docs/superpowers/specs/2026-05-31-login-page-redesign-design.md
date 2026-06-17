# Spec: Login Page Redesign — SinShe Jaya Abadi (Fase 6)

Tanggal: 2026-05-31
Status: Approved — siap implementasi

---

## Ringkasan

Redesign halaman Login (`LoginMobileLayout`) sesuai mockup `login_app.jpeg`:
- Background gradient gelap + logo di atas
- White card bottom sheet untuk form
- Bordered inputs dengan fokus teal
- Warna aksen teal `#00897B`

---

## Struktur Layout

Screen terdiri dari 2 zona:

```
┌──────────────────────────┐  ← zona atas (~55%)
│  [Gradient #0D1117 → #1A2332]
│       Status bar area
│         [Logo]
│    "SinShe Jaya Abadi"
│ "System Manajemen Klinik Herbal"
└──────────────────────────┘
┌──────────────────────────┐  ← zona bawah (~45%)
│  ┌──────────────────────┐│
│  │   [White card]       ││  border-radius: 32px 32px 0 0
│  │   Selamat Datang      ││  shadow: black12, blur 24, offset -8
│  │   Masuk untuk...      ││
│  │   [Email field    ]  ││  border: #E2E8F0 1.5px, radius 10
│  │   [Password field ]  ││
│  │   [🔑 Masuk        ] ││  bg: #00897B, radius 10, shadow teal
│  │   Lupa password?     ││
│  │   [Info box         ]│
│  │   © 2026 SinShe      ││
│  └──────────────────────┘│
└──────────────────────────┘
```

---

## Komponen Utama

### 1. Background Upper Zone

- `Container` dengan `BoxDecoration(gradient: LinearGradient(...))`
- `begin: Alignment.topCenter`, `end: Alignment.bottomCenter`
- Colors: `#0D1117` → `#1A2332`
- `SafeArea` + `SizedBox(height: 48)` untuk status bar area
- Logo: `Image.asset('assets/logo/logo_sinshe_login.png', height: 100)`
- Text: "SinShe Jaya Abadi" (22px, white, font-weight 800)
- Subtitle: "System Manajemen Klinik Herbal" (12px, white50)

### 2. White Form Card

- `Container` dengan `borderRadius.only(topLeft: 32, topRight: 32)`
- Background: `Colors.white`
- Shadow: `BoxShadow(color: Colors.black.withAlpha(31), blurRadius: 24, offset: Offset(0, -8))`
- Padding: `EdgeInsets.fromLTRB(28, 28, 28, 32)`
- Bisa pakai `MediaQuery.padding` untuk bottom safe area

### 3. Welcome Text

- "Selamat Datang" — 20px, font-weight 800, color `ctextPrimary`
- "Masuk untuk melanjutkan" — 13px, font-weight 500, color `ctextSecondary`

### 4. Bordered Input Fields

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
    borderRadius: BorderRadius.circular(10),
  ),
  child: TextField(
    decoration: InputDecoration(
      prefixIcon: Icon(AppLegacyIcons.mail, color: ctextMuted, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFF00897B), width: 1.5)),
      hintText: '...',
      hintStyle: TextStyle(color: ctextMuted, fontSize: 14),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
  ),
)
```

### 5. Password Field

- Sama style bordered dengan email field
- Suffix: `GestureDetector` → toggle icon `visibilityOff/On`
- `obscureText` controlled oleh parent widget

### 6. Button — Teal Full-Width

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
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(AppSymbols.login, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ])),
    ),
  ),
)
```

### 7. Elemen yang Tidak Berubah

- Link "Lupa password?" — tetap centered, muted color
- Info box "Belum punya akun? Hubungi admin..." — tetap
- Copyright footer — tetap

---

## Params Masuk (`LoginMobileLayout`)

Semua params sudah ada di signature saat ini:
- `emailController`, `passwordController`
- `obscurePassword`, `loading`
- `onTogglePassword`, `onLogin`, `onForgotPassword`

Tidak ada params baru yang diperlukan.

---

## Scope

- **Termasuk:** Restyle `LoginMobileLayout` sesuai spec di atas
- **Tidak termasuk:**
  - Desktop layout (bisa revisi terpisah)
  - Logic perubahan (auth, routing tetap seperti semula)
  - Eksternal file baru

---

## Approach

Restyle in-place di `lib/pages/login/widgets/login_layouts.dart` — edit `LoginMobileLayout` langsung, komponen internal tetap. Low risk, cepat selesai.

---

## File yang Diedit

- `lib/pages/login/widgets/login_layouts.dart` — `LoginMobileLayout` section