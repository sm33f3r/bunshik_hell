# Bunshik Hell — Dev Decisions

*Production doc v0.1 · 16 November 2026 · Mode: DEV*
*Repo path: `documentation/production/`*

> Production document. Changes are made by issuing a new version (v0.2…); this file stays unchanged.
> What is actually built, and every deviation, goes in the project logs.
> ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional

Reads with: `bunshik-hell_log-002.md` (latest log), `bunshik-hell-episodes-and-maps-v0.1.md`, `sdk-handoff-dev.md` (NHMH Godot–Sui SDK).

---

## 1. Platforms and release

| # | Decision | Status |
|---|---|---|
| 1 | **Priority 1:** downloadable, installable builds for **Windows and Linux**, from NHMH's website. | ✅ |
| 2 | **Priority 2:** playable in a web browser on NHMH's site. Skipped if it proves too difficult. | ✅ |
| 3 | **Priority 3:** Android. | ✅ |
| 4 | **Priority 4:** iOS and macOS. | ✅ |

---

## 2. Engine, renderer and physics

| # | Decision | Status |
|---|---|---|
| 1 | **Godot 4.7.2 stable**, GDScript. The same version on both machines. ❓ Confirm the Windows PC's version. | ✅ / ❓ |
| 2 | **Forward+ renderer**, to make the desktop version look its best. | ✅ |
| 3 | `game/project.godot` has no `rendering_method` line today (most likely the Forward+ default 🔍). The first DEV task sets it explicitly. | 🟡 |
| 4 | Web needs the Compatibility renderer and Android the Mobile renderer. Those platforms get their own visual pass when their turn comes. 🔍 Check per-platform renderer overrides in 4.7 then. | ✅ consequence |
| 5 | **Jolt physics.** New projects use Jolt for 3D by default since Godot 4.6, so this project (made in 4.7.2) should already be on it. 🔍 Confirm in Project Settings. | 🟡 |
| 6 | **2.5D:** the 떡 is a `CharacterBody3D` locked to one plane (no depth movement). Side camera. Depth is for scenery, parallax and foreground objects. | 🟡 |

---

## 3. Repositories and layout

### 3.1 Two repositories

| Repo | Visibility | Holds | Status |
|---|---|---|---|
| `sm33f3r/bunshik_hell` | Public | Code, game-ready assets (`.glb`, textures, `.ogg`), documentation | ✅ |
| Art repo (🟡 `bunshik_hell_art`) | **Private** | Blender `.blend` sources, Krita files, Grease Pencil concepts, Suno masters. Uses **Git LFS** 🔍 (check GitHub's current LFS limits before creating). | ✅ private / 🟡 name |

### 3.2 Public repo layout

```
bunshik_hell/
├── LICENSE                     AGPL-3.0 (to add)
├── README.md                   includes the asset-rights notice
├── CLAUDE.md                   agent rules (§10)
├── documentation/
│   ├── roadmaps/   design/   production/   logs/
└── game/                       res:// (project.godot lives here)
    ├── player/                 the 떡: scene, state machine, skills
    ├── enemies/                one folder per enemy: scene + behaviour
    ├── bosses/
    ├── items/
    ├── maps/ep01/              map01_bunsikjip/, map02_.../, map03_.../
    ├── data/                   .tres content: enemy defs, items, skills, reaction table
    ├── systems/                autoload scripts (§5)
    ├── ui/
    ├── audio/                  music/ (Suno .ogg), sfx/
    ├── shaders/
    ├── assets/                 exported .glb models, textures, fonts
    └── tests/                  headless test runner and tests
```

Folder names are 🟡 until the first DEV task creates them.

---

## 4. Content as data

| # | Decision | Status |
|---|---|---|
| 1 | **Our own content is `.tres`** (Godot custom Resources): enemy definitions, items, skills, the food-reaction table. Typed, edited as forms in the inspector, file links stay valid when files move. | ✅ |
| 2 | **Anything from outside, or going on-chain, is JSON:** saves, and player-made items planned for the DDEOK store. | ✅ |
| 3 | **Never load `.tres` or `.res` from outside the game.** A resource file can reference scripts, so loading one from a stranger is a code-execution risk. | ✅ |
| 4 | A new enemy or item is a data file plus, at most, a small behaviour script. Anything that needs new engine code gets flagged. | ✅ |
| 5 | The **food-reaction table** (attack type × enemy material → reaction) is one Resource, so every enemy reads the same rules. | 🟡 |

---

## 5. Core architecture (🟡)

| Autoload | Owns |
|---|---|
| `GameState` | Hearts, sauce, 나트륨 (each capped at 7), inventory, unlocked skills, current episode and map |
| `SaveSystem` | JSON saves: compact and versioned (`save_version`), migrations between versions |
| `Settings` | Key rebinding, instant-heal default item, audio, display, **play on-chain / off-chain** |
| `ChainBridge` | The only door to Sui (§7). Off-chain stub for Episode 1 |

- **The 떡** is a state machine: idle, squiggle, jump, double jump, stomp, roll, slam, hurt, dead. Skills are unlocked by flags in `GameState`.
- **Enemies** share one base (health, hurt, death, reaction lookup) and differ by their `.tres` data and a behaviour script.
- **Damage always goes through the reaction table.** Nothing hardcodes "this attack kills that enemy".

---

## 6. Input (🟡 action names for controls v0.1)

| Action | Keyboard + mouse | Controller |
|---|---|---|
| `move_left` / `move_right` | A / D | Left stick |
| `look_up` (talk, enter) | W | Stick up |
| `look_down` (drop through; stomp in the air) | S | Stick down |
| `jump` (double jump in the air) | Space | A / ✕ |
| `roll` (slam in the air) | Left Shift | B / ○ |
| `sauce_attack` | Left mouse | X / □ |
| `sauce_next` / `sauce_prev` | Q, mouse wheel | RB / R1, LB / L1 |
| `aim_*` (later skills) | Mouse | Right stick |
| `special` (나트륨) | Right mouse | Y / △ |
| `heal` | R | LT / L2 |
| `inventory` | Tab | View / Touchpad |
| `pause` | Esc | Menu / Options |

All actions can be rebound; bindings are saved by `Settings`. ✅

---

## 7. On-chain readiness

| # | Decision | Status |
|---|---|---|
| 1 | **Bunshik Hell stays off-chain until Episode 1 is completely finished.** | ✅ |
| 2 | **Prepared from the start**, so going on-chain later is easy. | ✅ |
| 3 | Players choose **"play on-chain"** (connect a Sui wallet) or **"play off-chain"**. Off-chain, DDEOK rewards, clothing NFTs and item NFTs are virtual and not connected to Sui. **The same for HHT and Noraebang Night.** | ✅ |
| 4 | DDEOK is live on Sui **testnet**. | ✅ (fact) |
| 5 | **All chain access goes through `ChainBridge`.** Episode 1 ships with an off-chain implementation; the real one comes from the shared NHMH SDK addon (떡방앗간). | 🟡 |
| 6 | Saves, rewards and inventory use **stable IDs and JSON-ready shapes** from day one, so an item earned off-chain maps cleanly to an NFT type later. | 🟡 |
| 7 | **The game never creates or holds player private keys.** Players connect their own wallet (from the SDK handoff). | ✅ |
| 8 | ❓ **SDK milestone order.** The SDK handoff builds the web layer first (M1) and desktop later (M2). Bunshik Hell is desktop-first. Settle in the SDK DEV session. | ❓ |
| 9 | ❓ Which on-chain features Bunshik Hell uses first (DDEOK rewards, saves, item or clothing NFTs). | ❓ |

---

## 8. Art and audio pipeline

| # | Decision | Status |
|---|---|---|
| 1 | Blender → **`.glb` export** into `game/assets/`. No direct `.blend` import (needs Blender on every machine and build server). | ✅ |
| 2 | The 떡's squiggle uses **shape keys** (glTF morph targets) or bones. | 🟡 |
| 3 | **Grease Pencil does not export to Godot.** Standard glTF doesn't carry it; a Nov 2026 proof of concept (Blender 5.2.2 → Godot 4.7.2) moves only stroke curves. Use it for concepts, storyboards and pre-rendered cutscenes. | ✅ (fact) |
| 4 | Ignore Blender backup files (`*.blend1`, `*.blend2`) in the art repo. | ✅ |
| 5 | Music from **Suno Pro**, exported as `.ogg`. Masters in the art repo. | ✅ |
| 6 | Every third-party asset (fonts, sounds, Mixamo animations) gets its licence recorded. 🔍 Raw Mixamo files may not be allowed in a public repo. | ✅ / 🔍 |

---

## 9. Licences

| # | Decision | Status |
|---|---|---|
| 1 | **Code: AGPL-3.0.** The repo has no `LICENSE` file yet; the first DEV task adds it. | ✅ |
| 2 | **Assets: All Rights Reserved** for now, stated in the README. | ✅ |
| 3 | Planned: assets move to **CC BY-SA 4.0** once the game, or at least one episode, is complete. CC BY-SA lets others sell remixes with credit and the same licence. ⚖️ Review before switching, including the Suno music. | ✅ plan / ⚖️ |
| 4 | An NHMH-wide asset licence (shared with HHT and Noraebang Night) belongs in a STRATEGY session. | 🟡 |
| 5 | Godot (MIT) inside an AGPL-3.0 game: expected to be compatible. 🔍 | 🔍 |

---

## 10. Agents, git and tests

| # | Decision | Status |
|---|---|---|
| 1 | **`CLAUDE.md`** in the repo root: read the latest log first; follow the specs; never run `git add`, `git commit` or `git push`; never read wallet or key folders; no mainnet transactions; content as data. | ✅ |
| 2 | **`.gitignore`:** `.godot/`, `export_presets.cfg` (can hold Android signing passwords), build output, OS files. | ✅ |
| 3 | Git commands are given by DEV with **files named explicitly**. | ✅ |
| 4 | **Tests:** a headless test runner in `game/tests/`, the same pattern as the other NHMH games. Every system ships with tests. | 🟡 |
| 5 | Laptop shell is **fish**; the PC uses **PowerShell**. Commands are given in the right syntax for each. | ✅ |

---

## 11. Open

1. ❓ Godot version on the Windows PC.
2. ❓ Pushing from the PC (HTTPS, two GitHub accounts). Not needed until the PC is used for commits.
3. ❓ Art repo name; 🔍 GitHub LFS limits.
4. ❓ SDK milestone order (desktop vs web first) and Bunshik Hell's first on-chain features.
5. 🔍 Renderer and physics settings in `project.godot`.
6. 🔍 Per-platform renderer overrides, when web and Android come up.
7. ⚖️ Asset licence switch to CC BY-SA 4.0; AI music copyright.

## 12. Next

1. **Systems spec v0.1** (CHAT/DEV): movement, skills, controls, resources, health, damage rules, the reaction table.
2. Then the **first DEV task**: project setup (renderer, physics, folders, input map, autoloads, `LICENSE`, `CLAUDE.md`, `.gitignore`, test runner) and the **떡 gray-box test room**.
