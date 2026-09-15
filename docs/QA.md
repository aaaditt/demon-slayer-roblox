# Validation evidence

## 2026-09-15 local validation

### Portable checks

`python scripts/check.py` passed catalog referential integrity, nine-Hashira coverage, character-specific move restrictions, balance bounds, generation, Luau compilation (17 source/test files at this checkpoint), all eight core tests, and the Rojo place build.

Core coverage: malformed/NaN/infinite input, atomic cooldown/resource admission, token-bucket limits, hub safety and private mission isolation, hit geometry, guard/parry/dodge, corrupted profiles, and exclusive save-lease transitions. An initial lease-release test failed and was fixed; the regression test remains.

### Roblox engine smoke test

Executed `tests/studio.spec.luau` in Roblox Studio through run-in-roblox. **7 passed / 0 failed**:

- All 44 playable character rigs have expected R6 joints and humanoids.
- All 19 location themes build valid bounded rooms.
- An in-range enemy receives damage and a cooldown replay is rejected.
- Hub players and other private instances reject damage.
- Walls block line-of-sight attacks and server-driven dashes.
- Guard, poison application, and healing execute in the engine.
- All 12 shared move patterns execute.

These tests construct engine objects in the runner's Studio environment. They do not by themselves prove player movement, client UI, or multiplayer behavior.

### Real two-client Studio integration

Executed `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)` with injected test-only client and server scripts. **8 passed / 0 failed**:

1. Both clients loaded the GUI, attached cameras to their characters, and stood at valid ground height.
2. The custom rig moved more than five studs under client movement input.
3. Real remote requests selected Giyu, changed a loadout, and rejected a foreign move.
4. Completing a chapter advanced progression, awarded XP, and removed its mission enemy.
5. A forged request to start a locked chapter was rejected.
6. Two opt-in players started a round and a real client basic-attack request damaged the opponent.
7. Elimination scoring, respawn and a five-point round win updated correctly.
8. Client UI remained present after mission/arena respawns.

Test limits: the reward test sets the NPC's health to zero to exercise progression plumbing. The scoring test accelerates eliminations and the score threshold. These checks do not establish combat difficulty, long-session fairness, physical input ergonomics, visual polish, or live DataStore persistence.

The first multiplayer attempt exposed a **test-runner** issue: run-in-roblox's plugin also loaded in server/client DataModels and launched the edit-only test API again. The isolated wrapper now holds child copies idle. The corrected suite completed successfully. No production test hooks or test remotes ship in the place.

## Remaining release checks

- Human playthrough of every chapter and loadout; difficulty/balance tuning.
- Visual inspection at desktop, phone portrait/landscape, and tablet resolutions.
- Physical controller and touch interaction; focus navigation and screen safe-area layout.
- Real published DataStore save/load, disconnect, throttle, lease conflict, crash recovery, and shutdown tests.
- Adversarial remote/movement tests; lag and packet-loss behavior; maximum-room/player performance.
- Per-move visual/choreography verification against lawful primary scene references.
- Long-running arena join/leave, timeout/tie, disconnect and late-join tests.
- Public Roblox publishing and cross-computer play.
