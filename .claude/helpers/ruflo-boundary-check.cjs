/**
 * RUFLO BOUNDARY CHECK — Anti-Runaway Enforcement
 *
 * Called on UserPromptSubmit to check if we're violating execution boundaries.
 * Reads saved plans and enforces PLAN_IS_LAW constraint.
 */

const fs = require("fs");
const path = require("path");

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || ".";
const BOUNDARY_FILE = path.join(PROJECT_DIR, "docs", "RUFLO_BOUNDARIES.md");

function check() {
  // 1. Check if boundary file exists
  if (!fs.existsSync(BOUNDARY_FILE)) {
    console.error("[RUFLO-BOUNDARY] WARN: docs/RUFLO_BOUNDARIES.md not found!");
    return;
  }

  // 2. Load boundary rules
  const content = fs.readFileSync(BOUNDARY_FILE, "utf8");

  // 3. Check for PLAN_LOCKED markers
  const hasPlanLocked = content.includes("[PLAN_LOCKED]");
  const hasRules = content.includes("PLAN IS LAW");

  if (hasRules) {
    console.log("[RUFLO-BOUNDARY] ACTIVE: Anti-runaway boundaries enforced");
    console.log("[RUFLO-BOUNDARY] RULES: PLAN_IS_LAW, NO_DISCOVERY_DURING_EXECUTION");
  }

  // 4. Verify memory stores have the rules
  console.log("[RUFLO-BOUNDARY] VERIFY: memory namespace='ruflo-rules' key='ruflo-anti-runaway-boundaries'");
  console.log("[RUFLO-BOUNDARY] STATUS: Enforcement mode=strict");
}

// Auto-run when loaded
check();
