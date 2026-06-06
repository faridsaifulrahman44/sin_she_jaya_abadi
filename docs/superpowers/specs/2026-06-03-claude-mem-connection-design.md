# Design: claude-mem Connection (Tanpa Docker)

**Tanggal:** 2026-06-03
**Status:** Investigated — menunggu approval user
**Brainstorming session:** Poin 2 dari request "2 hal yang harus difix"

---

## 📊 Temuan Investigasi (Recon Lengkap)

### Apa yang SUDAH JALAN (diverifikasi via netstat + curl)

| Komponen | Status | Bukti |
|---|---|---|
| **claude-mem worker** (PID 13248) | ✅ Berjalan | `supervisor.json` → started 2026-06-03 14:45:17 |
| **HTTP server (viewer UI)** | ✅ Listen `127.0.0.1:37777` | `curl http://localhost:37777/` → 200 OK, HTML 76.9KB |
| **Health endpoint** | ✅ Aktif | `/health` → `{"status":"ok","activeSessions":1,...}` |
| **Bun runtime** | ✅ Terinstall | `C:\Users\farid\.bun\bin\bun.exe` |
| **claude-mem plugin v13.4.0** | ✅ Loaded | `C:/Users/farid/.claude/plugins/cache/thedotmack/...` |
| **Database SQLite** | ✅ Ada | `C:/Users/farid/.claude-mem/claude-mem.db` |
| **MCP tools in-session** | ✅ Visible | `mcp__plugin_claude-mem_mcp-search__*` di tool registry sesi ini |
| **Hooks (SessionStart, PostToolUse, dll)** | ✅ Registered | `hooks.json` plugin punya semua hook definitions |
| **Docker** | ❌ TIDAK ada | `docker: command not found` |

### Verdict: 100% AMAN tanpa Docker ✅

**Alasan:**
1. Server binding **eksklusif ke `127.0.0.1` (loopback only)** — tidak terekspos ke LAN/internet
2. Worker process jalan sebagai child process Claude Code di user namespace yang sama
3. SQLite DB di user home (`~/.claude-mem/`) — tidak ada attack surface eksternal
4. Plugin author (thedotmack) sudah sediakan `Dockerfile.test-installer` HANYA untuk **E2E testing installer** (bukan untuk runtime harian). Anda tidak perlu Docker sama sekali.
5. Port 37777 sudah ditetapkan oleh plugin — tidak konflik dengan service lain

### Apakah MCP "sudah connect"?

**Ya, sebagian besar sudah.** Yang terjadi:
- Plugin di-enable di `settings.json` line 165: `"claude-mem@thedotmack": true`
- Hooks registered via `hooks.json` plugin
- Tools tersedia di sesi ini via `mcp__plugin_claude-mem_mcp-search__*` (terlihat di tool list)
- Worker di-spawn via `SessionStart` hook (Bun + worker-service.cjs)

**Yang perlu diverifikasi/ditingkatkan (opsional):**
- Apakah **search/get_observations** benar-benar bisa dipanggil (tidak error saat dipakai)
- Apakah **mcpServers block eksplisit** perlu ditambah ke settings.json untuk memastikan koneksi persistent (tidak hilang setelah restart)

---

## 🎯 Tujuan Brainstorming

User bilang: *"rekomendasi anda adalah buat install docker, anda juga Analissa kalo claude mem juga berjala di local host http://localhost:37777/, dan aman aja kalo tanpa docker, gimana saran anda biar claude mem bisa connect dan biar server beta juga jalan"*

**Pertanyaan inti yang harus dijawab:**
1. Apakah perlu install Docker? → **TIDAK**
2. Apakah server di 37777 sudah cukup untuk "claude mem connect"? → **YA, sudah**
3. Apakah perlu setup tambahan? → **Minimal — hanya verify**
4. Apa itu "server beta" yang user sebut? → **Plugin author memisahkan 2 service**:
   - `worker-service.cjs` (yang sudah jalan di 37777) — handles observations, hooks
   - `server-beta-service.cjs` (1.8MB, lebih besar) — kemungkinan beta/development version dengan fitur tambahan

---

## 💡 3 Pendekatan (Options)

### Option A — **Status Quo: Biarkan apa adanya** (RECOMMENDED) ⭐
**Apa:** Jangan ubah apapun. Server 37777 sudah jalan, MCP tools sudah visible, plugin hooks sudah registered.

**Cara verify:** Panggil 1-2 tool MCP di sesi berikutnya untuk pastikan response OK.

**Pro:**
- Zero risk — tidak ada perubahan yang bisa break
- Server sudah terbukti stabil (PID 13248, 26+ menit uptime, 1 active session)
- Docker tidak perlu diinstall
- Biaya setup: NOL

**Kontra:**
- Tidak ada improvement; jika nanti perlu fitur dari server-beta, harus setup manual
- Plugin akan auto-update worker saat update, yang kadang bisa break

**Cocok untuk:** User yang hanya butuh observability & memory recall (use case utama claude-mem).

---

### Option B — **Verify + Add mcpServers Block Eksplisit** (DEFENSIVE)
**Apa:** Tambahkan `mcpServers` block ke `settings.json` untuk **memastikan** MCP claude-mem terdaftar secara eksplisit (tidak hanya via plugin auto-discovery).

**Snippet yang akan ditambah:**
```json
{
  "mcpServers": {
    "claude-mem": {
      "type": "stdio",
      "command": "node",
      "args": [
        "C:/Users/farid/.claude/plugins/cache/thedotmack/claude-mem/13.4.0/scripts/mcp-server.cjs"
      ],
      "env": {
        "CLAUDE_MEM_DATA_DIR": "C:/Users/farid/.claude-mem"
      }
    }
  }
}
```

**Pro:**
- Menjamin MCP server restart otomatis saat Claude Code restart
- Explicit configuration = easier to debug
- Bisa di-disable per-session jika perlu

**Kontra:**
- Risk conflict dengan auto-discovery plugin (mungkin duplikat server)
- Perlu restart Claude Code untuk apply
- mcp-server.cjs besar (329KB) — sedikit beban startup

**Cocok untuk:** User yang ingin kontrol eksplisit & predictable behavior.

---

### Option C — **Start server-beta-service.cjs** (EXPERIMENTAL)
**Apa:** Jalankan service kedua (`server-beta-service.cjs`, 1.8MB) di port berbeda untuk fitur beta/experimental.

**Cara:**
```bash
cd C:/Users/farid/.claude/plugins/cache/thedotmack/claude-mem/13.4.0/scripts
bun server-beta-service.cjs
```

**Pro:**
- Akses fitur beta terbaru plugin
- Bisa jalan paralel tanpa disrupt worker existing

**Kontra:**
- Service beta mungkin belum stabil (perhatikan nama "beta")
- Perlu port tambahan (kemungkinan 37778 atau configurable)
- Dokumentasi plugin tidak jelas tentang endpoint/path
- Tanpa Docker, restart management manual

**Cocok untuk:** User yang aktif ikut development plugin / pengen coba fitur baru.

---

## ✅ Rekomendasi Saya

**Pilih Option A (Status Quo) sebagai default**, dengan **+1 verification step**:

1. **JANGAN install Docker** — tidak ada untungnya untuk use case Anda
2. **JANGAN ubah settings.json lagi** hari ini (sudah kita edit untuk bash.exe fix)
3. **VERIFIKASI** dengan memanggil salah satu tool MCP claude-mem di sesi ini — kalau response OK, Anda 100% connected
4. **Bookmark** `http://localhost:37777/` di browser untuk akses viewer UI
5. **LANGKAH LANJUT (opsional, kapan saja):** Jika Anda butuh persistent settings, naik ke Option B nanti. Jangan sekarang karena kita baru saja edit `settings.json`.

**Reasoning:**
- Brainstorming skill **melarang asumsi "this is too simple"** — saya tetap present opsi
- Tapi root cause analysis menunjukkan **zero broken state** saat ini
- YAGNI principle: kalau sudah jalan dan aman, jangan over-engineer
- Server worker sudah terbukti stabil via supervisor pattern (auto-restart jika crash)

---

## ❓ Pertanyaan untuk User (Sebelum Apply)

Brainstorming skill **mewajibkan** approval sebelum apply perubahan apapun. Pertanyaan saya:

1. Apakah Anda ingin saya **verify** dengan test call ke salah satu tool MCP claude-mem (misal `mcp__plugin_claude-mem_mcp-search__list_corpora`)? Ini ZERO-RISK — hanya read call.

2. Atau Anda ingin langsung **naik ke Option B** (add explicit mcpServers block)? Ini butuh restart Claude Code.

3. Atau **skip semuanya** karena server sudah jalan dan Anda hanya butuh konfirmasi "semua baik-baik saja"?

---

## 🧪 Verification Commands (Run Anytime)

```bash
# Check worker health
curl http://localhost:37777/health

# Check worker PID
netstat -ano | findstr "37777"

# Check worker log
cat C:/Users/farid/.claude-mem/logs/worker-*.log 2>/dev/null | tail -20

# From inside Claude Code: test MCP tool (akan muncul jika connect OK)
# mcp__plugin_claude-mem_mcp-search__list_corpora
```

---

## 📁 File yang TIDAK Diubah (per CLAUDE.md "🔒 Yang TIDAK diubah")

- `settings.json` (selain fix bash.exe di Poin 1) — **TIDAK** ditambah mcpServers (pending approval)
- Plugin files di `~/.claude/plugins/cache/...` — read-only, jangan disentuh
- `~/.claude-mem/` data dir — read-only verification only
- `docker-compose.yml` plugin — diabaikan (Docker tidak relevan)

---

## 🔗 Context Tambahan

- Observation #1383 di database claude-mem **persis merangkum masalah ini** — saved by sesi sebelumnya
- Plugin author: thedotmack (https://github.com/thedotmack/claude-mem)
- Versi plugin: 13.4.0 (latest cache), 13.3.0 (older cache)
- CLAUDE.md plugin ada di `~/.claude/plugins/marketplaces/thedotmack/CLAUDE.md` (belum dibaca — bisa jadi berisi instruksi tambahan)
