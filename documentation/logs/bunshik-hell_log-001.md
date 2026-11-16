# Bunshik Hell Phase 1 Project Log

**Log:** 001 (first Bunshik Hell log)
**Phase:** 1 — Foundation & Setup
**Sessions:** planning and setup session (repo file dates show 2026-08-24, Asia/Seoul); review session 2026-11-11
**Modes:** CHAT (planning), DEV-style setup
**Status labels:** ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional
**Repo path for this file:** `documentation/logs/`

---

## 1. Documents this log refers to

| Document | Status |
|---|---|
| `BUNSHIK_HELL_GAME_DESIGN_BIBLE_PART_1.md` | Canonical design source. Where the roadmap and the Bible conflict, the Bible wins. |
| `Bunshik_Hell_Demo_Master_Roadmap.md` (Revised) | **Frozen** from this log on (NHMH Global Rule 3). Departures are recorded in logs, not edited in. |
| `BUNSHIK_HELL_FIRST_IDEAS.md ` | Early brainstorm. Kept for context. Filename has a trailing space (§7). |
| `Bunshik_Hell_Game_Development_Plan.md` | Original plan. Superseded by the Bible and the revised roadmap. A copy named `Bunshik_Hell_Game_Development_Plan (1).md` is in the NHMH project files; whether it differs is ❓. |

The first roadmap draft (shooter-style, written before the Bible was read) was replaced by the revised roadmap and should not be used.

---

## 2. Project placement

| # | Decision | Status |
|---|---|---|
| 1 | Bunshik Hell now runs inside the NHMH project and follows its document system: frozen roadmaps, versioned production docs, one numbered log per session, the modes and the Global Rules. | ✅ |
| 2 | Repo documentation layout: `documentation/roadmaps/`, `documentation/logs/`, `documentation/design/`, `documentation/production/`, with further subfolders as needed. | ✅ |
| 3 | Claude Code is set up on both machines (Windows 11 PC and CachyOS laptop). The DEV workflow applies: plan, Claude Code prompt, tests, then git commands given by DEV. | ✅ |

---

## 3. Design and scope decisions

| # | Decision | Status |
|---|---|---|
| 1 | The first build is **Bunshik Hell 0.1**: one tutorial 분식집 level, a few enemies and one boss. Build only the essentials while preparing for a larger project. | ✅ |
| 2 | The 0.1 boss is the **Mutant 라볶이**, a corrupted mirror of the 떡 fused with 라면. | ✅ |
| 3 | The **붕어빵 boss** belongs to the later winter-themed level. Out of scope for 0.1. | ✅ |
| 4 | The roadmap has **five phases**: Foundation & Setup; The 떡: Locomotion & Combat; The Food Ecosystem & Level 1; The Mutant 라볶이 Boss; Polish & Demo Release. Each phase ends with a gate. | ✅ |
| 5 | Enemy count is **not hardcoded**. Roughly 4–5 types, decided in session. The Bible's confirmed roster (만두, 뻔데기, 어묵, 라면, lit cigarettes, 튀김 + fryer) is the candidate pool. | ✅ count flexible / ❓ final 0.1 lineup |
| 6 | Art approach: **somewhere in between** placeholder and full art. Geometry for prototyping, then rough but intentional hand-drawn sprites before the demo. | ✅ |
| 7 | **Sauce controls, roll controls, bounce rules and the health model are decided in session through prototyping**, and revised as testing shows. They are not written into roadmaps ahead of testing. | ✅ |
| 8 | Locomotion reference: the original **Worms**. The 떡 squiggles forward with its whole body while the stick or keys move it left or right. | ✅ |
| 9 | Implement the squiggle first as **frame-based squash-and-stretch animation**. Move to Skeleton2D or Polygon2D deformation only if frames don't feel right. | 🟡 |

---

## 4. Engine and tools

| # | Decision | Status |
|---|---|---|
| 1 | Engine: **Godot** (not Unity or Unreal). Reasoning: free, no royalties, native 2D. For reference, Hollow Knight and Cuphead used Unity; Little Nightmares used Unreal Engine 4. | ✅ |
| 2 | Installed **Godot 4.7.2.stable.arch_linux** (`ed1daf0bf`) on the CachyOS laptop via `pacman`. Confirmed with `godot --version`. | ✅ |
| 3 | The Godot project lives in a **`game/` subfolder** of the repo. The project manager refused to create a project at the repo root ("engine's working directory"). | ✅ |
| 4 | Renderer: **Compatibility** was intended for 2D, but it was not selected at creation. A previous reply said Compatibility is the default for new projects; that claim is unverified and probably wrong. **Check `game/project.godot` or Project Settings → Rendering → Renderer.** | 🔍 |
| 5 | Shell on the laptop is **fish**. Bash heredocs (`<< 'EOF'`) don't work; future commands must be fish-compatible. | ✅ |
| 6 | `git config --global core.editor nano` set after a merge-message editor hung the terminal during `git pull`. | ✅ |

---

## 5. Repository and GitHub

| # | Item | Status |
|---|---|---|
| 1 | Repo: **`github.com/sm33f3r/bunshik_hell`**, public, on the `sm33f3r` account. Local folder `~/bunshik-hell`, branch `main`. | ✅ |
| 2 | SSH key `~/.ssh/id_ed25519_sm33f3r` for `sm33f3r`. `~/.ssh/config` defines host alias `github-sm33f3r`; remote is `git@github-sm33f3r:sm33f3r/bunshik_hell.git`. The existing `id_ed25519` key maps to `github-eth4nh4rdy`. | ✅ |
| 3 | Git identity was set **globally** to `sm33f3r` / `smeefer@gmail.com`. The plan was a repo-local identity. On the laptop, this now also applies to `eth4nh4rdy` repos. Decide whether to move it to repo-local config. | ❓ |
| 4 | `ssh-agent` was started with `eval (ssh-agent -c)` for one shell only. Future shells may need the key added again, or a persistent agent setup. | 🔍 |
| 5 | The first push used `git push --force` and **overwrote GitHub's initial commit `994f058`**. That commit was generated by GitHub's create-repo options and most likely held the **GPL v3 LICENSE** chosen in the picker. The repo probably has **no LICENSE file now**. This was irreversible and done without the confirmation required by Global Rule 12. | 🔍 check on GitHub |
| 6 | Commits pushed: `57a9045` (init: `.gitignore`, `README.md`), `89c5bcb` (Bible, roadmap, first ideas into `documentation/`). | ✅ |
| 7 | Commit "Phase 1: initialize Godot project" (`game/`) was given but **push not confirmed**. | 🔍 |
| 8 | The root folders `assets/ characters/ enemies/ bosses/ levels/ scripts/ ui/ audio/ shaders/ tests/` were created locally but **never pushed**, because git doesn't track empty folders. | ✅ (fact) |

---

## 6. Licence

| # | Decision | Status |
|---|---|---|
| 1 | Code licence: **AGPL-3.0**. Supersedes the earlier GPL v3 suggestion (and the GPL v3 picked in GitHub's picker, likely lost in the force push). | ✅ |
| 2 | Art and audio assets: **All Rights Reserved**, stated separately in the README, so nobody else can sell the game with its assets. Suggested in session, not yet confirmed or written. | 🟡 |
| 3 | Selling for USDC or SOL and taking donations is compatible in principle with an open-source licence when the developer holds the copyright. This came from chat and is not legal advice. | ⚖️ |
| 4 | Lawyer review needed before any sale: the AGPL code / All Rights Reserved asset split, contributor rights (whether a CLA is needed for future relicensing or sales), and crypto payments and tax. | ⚖️ |
| 5 | Godot is MIT-licensed. Compatibility with AGPL-3.0 is expected but unverified here. | 🔍 |

---

## 7. Deviations from the Demo Master Roadmap (Phase 1)

| Roadmap says | What happened |
|---|---|
| Step 1: adopt Bible §20 as the pitch and store it in `documentation/` | The Bible is in the repo; no separate pitch file was written. ❓ Is the Bible enough? |
| Step 2: write the 0.1 scope document | **Not written.** |
| Step 3: resolve sauce, roll, bounce and health before building | **Dropped.** These are Phase 2 prototyping experiments (§3 decision 7). Also removes the "working-decisions document" from Phase 1's definition of done. |
| Step 5: content folders at the repo root | Godot project is in `game/`; root content folders were not pushed (§5). ❓ Do the content folders move inside `game/`, where `res://` can reach them? |
| Step 5: docs flat in `documentation/` | New layout `documentation/{roadmaps,logs,design,production}` decided; existing files have not been moved yet. |
| Step 6: write placeholder-art rules | **Not written** as a document. The rule (geometry plus a deformable blob for the 떡) exists only in the roadmap. |
| Definition of done: "Godot project opens and runs an empty scene" | The project opens in the editor. No scene was created or run. 🔍 |

**Phase 1 gate:** scope is small enough ✅. The second half of the gate ("locomotion/combat decisions concrete enough") is replaced by §3 decision 7.

---

## 8. Open items before Phase 2 code

1. ❓ Content folders: move inside `game/` (recommended so Godot can load them) or keep at root.
2. 🔍 Confirm the `game/` commit was pushed.
3. 🔍 Check the renderer setting in `game/project.godot`.
4. 🔍 Check whether a LICENSE file exists on GitHub; add an **AGPL-3.0** LICENSE and the README asset notice.
5. ❓ Move existing docs into `documentation/roadmaps/` and `documentation/design/`; add this log under `documentation/logs/`.
6. ❓ Rename `BUNSHIK_HELL_FIRST_IDEAS.md ` (trailing space).
7. ❓ Global versus repo-local git identity on the laptop.
8. ❓ Is `Bunshik_Hell_Game_Development_Plan (1).md` a duplicate or a newer version?
9. ❓ Whether to write the 0.1 scope doc and placeholder-art rules as production docs (v0.1), or leave them to the roadmap.

---

## 9. Next

**Phase 2 — The 떡: Locomotion & Combat**, in MODE: DEV. First step: a Worms-style squiggle prototype (`CharacterBody2D`, placeholder blob, left/right input, a squash-and-stretch cycle while moving, idle when stopped). Brainstorm and plan first, then a Claude Code prompt with permission.
