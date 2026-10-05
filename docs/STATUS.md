# Current status

Updated: 2026-10-05

Start fresh sessions with [HANDOFF.md](HANDOFF.md). The prologue E-input test race is diagnosed and fixed. **Full regression: 23 passed / 1 failed** on October 5; all five chapters and sequential unlocks pass, but W+Q showed a 14.17-stud frame jump. The October 4 engine 25/25 and focused Asakusa 2/2 remain valid for the unchanged production build. GitHub and Studio access work.

## Current build: 0.6.0

Five chapters have staged story implementations: Kamado home/prologue, Sagiri training, Final Selection/homecoming, northwest town/Swamp Demon and **Lights of Asakusa**. Chapter five has fifteen stages, city streets and a noodle stall, Muzan and a civilian emergency, Tamayo/Yushiro, an enterable clinic/garden, Yahaba, a nonlethal Susamaru defense phase and departure. Dialogue, geography, encounter rules and acting are condensed original adaptations; see RESEARCH.md.

There are **44 bundled R15 clips** and two motion profiles. Tanjiro has six stance/walk/combo/guard overrides. Base clips cover locomotion, directional dashes, attacks and sword handling; the two new restraint clips support the civilian rescue. The checked Studio importer validates exports, backs up prior clips and preserves editor changes during generation. Manual editor round-trip and visual refinement remain pending.

Chapters **6-22 remain encounter previews**. The full objective remains all nine Hashira, protagonists, Muzan, Upper/Lower Moons, Infinity Castle (2025 minimum), story locations, PvP and progression. Catalog coverage is **83 cast records, 44 selectable fighters, 210 techniques, 19 location concepts and 22 chapter definitions**; these are data counts, not completed assets.

## Current validation

- `python scripts/check.py` passed on October 5: catalog validation, 44 clips, two profiles, **6 Python authoring tests**, **18 core tests**, **31 Luau compilations** and the production build.
- Actual Studio engine suite: **25 passed / 0 failed**, exit 0. Includes new map access, restraint/defense logic and sampled Tanjiro clips. Final twelve-rig animator benchmark: 2.502 ms per frame (0.209 ms per rig).
- Focused Asakusa two-client suite: **2/2**, exit 0, after fixing the encounter idle timer. All fifteen stages, both rescue clips, real Water attacks, nonlethal defense, one reward, saved kit restoration and cleanup passed.
- Full suite on October 5: **23 passed / 1 failed**, exit 1. E is accepted at scene age 0.765 s after the test waits for eligibility. All five story routes, exits, natural sequential unlocks, profiles, sword handling and PvP pass. W+Q failed: 14.17 studs in one 0.069 s frame, despite 16.6447 studs of server travel. Smoothness thresholds are unchanged; the full suite is not green. Failure isolation records fallback unlock seeds and cannot hide them from the sequential progression assertion.
- Focused dash diagnostic: **7/7**, exit 0, including three actual W+Q attempts. Largest jumps were 6.93 / 6.35 / 8.13 studs. Traces show client replication catch-up during server-owned movement; the earlier 14.17-stud failure was not reproduced. `--dash-only` now records synchronized ownership/position/frame evidence. Full regression remains unresolved.
- No new visual review or manual Animation Editor round-trip: the Windows computer-use helper could not connect its native pipe. Automated tests do not prove motion quality, human route traversal, difficulty or cinematic pacing.

## Next work

1. Use `python scripts/prepare_studio_test.py --dash-only` to investigate initial dash ownership/physics replication delay, then rerun full regression without weakening smoothness thresholds. The prologue race and dependent story-test failures are resolved. Finish qualification before new story implementation.
2. Review all five chapters and base/Tanjiro animation in Studio. Test the importer with an actual editor save/export. Refine observed sword paths, movement, acting, navigation and difficulty.
3. Continue chronologically with Tsuzumi Mansion, Zenitsu/Inosuke introductions and rotating-room encounters, using primary references. Expand Nezuko/Giyu profiles alongside story work.
4. Finish the later arcs, unique boss mechanics, character models, weapons, technique choreography, sound and exploration. Keep all existing cast/PvP/progression objectives.
5. Qualify physical touch/controller controls, small screens, low-FPS/lag dash behavior, performance, balance and live DataStores. Public-release settings and owner-dashboard checks remain open.

## Artifact and delivery

Local production place: `build/WisteriaChronicles.rbxlx`, **3,372,157 bytes**, SHA-256 `9cf06c489cdf5c512c9b1650be90522cb0aaa17ea4735587b8db8c92c0145b56`. Build output and Studio logs are ignored. The shipping place excludes test bridges/hooks.

Production source checkpoint [5ad7b51](https://github.com/aaaditt/demon-slayer-roblox/commit/5ad7b5106aa089f9ecae54f1899a2a0add106229) remains unchanged. Prologue/isolation test checkpoint [64a8c4c](https://github.com/aaaditt/demon-slayer-roblox/commit/64a8c4caa0064c2eef606ca7bd6646d59cf50af5) is committed and pushed; its [portable CI passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/37315915002). The following diagnostic checkpoint is recorded in WORKLOG.md. CI does not run Studio or clear the dash failure. Last release download remains [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), chapters 1-3; no new release was created.

The [private Roblox target](DEPLOYMENT.md) remains universe `10766590718`, place `139004028759819`, containing the earlier upload. No new cloud upload, public-access success or live-save validation is claimed. GitHub pushes do not update Roblox automatically.
