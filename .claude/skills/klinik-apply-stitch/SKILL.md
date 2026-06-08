---
name: klinik-apply-stitch
description: Use when editing Flutter UI files in Klinik Sin She Jaya Abadi (lib/pages/, lib/widgets/, lib/features/*/page*.dart, lib/features/*/dashboard*.dart). Triggers when user wants to apply Stitch design, refactor a page, migrate raw values to design tokens, or match a Flutter screen to a Stitch KEEP reference. Visual-first workflow: read Stitch PNG, audit, present plan, get user OK, then code.
---

Applies Stitch KEEP designs to the Flutter Klinik codebase. Visual-first workflow: never code before seeing the Stitch reference and getting user confirmation on the plan.

## Root cause this skill exists to prevent

Past failure pattern: Claude audited raw values, wrote a task list from assumptions, coded without seeing the Stitch PNG, produced a result that diverged from the design, user had to correct and restart. This skill enforces a strict visual-first sequence to break that loop.

## When this skill runs

Auto-trigger when the user request matches any of:
- "apply stitch to <file>"
- "refactor <file> to match stitch"
- "migrate raw values in <file>"
- "implement <screen> from stitch"
- "edit lib/pages/<x>.dart" or "edit lib/widgets/<x>.dart" (UI files)
- "tambah section <x> ke <file>"

Skip when the request is clearly non-UI (DB query, migration, auth flow, business logic, test setup).

## Source of truth (read first, in order)

1. `docs/PROJECT_PROGRESS.md` — current phase, what's done, what's next.
2. `docs/STITCH_SOURCE_OF_TRUTH.md` — list of 16 KEEP folders and 18 IGNORE (historical). Use KEEP only.
3. **MCP Stitch** → `mcp__stitch__list_screens(projectId: "4910840135092048917")` → cari screen ID matching KEEP folder → `mcp__stitch__get_screen(projectId, screenId)` → ambil screenshot PNG → **Must read PNG with `Read` tool to render as image. Do not skip this step.**
4. `docs/superpowers/specs/step1-token-map.md` — palette, typography, radius, spacing, shadow tokens. The only allowed token values.
5. `lib/core/design_system/app_tokens.dart` and `emil_design.dart` — current Dart token implementation. Verify token exists before using it. If a needed token is missing, surface to user before adding.

## Workflow per file (strict order, no skipping)

### Step 1 — See Stitch (non-negotiable)

**Read the Stitch KEEP PNG with the `Read` tool before touching any code.** The tool renders the image inline. This is the visual anchor for everything that follows.

- Find the matching KEEP folder from `STITCH_SOURCE_OF_TRUTH.md`.
- If there are multiple PNGs in the folder, read all of them.
- If the page maps to multiple KEEP folders, read each one.
- If no KEEP matches, stop and tell the user — do not invent a layout.

Output: a 2–3 line description of what the Stitch KEEP shows (header, sections, color blocks, key components).

### Step 1.5 — Skill consultation (mandatory)

**Invoke both skills via the `Skill` tool before any code edit.** Do not skip. This is the project's standing rule from `CLAUDE.md`.

1. **`impeccable`** — load the audit + critique framework. Use it to score the planned change on P0/P1/P2 severity (visual hierarchy, spacing rhythm, color discipline, typography, motion, a11y). Surface any P0 finding to the user in the Step 3 plan.
2. **`ui-ux-pro-max`** — load the prescriptive reference. Match the planned change against:
   - **Style**: default = Restrained color strategy + Material 3.
   - **Typography**: Plus Jakarta Sans, 4dp base, 48dp touch target.
   - **Palette / radius / spacing**: 12–16dp premium-soft radius; use the Healthcare POS / Clinic POS product-type presets.
   - **A11y baseline**: contrast, focus, target size.
   - **Anti-generic filter**: reject cream-warm, Inter default, purple-blue gradient, decorative gradients on data UI.

If either skill flags a conflict with the Stitch KEEP or the token map, surface it in Step 3 and let the user decide.

Output: a 3–5 line note: "impeccable: P0/P1/P2 findings", "ui-ux-pro-max: style/palette/font/a11y match".

### Step 2 — Audit current Flutter file

- Open the target file with `Read`.
- Note the existing structure: sections present, sections missing vs. Stitch, raw values that should be tokens.
- Token audit:
  - `Color(0xFF...)` → `AppColors.*`
  - `SizedBox(width|height: N)` → `AppSpacing.*`
  - `BorderRadius.circular(N)` → `AppRadius.*`
  - `fontSize: N` literal in `TextStyle` → `AppTextStyles.*.copyWith(fontSize: N)` only if `N` matches a token scale; otherwise flag as "token missing"
  - `BoxShadow(...)` → `AppShadows.*`
- Identify sections present in Stitch KEEP but missing in Flutter file → list as "to add".
- Identify sections present in Flutter but not in Stitch KEEP → flag for user decision (keep, remove, or relocate).

Output: a structured diff. Sections present/missing. Token gaps.

### Step 3 — Present plan, wait for OK

**Do not start coding until the user confirms the plan.** Present:

1. **Visual target**: which KEEP PNG, what it shows.
2. **Section plan**: which sections to add, modify, or remove.
3. **Token plan**: which tokens to use, which new tokens (if any) need user approval to add to `app_tokens.dart`.
4. **Risk callouts**: anything that touches business logic, state, navigation, dark mode, or responsive behavior.
5. **Test plan**: which tests to add or update.

Wait for explicit "OK" / "lanjut" / "proceed" before Step 4. If the user corrects the plan, revise and re-present.

### Step 4 — Code

- Replace raw values with tokens per Step 2 audit.
- Add missing sections per Step 3 plan.
- Preserve widget structure and logic. Do not refactor business logic, state, navigation, or naming unless required.
- One file = one commit. Do not bundle.
- If a token value is needed but not in `step1-token-map.md` and not in `app_tokens.dart`, stop and ask.

### Step 5 — Visual match check

- Re-read the Stitch KEEP PNG and the changed Flutter file side by side.
- Compare: header layout, color blocks, card structure, spacing rhythm, typography hierarchy, icon usage.
- If any region diverges >10% from KEEP, revise the code. Do not declare done until match is acceptable.
- If a true visual match is impossible without breaking tokens or business logic, surface to user with screenshot evidence.

### Step 6 — Test

- Run `flutter analyze` (must be clean).
- Run `flutter test` (must stay green; pre-existing failures noted, not new ones).
- If new sections were added, write at least 1 widget test per new section.

### Step 7 — Commit

- One commit per file. Message format: `refactor(<area>): <what changed> per Stitch KEEP/<folder>`.
- Co-author line: `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`.
- Do not amend. If pre-commit hook fails, fix root cause and create a new commit.

## Multi-agent parallelism (mandatory for batch work)

When the user asks to apply Stitch to **multiple files** at once (e.g. "apply to all login pages", "refactor all pages in lib/pages/"), **spawn parallel `Agent` (general-purpose) subagents** instead of doing it sequentially in this session. This is a hard rule, not an optimization.

### Why this is mandatory
- Sequential work is too slow for batch refactor across many files.
- Each subagent works on its own file with full isolation.
- Results come back in one round, ready to commit per file.

### How to dispatch
1. **Pick the file list first.** Confirm with user if ambiguous (don't guess). List should be 2+ files for multi-agent to make sense.
2. **One subagent per file.** Each subagent gets:
   - File path
   - Corresponding Stitch KEEP folder
   - Token map file
   - Skill output contract (read PNG, audit, plan, code, test, report)
3. **Launch in parallel** — single message, multiple `Agent` tool calls.
4. **Per-subagent test gate.** Each subagent must run `flutter analyze` + `flutter test` on its own file before reporting back. If a subagent reports a pre-existing failure, mark it explicitly in its report.
5. **Aggregate results in main session.** After all subagents return, summarize:
   - Files changed (per-file)
   - Tests status
   - Any P0 finding flagged by skill consultation
   - Any residual raw value with documented reason
6. **Commit per file** in main session (one commit = one file).

### Subagent prompt template (use this skeleton)

```
You are applying a Stitch KEEP design to one Flutter file in project Klinik Sin She Jaya Abadi.

Constraints (read these files first):
- D:/flutter_klinik_starter/.claude/skills/klinik-apply-stitch/SKILL.md  (the workflow)
- D:/flutter_klinik_starter/docs/superpowers/specs/step1-token-map.md  (allowed tokens)
- D:/flutter_klinik_starter/CLAUDE.md  (project rules)
- D:/flutter_klinik_starter/docs/PROJECT_PROGRESS.md  (current phase)

Your target:
- Flutter file: <lib/path/file.dart>
- Stitch KEEP folder: Screen ID via `mcp__stitch__list_screens(projectId: "4910840135092048917")`

Follow the SKILL.md workflow strictly:
1. Read the Stitch PNG (use Read tool on the image file inside the KEEP folder).
2. Invoke Skill `impeccable` AND Skill `ui-ux-pro-max` (mandatory per SKILL.md).
3. Audit current Flutter file (raw values, section gaps vs KEEP).
4. Present a 5–8 bullet plan. WAIT for user OK before coding.
5. Code per plan. Use only tokens from step1-token-map.md. No new tokens without user approval.
6. Re-read PNG, compare section-by-section, fix any >10% visual drift.
7. Run `flutter analyze` (must be clean) + `flutter test` (must stay green).
8. Report back with: sections changed, raw value delta, skill findings, test result.

Do NOT touch: schema, RLS, RPC, business logic, role detection, stok logic, auth flow, printer.
Do NOT add new tokens. If a needed token is missing, surface and stop.
Do NOT amend commits. One commit per file (main session will commit after you return).
```

### When NOT to use multi-agent
- Single-file refactor (1 subagent = 0 parallelism benefit).
- Changes that cross-edit the same file (race condition risk).
- Any task that requires coordinated schema/RLS/RPC changes.
- Debugging a single bug — sequential investigation is faster.

## Hard rules (do not violate)

- **Skill consultation mandatory.** Before any code edit (Step 4), invoke both `Skill` tools: `impeccable` (severity audit) and `ui-ux-pro-max` (style/palette/font/a11y match). No exceptions. If a skill flags a conflict with Stitch KEEP or the token map, surface it in Step 3 plan and wait for user decision.
- **Stitch KEEP only.** IGNORE folders in `STITCH_SOURCE_OF_TRUTH.md` are historical reference. Do not use them as visual source.
- **Visual first, code last.** No code before reading the Stitch PNG and getting user OK on the plan.
- **No invented tokens.** If a value is not in `step1-token-map.md` and not in `app_tokens.dart`, ask the user before adding it.
- **Do not touch** stok logic, auth flow, role detection, printer logic, schema, RLS, RPC, or migrations — even if the file also contains UI. Refactor only the UI parts. If refactor requires touching those, stop and ask.
- **DB SELECT is OK.** INSERT/UPDATE/DELETE/ALTER require showing the SQL first and waiting for explicit `LANJUT`.
- **One file = one commit.** Do not bundle multiple files.
- **Test after every change.** `flutter analyze` + `flutter test` per file.
- **Do not delete files** without explicit user approval. Renames are OK with approval.
- **Do not write task lists from assumptions.** Tasks must be derived from a Stitch KEEP read + a plan-confirmed-with-user. Asumsi = stop, baca dulu.

## Soft preferences (follow unless user says otherwise)

- Minimal diff. Don't refactor nearby code that's working.
- Keep existing copy (Indonesian strings) unless Stitch KEEP clearly differs.
- Use `AppColors.*`, `AppSpacing.*`, `AppRadius.*`, `AppTextStyles.*`, `AppShadows.*` from `app_tokens.dart`. If a token doesn't exist there, check `emil_design.dart` or `docs/superpowers/specs/step1-token-map.md`.
- For dark mode, check both `LightColors.*` and `DarkColors.*` references — the file likely already has them. Do not break dark mode.
- Reuse existing widget helpers (`DashboardSummaryCard`, `DashboardMenuCard`, `QuickActionGrid`, etc.) before building new widgets.

## Output format (after every file)

Report:
- Stitch KEEP source (folder + PNG filename)
- File changed (with line range)
- Sections added/modified/removed
- Tokens added/used (name only)
- Visual match notes (matches KEEP, what's still off)
- Test result (analyze + test pass count)
- Commit hash + message
- Risks / open questions (if any)

## When to stop and ask

- Token value needed but not in map → ask before adding
- Stitch KEEP reference is ambiguous or missing the page → ask
- Refactor requires touching stok/auth/role/printer/schema → ask
- User instruction conflicts with hard rules → ask
- Visual match requires breaking existing behavior → ask
- Plan is ready and waiting for OK → ask (do not code yet)
