# Bunshik Hell — Episode 1 Master Roadmap

*Roadmap · 17 November 2026 · Frozen once saved*
*Repo path: `documentation/roadmaps/`*

> **Roadmaps are never modified.** This records the plan as of today. When work departs from it, the difference goes in the next project log.
> ✅ decided · 🟡 suggested · ❓ open · 🔍 verify · ⚖️ needs a professional

**Episode 1:** *Yummy! Bunshik for Lunch* (working title). Three maps (lunch 분식집 · school gate and 문방구 · school cafeteria), a map boss on each, one world final boss, an optional tutorial inside Map 1, and an ending where the woman stabs and swallows the 떡.

**Reads with:** the latest log, `bunshik-hell-episodes-and-maps-v0.1.md`, `bunshik-hell-dev-decisions-v0.1.md`, `bunshik-hell-systems-spec-v0.1.md`.

---

## Goals and context

| # | Item | Status |
|---|---|---|
| 1 | **No fixed deadlines.** Make as much progress as possible. | ✅ |
| 2 | Release a **demo and a "coming soon"** page first. | ✅ |
| 3 | Aim to release **Episode 1 of Bunshik Hell, Noraebang Night and Hangul Hiking Trip in the same month**, together with the DDEOK website (ddeok.org or ddeok.xyz ❓) with a staking pool, and a small NFT collection sold at in-game merchants for DDEOK. | ✅ goal |
| 4 | Then apply for funding and grants, aiming for full-time work on all three games. (STRATEGY) | ✅ goal |
| 5 | Merchandise on the website later, after getting the licence it needs. ⚖️ | ✅ goal |
| 6 | Bunshik Hell stays **off-chain until Episode 1 is completely finished**; on-chain comes in Phase 10. | ✅ |
| 7 | Downloads for **Windows and Linux** first, from NHMH's website. | ✅ |
| 8 | **Art starts early, piece by piece,** with the essentials first: the 떡, then the early enemies. | ✅ |
| 9 | Episode 1 has **at least one friend and one merchant.** A friend who doesn't teach a skill can greet the 떡 and say something that makes no sense yet but turns out to be a story clue. | ✅ |

---

## Working rules for every phase

- A **project log** for every working session (Global Rule 1).
- **Specs are written just ahead of building**, not all at once. Each map gets its spec at the start of its phase.
- **Gray-box first, art second.** A map gets art only after it passes its gray-box gate.
- **Tests ship with every system.** The `-- --physics` suite runs before any commit touching movement or combat.
- Claude Code never runs git. DEV gives git commands with files named.
- One step at a time.

---

## Phase 0 — Foundation and the 떡 prototype ✅ DONE

**Goal:** a working project and a 떡 that's fun to move.

**Done checklist**
- [x] Repo on GitHub; docs organized (`design/ roadmaps/ production/ logs/`)
- [x] Dev Decisions v0.1, Systems Spec v0.1, Episodes and Maps v0.1
- [x] Task 1a: project setup, autoloads, tests, AGPL-3.0 `LICENSE`, `CLAUDE.md`
- [x] Task 1b: gray-box test room (squiggle, jump, stomp, roll, slam, reaction table, dummies, 찜기)
- [x] Task 1c: playtest fixes, 103 tests
- [x] User playtest

**Gate:** Is the 떡 fun to move in a gray room? ✅ "It's already fun."

---

## Phase 1 — Episode 1 on paper (overview + Map 1)

**Goal:** enough design to build Map 1 and to start the art. Maps 2 and 3 get detailed specs in their own phases.

**Steps**
1. **Episode 1 enemy roster v0.1:** every enemy's material, moves, attacks, difficulty, how the 떡 beats it, and which map it appears in.
2. **Episode 1 boss sheet v0.1:** the Mutant 라볶이 in detail (phases, attacks, telegraphs, what food logic beats it). Concepts for the Map 2 and Map 3 bosses and the world final boss.
3. **Episode 1 characters v0.1:** the woman (role; identity may stay ❓), at least one **friend**, at least one **merchant**, and who appears in which map.
4. **Skill sources:** which boss reward or friend gives the roll, the sauce flick and the double jump.
5. **Inventory containers:** the small starter container (found early) and the better ones sold by merchants.
6. **Map 1 spec v0.1** (lunch 분식집): layout beats, the prologue and the woman's stab sequence, the tutorial, the roll unlock, enemy and pickup placement, the rare 찜기 spots, the 라볶이 arena, the exit to Map 2.
7. **Systems Spec v0.2:** picks up everything decided since v0.1 (logs 003 and later).

**Done checklist**
- [ ] Enemy roster v0.1 approved
- [ ] Boss sheet v0.1 approved (라볶이 detailed; the others at concept level)
- [ ] Characters v0.1 approved (≥ 1 friend, ≥ 1 merchant)
- [ ] Every Episode 1 skill has a source
- [ ] Starter container and merchant containers named
- [ ] Map 1 spec v0.1 approved
- [ ] Systems Spec v0.2 written
- [ ] All files in the repo and the Project

**Gate:** Could Claude Code build Map 1 from these documents without guessing?

---

## Phase 2 — Art foundation (runs alongside Phases 3 and 4)

**Goal:** a working Blender → Godot pipeline and the first real characters.

**Steps**
1. **Style brief v0.1** (FRONTEND): look and palette, shape language, lighting for Forward+, the cute → disturbing scale, how the face reads, the food realism rule.
2. **Private art repo** created, with Git LFS (🔍 check GitHub's LFS limits first) and a `.gitignore` for Blender backups.
3. **Pipeline test:** a throwaway model with shape keys exported to `.glb`, imported into Godot, its shape keys driven from code.
4. **The 떡, final model:** longer body, eyes and mouth at the head end, sauce drip, shape keys for the squiggle, jump stretch, landing squash and the posture set (curious lean, startled recoil, nervous idle).
5. **The 떡 in the game:** the model replaces the placeholder in the test room; the squiggle still feels as good.
6. **Early enemies** for Map 1, one at a time: 만두, 김밥 slices, 단무지, 라면, plus the metal chopsticks hazard.
7. Provenance recorded for every asset (tool, any model or checkpoint and its licence, human edits).

**Done checklist**
- [ ] Style brief v0.1 approved
- [ ] Art repo exists and is private
- [ ] Shape keys proven to work from Blender to Godot
- [ ] The 떡's final model is in the game, and the playtest says the squiggle still feels good
- [ ] Every Map 1 enemy has a model in the game
- [ ] Provenance written for every asset

**Gate:** Does it look like Bunshik Hell, and does the 떡 still feel as good to move?

---

## Phase 3 — Core systems

**Goal:** every system Episode 1 needs, working in the test room.

**Steps**
1. **Sauce:** the attack button, cycling types, refills from pools, dipping dishes and drips; the basic **flick** (no aiming).
2. **Health items and the heal button:** 참기름, 콩고물 (with its one-hit coat), 조청 or 꿀; lowest item first, default changeable in settings.
3. **Inventory:** containers (none at the start; the starter container; bigger ones later), dropping items, the "full" popup with *use it now* / *drop it*.
4. **나트륨** pickups and at least one **environment special** (e.g. knocking a heavy object onto an enemy).
5. **Double jump** (skill-locked).
6. **Skill unlocks** triggered by a boss defeat or by talking to a friend.
7. **Talking** (W / stick up): a simple dialogue box for friends and merchants. 🟡 English and Korean text.
8. **Merchant shop:** buy containers and items with **off-chain DDEOK**; DDEOK pickups.
9. **HUD:** hearts in halves, sauce, 나트륨, DDEOK, current sauce type.
10. **Pause, settings and rebinding**, including the instant-heal default; the DualSense **inventory moves to the touchpad**.
11. **Save and load:** at every 찜기, plus continue from the title.
12. Reaction table extended for every Episode 1 enemy material.

**Done checklist**
- [ ] Every step above works in the test room
- [ ] Tests for every system; the fast suite and the `--physics` suite pass
- [ ] User playtest of the new systems passes
- [ ] Saves load correctly after quitting and restarting

**Gate:** Can every Episode 1 mechanic be played in the test room?

---

## Phase 4 — Map 1: the lunch 분식집

**Goal:** a finished first map, built to be the demo.

**Steps**
1. **Gray-box Map 1** from the Map 1 spec: the prologue (the woman stabbing), the tutorial (optional; skipping still gives the roll), the dining room, the kitchen and the 떡볶이 pan, the street exit.
2. Map 1 enemies, pickups, the rare 찜기 spots, the starter container, any friend or merchant set in Map 1.
3. **The Mutant 라볶이** fight in gray.
4. **Gray-box playtest** and tuning.
5. **Art pass:** environment, props, the woman, the 라볶이; the early enemy models from Phase 2.
6. **Audio:** a Suno track for the map and one for the 라볶이 (MUSICIAN), plus core sound effects.

**Done checklist**
- [ ] Map 1 is playable from the prologue to the exit
- [ ] The tutorial works, and can be skipped (the roll is still granted)
- [ ] The 라볶이 is beatable, every attack is telegraphed, and beating it needs food logic
- [ ] Gray-box playtest passed before the art pass began
- [ ] Art and audio are in
- [ ] Tests and the physics suite pass

**Gate:** After dying to the 라볶이, does the player want to try again right away?

---

## Phase 5 — Demo and "coming soon"

**Goal:** strangers play Map 1.

**Steps**
1. **Demo build:** Map 1 only, ending with a "to be continued" card.
2. Windows and Linux exports, tested on a clean machine of each.
3. A **"coming soon"** page on NHMH's website with the demo downloads.
4. Outside playtesters; a simple way to send feedback.
5. A feedback review: find the repeated problems and fix the core before continuing.

**Done checklist**
- [ ] Demo builds run on a clean Windows and a clean Linux machine
- [ ] Coming-soon page and downloads are live
- [ ] At least a few outside players have played it
- [ ] The feedback is summarized in a log, and the repeated problems are fixed or planned

**Gate:** Do people who have never heard of the game finish the demo and ask for more?

---

## Phase 6 — Map 2: school gate and 문방구

**Steps**
1. **Map 2 spec v0.1.**
2. Gray-box: the street and the 문방구; enemies (뻔데기, 떡꼬치, 쫀드기, tube candy, spilled 슬러시).
3. The **sauce flick** unlock (boss reward or friend).
4. **Map 2 boss**, in gray.
5. Gray-box playtest → art pass → audio.

**Done checklist**
- [ ] Map 2 spec approved
- [ ] Playable from the Map 1 exit to the Map 2 exit
- [ ] Sauce flick unlocked here and taught by the level
- [ ] Boss beatable and telegraphed
- [ ] Gray-box playtest passed before art; art and audio in
- [ ] Tests pass

**Gate:** Does Map 2 add something new, and is it fun?

---

## Phase 7 — Map 3: the school cafeteria

**Steps**
1. **Map 3 spec v0.1.**
2. Gray-box: the 급식실; enemies (흰 우유 cartons, 깍두기, 나물 반찬, 요구르트); the serving ladle and the 잔반통 pit.
3. The **double jump** unlock.
4. **Map 3 boss**, in gray.
5. Gray-box playtest → art pass → audio.

**Done checklist**
- [ ] Map 3 spec approved
- [ ] Playable from the Map 2 exit to the final boss
- [ ] Double jump unlocked and needed
- [ ] Boss beatable and telegraphed
- [ ] Gray-box playtest passed before art; art and audio in
- [ ] Tests pass

**Gate:** Does Map 3 make the player use everything learned so far?

---

## Phase 8 — The world final boss and the ending

**Steps**
1. **Final boss spec:** gigantic, absurd, difficult, original; grown out of food culture but unrecognizable.
2. The fight in gray → playtest → art → its own Suno track.
3. **The ending:** after the boss, the pick stabs the 떡 and the woman swallows him. Cliffhanger card for Episode 2.
4. Credits.

**Done checklist**
- [ ] Final boss spec approved
- [ ] The boss is beatable, every attack telegraphed, and it uses what all three maps taught
- [ ] The ending plays and leads into the credits
- [ ] Art and audio in

**Gate:** Does the ending make players want Episode 2?

---

## Phase 9 — Polish and release of Episode 1 (off-chain)

**Steps**
1. Title screen, main menu, continue, credits.
2. Settings complete: rebinding (keyboard and DualSense), audio, display, instant-heal default; the on-chain option shown but off.
3. Difficulty and pacing pass across all three maps.
4. Performance pass on modest Windows and Linux PCs.
5. Bug pass: crashes and progress blockers first.
6. A final mix of music and sound.
7. Windows and Linux release builds; the download page on NHMH's site.
8. Release notes, a known-issues list, and the content warnings (they inform; they don't apologize).
9. ⚖️ Review before release: the README copyright holder, the asset licence, the Suno music, satirical names.

**Done checklist**
- [ ] The full episode is playable start to finish with no blockers
- [ ] Builds tested on clean Windows and Linux machines
- [ ] Download page live
- [ ] Every ⚖️ item reviewed
- [ ] Release log written

**Gate:** Is Episode 1 finished, by the standard that it's good enough for strangers to pay or donate for?

---

## Phase 10 — On-chain (after Episode 1 is complete)

**Goal:** "play on-chain" works. Coordinated with the NHMH launch month: the DDEOK website, the staking pool and the NFT collection.

**Steps**
1. Check the NHMH Godot–Sui SDK (`sdk-master-roadmap.md`) is ready for **Windows and Linux desktop**.
2. Plug the SDK into `ChainBridge`; the game code doesn't change.
3. Wallet connect (players use their own wallet; the game never holds keys).
4. DDEOK rewards and merchant purchases on **testnet**, then **mainnet**.
5. The NFT collection's items sold at in-game merchants.
6. Save and item IDs map onto on-chain objects as designed (Dev Decisions §7).
7. A security review before mainnet.

**Done checklist**
- [ ] On-chain play works on testnet end to end
- [ ] Off-chain play is unchanged
- [ ] Security review done
- [ ] Mainnet enabled, in step with the DDEOK website and NFT launch

**Gate:** Can a player switch on-chain, connect a wallet, earn DDEOK and buy an item, with off-chain play still working for everyone else?

---

## Open items at the time of writing

1. ❓ The woman's identity.
2. ❓ The Map 2, Map 3 and world final bosses.
3. ❓ The friend and merchant characters.
4. ❓ Inventory container types.
5. ❓ 감칠맛.
6. ❓ Whether Episode 1 ships with on-chain on at release, or gets it in an update after.
7. ❓ The DDEOK website domain (ddeok.org or ddeok.xyz).
8. ❓ SDK milestone order (desktop vs web first).
9. ⚖️ Copyright holder, asset licence, AI music, satirical names, merchandise licence.
