# CLAUDE.md — rules for agents in this repo

Project: Bunshik Hell, a 3D side-view (2.5D) platformer. Godot 4.7.x, GDScript. Godot project root is `game/`.

## Before you start
- Read the latest log in `documentation/logs/` first.
- Follow the production docs in `documentation/production/`. Newer documents win over older ones.
- Do not edit anything in `documentation/` unless the task says to.

## Hard rules
- Never run `git add`, `git commit` or `git push`. The human does that.
- Never read or write `~/.ssh`, `~/.sui`, or any wallet or key files.
- No mainnet transactions. All chain access goes through `ChainBridge`, which is an off-chain stub for now.
- Never load `.tres` or `.res` files from outside the game (`user://`, downloads, saves, player-made content). Outside data is JSON only.

## Conventions
- Our own content is data: `.tres` custom Resources (enemy definitions, items, skills, reaction table). Saves and anything from outside are JSON.
- Static typing everywhere in GDScript.
- Tests ship with every system. Run:
  `godot --headless --path game -s res://tests/test_runner.gd`
  Tests instantiate fresh script instances; they must not rely on autoload state.
- Autoloads live in `game/systems/`: `GameState`, `SaveSystem`, `Settings`, `ChainBridge`.
- Keep changes minimal and in scope. No addons or plugins without being asked.
