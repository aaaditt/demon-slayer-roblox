# Current status

Updated: 2026-10-04

Start fresh sessions with [HANDOFF.md](HANDOFF.md). The Tanjiro animation/import and Asakusa checkpoint is saved for continuation. Engine tests pass (25/25), and focused Asakusa two-client tests pass (2/2). **Full regression failed: 14/23**, starting with a prologue E-dialogue input failure and dependent locked-chapter failures. GitHub and Studio access now work. Historical September permission failures are recorded in WORKLOG.md.

## Current build: 0.6.0

Five chapters have staged story implementations: Kamado home/prologue, Sagiri training, Final Selection/homecoming, northwest town/Swamp Demon and **Lights of Asakusa**. Chapter five has fifteen stages, city streets and a noodle stall, Muzan and a civilian emergency, Tamayo/Yushiro, an enterable clinic/garden, Yahaba, a nonlethal Susamaru defense phase and departure. Dialogue, geography, encounter rules and acting are condensed original adaptations; see RESEARCH.md.

There are **44 bundled R15 clips** and two motion profiles. Tanjiro has six stance/walk/combo/guard overrides. Base clips cover locomotion, directional dashes, attacks and sword handling; the two new restraint clips support the civilian rescue. The checked Studio importer validates exports, backs up prior clips and preserves editor changes during generation. Manual editor round-trip and visual refinement remain pending.

Chapters **6-22 remain encounter previews**. The full objective remains all nine Hashira, protagonists, Muzan, Upper/Lower Moons, Infinity Castle (2025 minimum), story locations, PvP and progression. Catalog coverage is **83 cast records, 44 selectable fighters, 210 techniques, 19 location concepts and 22 chapter definitions**; these are data counts, not completed assets.

## Current validation

- `python scripts/check.py` passed on October 4: catalog validation, 44 clips, two profiles, **6 Python authoring tests**, **18 core tests**, **31 Luau compilations** and the production build.
- Actual Studio engine suite: **25 passed / 0 failed**, exit 0. Includes new map access, restraint/defense logic and sampled Tanjiro clips. Final twelve-rig animator benchmark: 2.502 ms per frame (0.209 ms per rig).
- Focused Asakusa two-client suite: **2/2**, exit 0, after fixing the encounter idle timer. All fifteen stages, both rescue clips, real Water attacks, nonlethal defense, one reward, saved kit restoration and cleanup passed.
- Full suite: **14 passed / 9 failed**, exit 1. Prologue virtual E input did not advance dialogue; the resulting missing chapter unlock caused later chapter checks to fail at start. The first failure is unresolved. Both-client Tanjiro profile checks, movement/dashes, sword handling and PvP passed. See HANDOFF.md for exact next debugging steps.
- No new visual review or manual Animation Editor round-trip: the Windows computer-use helper could not connect its native pipe. Automated tests do not prove motion quality, human route traversal, difficulty or cinematic pacing.

## Next work

1. Diagnose the prologue E-input failure and rerun full regression; isolate dependent test failures. Check Git/CI delivery in WORKLOG.md. Finish this qualification before new story implementation.
2. Review all five chapters and base/Tanjiro animation in Studio. Test the importer with an actual editor save/export. Refine observed sword paths, movement, acting, navigation and difficulty.
3. Continue chronologically with Tsuzumi Mansion, Zenitsu/Inosuke introductions and rotating-room encounters, using primary references. Expand Nezuko/Giyu profiles alongside story work.
4. Finish the later arcs, unique boss mechanics, character models, weapons, technique choreography, sound and exploration. Keep all existing cast/PvP/progression objectives.
5. Qualify physical touch/controller controls, small screens, low-FPS/lag dash behavior, performance, balance and live DataStores. Public-release settings and owner-dashboard checks remain open.

## Artifact and delivery

Local production place: `build/WisteriaChronicles.rbxlx`, **3,372,157 bytes**, SHA-256 `9cf06c489cdf5c512c9b1650be90522cb0aaa17ea4735587b8db8c92c0145b56`. Build output and Studio logs are ignored. The shipping place excludes test bridges/hooks.

The last verified release download is [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), source `e2f34d5`, chapters 1-3. Prior animation commit `4fd6110` has [passing CI](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/36588934297). Current checkpoint delivery is pending.

The [private Roblox target](DEPLOYMENT.md) remains universe `10766590718`, place `139004028759819`, containing the earlier upload. No new cloud upload, public-access success or live-save validation is claimed. GitHub pushes do not update Roblox automatically.
