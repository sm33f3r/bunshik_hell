# Bunshik Hell Project Log 004

**Session:** 17 November 2026 (Asia/Seoul)
**Mode:** DEV (planning). No code was written.
**Status labels:** ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
**Previous log:** `bunshik-hell_log-003.md`
**Repo path for this file:** `documentation/logs/`

> **New session? Start here.** Read this log, then the documents in §1. The next step is in §6.

---

## 1. Documents

| Document | Repo path | Status |
|---|---|---|
| `bunshik-hell-episode-1-master-roadmap.md` | `documentation/roadmaps/` | **New. Frozen.** Phases 0–10, each with steps, a done checklist and a gate. Phase 0 is complete. |
| `bunshik-hell-systems-spec-v0.1.md` | `documentation/production/` | Current. Overtaken in places (log 003 §4, and §3 below). |
| `bunshik-hell-dev-decisions-v0.1.md` | `documentation/production/` | Current. Overtaken in places (log 003 §4, and §3 below). |
| `bunshik-hell-episodes-and-maps-v0.1.md` | `documentation/production/` | Current. Re-sent this session because it had never been saved into the repo. |
| `bunshik-hell_log-003.md` | `documentation/logs/` | Previous log: Tasks 1a–1c, the playtest, repo and machine setup. |
| Bible Part 1, Demo Master Roadmap, First Ideas | `design/`, `roadmaps/` | Records. |
| `sdk-master-roadmap.md` | Project only | NHMH Godot–Sui SDK. Not read in a Bunshik Hell session yet. Needed for Roadmap Phase 10. |

**Repo state:** the commit adding log 003 and Episodes and Maps v0.1 had **not succeeded** at the start of this session (the second file was missing). ❓ Confirm that log 003, log 004, Episodes and Maps v0.1 and the Episode 1 Master Roadmap are all committed.

---

## 2. Decisions

| # | Decision | Status |
|---|---|---|
| 1 | **DualSense inventory goes on the touchpad.** Built on Back/Create in Task 1a; to be changed in the next DEV task (Roadmap Phase 3, step 10). | ✅ |
| 2 | **Art starts early, piece by piece**, with the essentials first: the style brief, the private art repo, a Blender → Godot shape-key test, the 떡's final model, then the Map 1 enemies one at a time. It runs alongside core systems and Map 1 (Roadmap Phase 2). Each map gets its art pass only after it passes its gray-box gate. | ✅ |
| 3 | **Episode 1 has at least one friend and one merchant.** A friend who doesn't teach a skill can greet the 떡 and say something random that makes no sense yet and turns out later to be a story clue. | ✅ |
| 4 | **Release goals:** a demo and a "coming soon" page first; then Episode 1 of Bunshik Hell, Noraebang Night and Hangul Hiking Trip in the same month, with the DDEOK website (ddeok.org or ddeok.xyz ❓), a staking pool, and a small NFT collection bought and sold at in-game merchants for DDEOK. | ✅ goal |
| 5 | After that, apply for funding and grants from any institutions, companies or individuals who want more episodes, aiming for full-time work on all three games. (STRATEGY) | ✅ goal |
| 6 | **Merchandise** on the website later, after getting the needed licence. ⚖️ | ✅ goal |
| 7 | **No fixed deadlines.** Make as much progress as possible. | ✅ |
| 8 | **The demo is Map 1** (prologue, tutorial, the Mutant 라볶이), ending on a "to be continued" card (Roadmap Phase 5). | 🟡 (in the roadmap) |
| 9 | **Specs are written just ahead of building.** Phase 1 covers the Episode 1 overview and Map 1; Maps 2 and 3 get their specs at the start of their own phases. | ✅ (in the roadmap) |
| 10 | **Move to a fresh context window** at the start of Phase 1. This conversation had grown very long; the logs and docs carry everything forward. | ✅ |

---

## 3. Where earlier docs are now out of date

| Doc | Says | Now |
|---|---|---|
| Dev Decisions v0.1 §6, Systems Spec v0.1 §4 | Inventory on View / Touchpad | **Touchpad** ✅ (built on Back/Create; change pending) |
| Dev Decisions v0.1 §1 | Platforms and on-chain order | Unchanged, but the release goal now ties Episode 1 to an NHMH-wide launch month (§2 #4) |
| Systems Spec v0.1 §5 #3 | Sauce costs placeholders | Unchanged (still set after playtesting) |

The full list of Systems Spec v0.1 gaps is in log 003 §4. **Systems Spec v0.2** (Roadmap Phase 1, step 7) picks them all up.

---

## 4. Answers recorded from the roadmap discussion

- **When art starts:** Roadmap Phase 2, running alongside Phases 3 and 4. Before Phase 2, there's no style brief, so models would be remade. Delaying it further would hold up the demo, since the 떡 is on screen every second.
- **Friends and merchants:** designed in Phase 1 (Episode 1 characters v0.1), built in Phase 3 (talking, the merchant shop, off-chain DDEOK).
- **On-chain:** Roadmap Phase 10, after Episode 1 is complete, timed with the DDEOK website, the staking pool and the NFT launch.

---

## 5. Open items

**New**
1. ❓ Does Episode 1 **launch with on-chain switched on**, or release off-chain and get on-chain in an update? Depends on the SDK being ready for Windows and Linux desktop.
2. ❓ DDEOK website domain: ddeok.org or ddeok.xyz.
3. ❓ Confirm the four documentation files are committed (§1).

**Carried from log 003 §8**
4. ❓ Laptop: `git pull`; global vs repo-local git identity.
5. ❓ Art repo name; 🔍 GitHub LFS limits.
6. ❓ Inventory container types (Roadmap Phase 1, step 5).
7. ❓ SDK milestone order (desktop vs web first) and Bunshik Hell's first on-chain features.
8. ⚖️ README copyright holder; asset licence switch; AI music copyright.
9. From log 002: the woman's identity; episode exits and order; missing third maps; the Map 2, Map 3 and world final bosses; the 분식집 Owner; 감칠맛; sauce costs; real-place facts 🔍; Suno terms 🔍.

---

## 6. Next

**Episode 1 Master Roadmap, Phase 1, step 1: the Episode 1 enemy roster v0.1**, in a fresh session (MODE: CHAT).

Starting material: the accepted enemy list in log 002 §6, the food-reaction table in Systems Spec v0.1 §8, and the Bible's confirmed enemy rules (§13–15).

Then Phase 1, steps 2–7 in order: boss sheet v0.1, characters v0.1, skill sources, inventory containers, Map 1 spec v0.1, Systems Spec v0.2.
