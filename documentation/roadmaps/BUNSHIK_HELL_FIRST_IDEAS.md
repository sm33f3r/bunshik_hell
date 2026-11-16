# BUNSHIK HELL — Game Development Plan

## 1. Project Overview

**Title:** Bunshik Hell
**Genre:** 2D action-platformer / boss-rush / light bullet-hell
**Primary inspiration:** Super Mario, Cuphead
**Setting:** Korean 분식 (bunsik / Korean street food) culture
**Initial target:** Linux desktop
**Secondary target:** Android
**Potential release platforms:** itch.io first, then Steam and Google Play
**Engine:** Godot 4.x
**Language:** GDScript
**Art direction:** Original hand-drawn cartoon art inspired by the exaggerated animation, squash-and-stretch, expressive characters, and theatrical presentation of classic animation and Cuphead — without copying Cuphead's characters, assets, or exact visual identity.

### Core premise

A single little **tteokbokki** must survive the bizarre and increasingly hostile world of Korean street food.

The world is populated by cute, grotesque, ridiculous, and dangerous food creatures. What begins as a colorful 분식집 adventure gradually descends into **Bunshik Hell**.

The game should feel:

- Funny
- Fast
- Weird
- Charming
- Visually expressive
- Difficult but learnable
- Strongly Korean in its subject matter
- Accessible enough to pick up immediately

---

# 2. Development Philosophy

The most important rule:

> **Do not try to make Cuphead. Make a small, excellent Bunshik Hell.**

Cuphead's visual quality comes from an enormous amount of illustration and animation work. A solo developer should avoid committing to that production scale at the beginning.

Instead:

1. Build a tiny playable prototype.
2. Establish the game's identity.
3. Create one polished vertical slice.
4. Release a small demo.
5. Get real player feedback.
6. Expand only if the game is genuinely fun.

The first goal is **not Steam 1.0**.

The first goal is:

> **Bunshik Hell 0.1 — one excellent level and one excellent boss.**

---

# 3. Recommended Technology

## Engine

### Godot 4.x

Godot is the preferred engine because it:

- Is free and open source.
- Supports 2D very well.
- Supports Linux development.
- Supports Android export.
- Uses GDScript, which is approachable for a Python learner.
- Has no royalty requirement.
- Allows the same basic game project to target multiple platforms.

## Development platform

Primary:

- Linux
- CachyOS / Arch Linux or another comfortable Linux environment

Secondary:

- Android testing device

## Version control

Use Git from the beginning.

Suggested repository:

```text
bunshik-hell/
├── project.godot
├── README.md
├── LICENSE
├── assets/
├── audio/
├── characters/
├── enemies/
├── bosses/
├── levels/
├── scripts/
├── ui/
├── shaders/
├── documentation/
└── tests/
```

A GitHub repository can eventually contain:

- Source code
- Documentation
- Issue tracking
- Development roadmap
- Art pipeline documentation
- Release notes

---

# 4. Target Platforms

## Phase 1 — Development

Linux desktop.

## Phase 2 — Open/public demo

itch.io or another open indie-game distribution platform.

Potential formats:

- Linux build
- Windows build if practical
- Web build if technically practical

## Phase 3 — Commercial release

### Steam

Potential final PC release.

Steam is attractive because of:

- Large PC audience
- Linux support
- Controller support
- Achievements
- Community features
- Wishlist system
- Commercial indie-game ecosystem

Steam Direct currently requires a USD $100 fee per app/game, which becomes recoupable after the game reaches the applicable revenue threshold.

## Phase 4 — Android

Google Play.

Android should be treated as a second platform, not a completely separate game.

The game should therefore be designed from the beginning with:

- Controller support
- Touch controls
- Scalable UI
- Different screen aspect ratios
- Variable resolutions
- Performance constraints

---

# 5. Initial MVP

The first playable version should be extremely small.

## Bunshik Hell 0.1

### Player

One character:

**Tteokbokki**

### Level

One complete level.

### Enemies

Five initial enemy types:

1. Sundae monster
2. Liver-slice monster
3. Dumpling
4. Ramyeon monster
5. 튀김 monster

### Obstacles

At least:

- 꼬치
- Hot surfaces
- Kitchen hazards
- Moving food obstacles

### Boss

One:

# 붕어빵

### Gameplay

The player must be able to:

- Move
- Jump
- Attack
- Take damage
- Die
- Restart
- Defeat enemies
- Reach the end of the level
- Fight the boss
- Win

### Target playtime

Approximately:

**5–10 minutes**

The MVP should be playable from:

```text
Title Screen
      ↓
Level
      ↓
Enemies
      ↓
Boss
      ↓
Victory
      ↓
Credits / Restart
```

---

# 6. Core Gameplay

The exact mechanics should be refined during prototyping.

Possible core movement:

- Run
- Jump
- Short jump / variable jump
- Dash or dodge
- Attack
- Crouch
- Possibly wall interaction later

Possible attack:

The tteokbokki could launch:

- Sauce projectiles
- Tiny rice-cake projectiles
- Spicy sauce bursts
- Temporary power-ups

The attack should feel silly and satisfying rather than realistic.

---

# 7. Difficulty Philosophy

Bunshik Hell should be challenging, but the player should understand why they died.

Inspired by the best parts of platformers and boss games:

- Fast restarts
- Short levels
- Predictable attack patterns
- Strong visual warnings
- Learnable bosses
- Minimal downtime
- Immediate retry

Avoid:

- Cheap damage
- Invisible attacks
- Excessive loading
- Long animations after death
- Large amounts of progress lost after failure

A failed attempt should make the player think:

> "Okay, I know what I need to do next time."

---

# 8. Art Direction

## Overall style

The visual identity should combine:

- Hand-drawn cartoon illustration
- Exaggerated facial expressions
- Squash and stretch
- Dramatic poses
- Strong silhouettes
- Large readable animations
- Comedic timing
- Korean street-food imagery

The game can be inspired by Cuphead's *principles* without copying its specific characters, designs, animation frames, or visual assets.

## Character design

Characters should be:

- Immediately recognizable
- Simple enough to animate
- Expressive
- Funny when idle
- Funny when attacking
- Funny when dying

## Food behavior

Food should behave like food.

Examples:

### Tteokbokki

- Squishes when landing
- Stretches when jumping
- Wobbles while standing
- Sauce splashes during attacks

### Sundae

- Wobbles
- Bounces
- Flops
- Can split into pieces

### Ramyeon

- Noodles act like tentacles
- Noodles whip around
- Noodle attacks create readable patterns

### Dumplings

Cute and harmless-looking at first.

Then:

- Grow angry faces
- Roll toward the player
- Bounce
- Stack themselves
- Potentially attack in groups

### 튀김

Crispy, chaotic, and explosive.

---

# 9. Character Roster

## Player

### Tteokbokki

The protagonist.

Personality possibilities:

- Tiny
- Determined
- Permanently angry
- Adorably frustrated
- Extremely brave despite being tiny

Possible visual features:

- One or two rice cakes as the body
- Sauce
- Big expressive eyes
- Tiny arms and legs

---

# 10. Enemy Roster

## Sundae Monsters

Slow or medium-speed enemies.

Possible attacks:

- Charge
- Bounce
- Roll
- Launch small pieces

## Liver-Slice Monsters

Fast, disgusting, funny enemies.

Possible behavior:

- Leap
- Slide
- Hide
- Attack from below

## Dumplings

Initially cute.

Possible attacks:

- Roll
- Bounce
- Group charge
- Stack attack

## Ramyeon Monsters

Long noodle bodies.

Possible attacks:

- Noodle whip
- Projectile noodles
- Grab attacks
- Temporary barriers

## 튀김 Monsters

Crispy enemies.

Possible attacks:

- Roll
- Explode
- Drop crumbs
- Dive attack

## 어묵 Villains

More organized enemies.

They could function as:

- Soldiers
- Guards
- Spear users
- Ranged attackers
- Mini-bosses

---

# 11. Obstacles

## 꼬치

Skewers can appear as:

- Stationary spikes
- Moving hazards
- Falling hazards
- Rotating obstacles

## Cooking Equipment

Potential hazards:

- Fryers
- Boiling pots
- Steam
- Hot grills
- Ladles
- Chopsticks
- Knives
- Kitchen machinery

The hazards should remain cartoonish and readable.

---

# 12. Boss Roster

The game can eventually build toward a large roster of food bosses.

## Boss 1 — 붕어빵

First major boss.

Possible phases:

### Phase 1

The 붕어빵 moves around the arena.

### Phase 2

It launches red-bean projectiles.

### Phase 3

It changes shape or splits.

### Phase 4

The arena itself becomes dangerous.

The first boss should teach the player how Bunshik Hell bosses work.

---

# 13. Potential Future Bosses

## The Fryer

A giant fryer.

Attacks:

- Oil waves
- Flying 튀김
- Explosions
- Rising temperature

## Sundae Queen

A giant, theatrical sundae character.

Attacks:

- Rolling attacks
- Minions
- Splitting attacks
- Projectile food

## Ramyeon Monster

A giant bowl of ramyeon.

Its noodles behave like tentacles.

## 어묵 King

A giant fishcake ruler.

Could command smaller 어묵 soldiers.

## Final Boss — The 분식집 Owner

The person responsible for the entire world.

Potential attacks:

- Ladle
- Chopsticks
- Frying pan
- Sauce
- Ingredients
- Entire kitchen appliances

The final battle could combine mechanics from every previous world.

---

# 14. World Structure

A possible campaign:

## WORLD 1 — 분식집

The introductory world.

Enemies:

- Dumplings
- Sundae
- 튀김
- 어묵

Boss:

**붕어빵**

---

## WORLD 2 — 포장마차

Nighttime Korean street-food environment.

Visual ideas:

- Rain
- Neon
- Plastic tent
- Tables
- Steam
- Street traffic in background

Enemies:

- Ramyeon
- Fishcake
- Skewers
- Boiling-pot creatures

Boss:

**Ramyeon Monster**

---

## WORLD 3 — FRYER HELL

A chaotic industrial kitchen.

Visual ideas:

- Fire
- Oil
- Smoke
- Conveyor belts
- Giant fryers

Enemies:

- Shrimp 튀김
- 김말이
- Sweet potato fritters
- Exploding fried food

Boss:

**The Fryer**

---

## WORLD 4 — SUNDAE KINGDOM

A strange, darker food kingdom.

Visual style:

- Gothic-comedy atmosphere
- Giant food structures
- Strange shadows
- Dramatic music

Boss:

**Sundae Queen**

---

## FINAL WORLD — 분식지옥

Everything comes together.

Enemies from previous worlds return.

Obstacles become increasingly absurd.

Final boss:

**The 분식집 Owner**

---

# 15. Level Design

Each level should have a clear purpose.

Possible structure:

```text
Introduction
    ↓
Basic enemy
    ↓
New mechanic
    ↓
Combination of mechanics
    ↓
Difficulty spike
    ↓
Checkpoint
    ↓
Boss
```

Avoid making levels excessively long.

Short, replayable stages fit the concept better.

---

# 16. Boss Design Philosophy

Bosses should be the game's main attraction.

Every boss should have:

1. Strong visual identity
2. Distinct music
3. Distinct attack patterns
4. Multiple phases
5. Clear telegraphs
6. Comedic animations
7. A memorable defeat animation

A boss should feel like a character rather than a large health bar.

---

# 17. Animation Strategy

Do not attempt full Cuphead-level animation immediately.

Start with:

- Idle
- Walk/run
- Jump
- Attack
- Hurt
- Death
- Victory

For bosses:

- Intro
- Idle
- Attack 1
- Attack 2
- Attack 3
- Damage
- Phase transition
- Death

Use reusable animation techniques where possible.

Potential tools:

- Godot AnimationPlayer
- Sprite sheets
- Bone/rig animation where appropriate
- Hand-drawn frames
- Vector assets where appropriate
- Blender/Synfig if useful for particular assets

The visual style should remain consistent even if different technical animation methods are used.

---

# 18. Audio

Audio should be treated as part of the game's identity.

## Music

Possible influences:

- Big-band cartoon energy
- Korean street atmosphere
- Traditional Korean instruments used creatively
- Arcade/game music
- Comedic percussion

Do not imitate copyrighted songs.

## Sound effects

Potential sounds:

- Sauce splat
- Rice cake bounce
- Fryer explosion
- Noodle whip
- Dumpling bounce
- Fishcake slap
- Skewer clank
- Cartoon impact

Sound effects can make relatively simple animation feel much more alive.

---

# 19. UI

Keep the UI simple and readable.

Possible screens:

- Title
- Start Game
- Options
- Controls
- Level Select
- Pause
- Boss health
- Game Over
- Victory
- Credits

Potential title screen:

```text
        BUNSHIK
         HELL

       🌶️

     PRESS START
```

The title treatment should eventually become one of the game's strongest pieces of visual branding.

---

# 20. Controls

## Keyboard

Possible default:

```text
A / D       Move
Space       Jump
J           Attack
K           Dash / special
Esc         Pause
```

Exact controls should be tested rather than assumed.

## Controller

Support:

- D-pad / left stick
- Jump
- Attack
- Dash
- Pause

Controller support should be implemented early enough that it does not become an end-stage problem.

## Android

Touch controls:

- Virtual movement controls
- Jump
- Attack
- Dash

Touch UI should be optional if a controller is connected.

---

# 21. Android Design Requirements

If Android remains a target, plan for:

- Multiple screen sizes
- Portrait/landscape decision
- Touch controls
- Safe areas
- Performance
- Battery consumption
- Pause/resume behavior
- Different aspect ratios
- Android back button behavior
- Save data

The game should preferably use scalable UI rather than fixed pixel coordinates.

---

# 22. Development Roadmap

# PHASE 0 — Brainstorming and Game Design

**Estimated time: 1–2 weeks**

Deliverables:

- Game concept
- Core gameplay loop
- Player concept
- Enemy list
- Boss list
- World list
- Art direction
- Control scheme
- Technical plan
- MVP definition

No major production work yet.

---

# PHASE 1 — Godot Learning + Prototype

**Estimated time: 2–4 weeks**

Learn enough Godot to build:

- Project
- Scene system
- CharacterBody2D
- Physics
- Collision
- Input
- Animation
- Camera
- Enemies
- Health
- Game states

Graphics can initially be:

- Squares
- Circles
- Temporary sprites

Goal:

**Prove that the game is fun.**

---

# PHASE 2 — Tteokbokki Prototype

**Estimated time: 2–4 weeks**

Create the first real protagonist.

Deliver:

- Character design
- Idle animation
- Walk animation
- Jump animation
- Attack animation
- Hurt animation
- Death animation

Implement:

- Movement
- Jumping
- Attack
- Damage
- Death
- Restart

---

# PHASE 3 — Enemy Prototype

**Estimated time: 2–4 weeks**

Implement the first five enemy types:

1. Sundae
2. Liver slice
3. Dumpling
4. Ramyeon
5. 튀김

Each should have a distinct behavior.

---

# PHASE 4 — First Level

**Estimated time: 2–4 weeks**

Create the first complete level.

Include:

- Background
- Platforms
- Obstacles
- Enemy placement
- Checkpoint/restart system
- Ending
- Music
- Sound effects

---

# PHASE 5 — 붕어빵 Boss

**Estimated time: 2–4 weeks**

Create:

- Boss art
- Intro animation
- Boss arena
- Health system
- Multiple attacks
- Phase changes
- Damage animations
- Death animation
- Boss music

This is the most important milestone.

---

# PHASE 6 — Vertical Slice

**Estimated time: 1–2 months**

Combine everything.

Target:

> 5–10 minutes of polished gameplay.

Structure:

```text
Title
 ↓
Level
 ↓
Enemies
 ↓
Obstacles
 ↓
Checkpoint
 ↓
붕어빵
 ↓
Victory
 ↓
Credits
```

This becomes:

# BUNSHIK HELL 0.1

---

# PHASE 7 — Public Demo

**Estimated time: 1–2 weeks**

Prepare:

- Linux build
- Optional Windows build
- Optional Web build
- Game page
- Screenshots
- Trailer
- Description
- Controls
- Known issues
- Feedback system

Release first through an open indie platform such as itch.io.

The objective is not revenue.

The objective is:

> **Get strangers to play it.**

---

# PHASE 8 — Feedback

**Estimated time: 2–4 weeks**

Collect feedback about:

- Controls
- Difficulty
- Art
- Music
- Boss
- Humor
- Game length
- Performance
- Bugs

Do not immediately add every requested feature.

Look for repeated problems.

---

# PHASE 9 — Full Game Production

**Estimated time: roughly 6–12+ additional months**

If the vertical slice proves successful, expand to:

- 4–5 worlds
- 15–30 levels
- 8–12 bosses
- More enemies
- More mechanics
- More music
- More animation
- Save system
- Achievements
- Difficulty modes
- Secrets
- Controller support
- Android support

A polished solo-developed game at this scale could realistically take:

**9–18 months total**, depending heavily on art and animation workload.

---

# PHASE 10 — Steam Release

Prepare:

- Steam store page
- Capsule artwork
- Screenshots
- Trailer
- Description
- Controller support
- Linux build
- Windows build
- Achievements
- Cloud saves if appropriate
- Steam testing
- Pricing
- Demo

Do not wait until the game is completely finished to think about marketing.

A Steam page can eventually become part of the development process.

---

# PHASE 11 — Android Release

Prepare:

- Android build
- Touch controls
- Mobile UI
- Performance optimization
- Different resolutions
- Android-specific testing
- Google Play listing
- Screenshots
- App icon
- Privacy/data documentation as applicable

---

# 23. Estimated Timeline

## Extremely small prototype

**2–4 weeks**

Playable but ugly.

## Small public demo

**3–6 months**

One polished level + boss.

## Small complete indie game

**9–18 months**

Multiple worlds and bosses.

## Large Cuphead-inspired production

**2–5+ years**

This should NOT be the initial commitment.

---

# 24. Recommended First-Year Goal

The most sensible first-year target is:

# BUNSHIK HELL 1.0

A compact game containing:

- 3–4 worlds
- 10–15 levels
- 5–8 bosses
- 8–12 enemy types
- Strong original art
- Original music/sound
- Linux support
- Windows support if practical
- Android support if practical
- Controller support
- itch.io release
- Steam release
- Potential Google Play release

But this goal should only be adopted after the 0.1 vertical slice works.

---

# 25. Scope Control

Features that should **NOT** be part of the initial MVP:

- Multiplayer
- Online multiplayer
- Procedural generation
- Complex inventory
- Open world
- RPG systems
- Crafting
- Character creation
- Huge dialogue system
- Voice acting
- Complex cutscenes
- Multiple playable characters
- Online leaderboards

These can be considered later.

---

# 26. Potential Expansion

If Bunshik Hell becomes successful, possible future additions include:

## Playable characters

- Tteokbokki
- Dumpling
- Sundae
- Ramyeon

Each could have different abilities.

## Challenge mode

Boss rush.

## Time attack

Speedrun mode.

## Endless mode

Survive increasingly difficult food enemies.

## Co-op

Two food characters.

This should be considered only after the single-player game is solid.

---

# 27. Branding

The title should remain:

# BUNSHIK HELL

Potential subtitle:

> **Welcome to 분식지옥.**

Possible marketing language:

> Korean street food has never been this dangerous.

> One little tteokbokki. An entire food hell.

> Eat or be eaten.

> Welcome to Bunshik Hell.

The game should use Korean food terminology naturally while remaining understandable to international players.

---

# 28. Cultural Direction

Korean food should not merely be used as random decoration.

Research and incorporate:

- 분식집 interiors
- 포장마차
- Korean street-food presentation
- Food preparation
- Korean signage
- Serving utensils
- Restaurant equipment
- Food textures
- Korean night streets
- Packaging
- Table settings

The goal is for someone familiar with Korean food culture to recognize the world immediately.

At the same time, international players should understand the visual comedy without needing extensive cultural knowledge.

---

# 29. Art Asset Pipeline

For each character:

```text
Concept
 ↓
Silhouette
 ↓
Character sheet
 ↓
Color/texture design
 ↓
Animation test
 ↓
Game sprite
 ↓
Effects
 ↓
Final integration
```

For each boss:

```text
Concept
 ↓
Attack sketches
 ↓
Arena concept
 ↓
Animation tests
 ↓
Gameplay prototype
 ↓
Final art
 ↓
Effects
 ↓
Sound
 ↓
Music
 ↓
Polish
```

Gameplay should be tested with placeholder art before spending large amounts of time animating.

---

# 30. Technical Architecture

Potential Godot structure:

```text
Game
├── Main
├── Player
├── Enemies
├── Bosses
├── Levels
├── UI
├── Audio
├── Effects
└── Systems
```

Systems may include:

- Player controller
- Enemy controller
- Damage system
- Health system
- Projectile system
- Checkpoint system
- Save system
- Level manager
- Boss manager
- Audio manager
- Input manager
- Settings manager

Keep systems modular so new food enemies can be added without rewriting the whole game.

---

# 31. Version Milestones

Suggested versions:

### 0.01

Movement prototype.

### 0.02

Jumping and collision.

### 0.03

Attack system.

### 0.04

First enemy.

### 0.05

First level prototype.

### 0.06

Tteokbokki art.

### 0.07

Five enemies.

### 0.08

Boss prototype.

### 0.09

First complete vertical slice.

### 0.1

Public demo.

### 0.5

Expanded beta.

### 1.0

Full release.

---

# 32. Definition of Success

Bunshik Hell does NOT need to be huge to succeed.

The first major success criterion is:

> Someone who has never heard of the project plays the first level and immediately wants to fight the 붕어빵 boss again.

If that happens, the project has something.

---

# 33. First Tasks

Before writing serious game code:

## Task 1

Write the one-paragraph game pitch.

## Task 2

Finalize the Tteokbokki concept.

## Task 3

Sketch:

- Tteokbokki
- Sundae
- Dumpling
- Ramyeon
- 튀김
- 어묵
- 꼬치
- 붕어빵

## Task 4

Define the player's basic controls.

## Task 5

Define the basic attack.

## Task 6

Design the first level.

## Task 7

Design the 붕어빵 boss.

## Task 8

Install Godot.

## Task 9

Create the Git repository.

## Task 10

Build the ugly prototype.

---

# 34. The First Playable Prototype

The first prototype should look terrible.

That is intentional.

Example:

```text
       [TTEOK]

         ↓

  [DUMPLING]       [SUNDAE]

==========================
       PLATFORM

               [BOSS]
```

If this is fun to play with rectangles, circles, and placeholder sprites, the project is working.

Only then should serious artwork begin.

---

# 35. Long-Term Vision

Bunshik Hell can eventually become a distinctive Korean indie-game world rather than simply a Cuphead-like clone.

The long-term identity should be:

> **A ridiculous hand-drawn action game built around Korean street food.**

Cuphead provides inspiration for:

- Animation ambition
- Boss-centric gameplay
- Cartoon theatricality
- Strong visual personality

Super Mario provides inspiration for:

- Accessible movement
- Platforming
- Level progression
- Immediate playability

But Bunshik Hell should ultimately have its own:

- Characters
- Mechanics
- Humor
- World
- Music
- Visual language
- Korean cultural identity

---

# 36. Recommended Overall Strategy

```text
BRAINSTORM
    ↓
GAME DESIGN BIBLE
    ↓
GODOT PROTOTYPE
    ↓
TTEOKBOKKI
    ↓
ONE ENEMY
    ↓
ONE LEVEL
    ↓
붕어빵 BOSS
    ↓
VERTICAL SLICE
    ↓
ITCH.IO DEMO
    ↓
PLAYER FEEDBACK
    ↓
DECISION:
"IS THIS ACTUALLY FUN?"
    ↓
YES
    ↓
FULL GAME
    ↓
STEAM
    ↓
ANDROID / GOOGLE PLAY
```

The key principle is:

# Make the smallest version that proves Bunshik Hell is fun.

Then make it bigger.
