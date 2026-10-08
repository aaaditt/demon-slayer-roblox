# Current status

Updated: 2026-10-08

Start fresh sessions with [HANDOFF.md](HANDOFF.md). **Tsuzumi Mansion is implemented as a sixteen-stage first pass.** Portable checks, **28/28 Studio engine checks** and **2/2 focused two-client Tsuzumi checks** pass. The full six-chapter regression passes **27/27**, including natural sequential unlocks, movement/security and PvP. Visual/editor review and later story production remain open.

## Current build: 0.7.0

Six chapters have staged story implementations: Kamado home/prologue, Sagiri training, Final Selection/homecoming, northwest town/Swamp Demon, Lights of Asakusa and **The Shifting Mansion**. Chapter six introduces Zenitsu/Inosuke, the children, parallel-fight cutaways, Kyogai, the box defense/reunion and wisteria rest. The server turns the room/player horizontally, marks three claw lanes and admits damage during attack openings. Dialogue, geometry, turn rules and cutaways are original adaptations; gravity inversion and exact fight choreography are unfinished. See RESEARCH.md and STORY_PRODUCTION.md.

There are **44 bundled R15 clips** and two motion profiles. Tanjiro has six stance/walk/combo/guard overrides. Base clips cover locomotion, directional dashes, attacks and sword handling; the two new restraint clips support the civilian rescue. The checked Studio importer validates exports, backs up prior clips and preserves editor changes during generation. Manual editor round-trip and visual refinement remain pending.

Chapters **7-22 remain encounter previews**. The full objective remains all nine Hashira, protagonists, Muzan, Upper/Lower Moons, Infinity Castle (2025 minimum), story locations, PvP and progression. Catalog coverage is **83 cast records, 44 selectable fighters, 210 techniques, 19 location concepts and 22 chapter definitions**; these are data counts, not completed assets.

## October 8 validation

- `python scripts/check.py`: **6 Python authoring tests, 19 core tests, 34 Luau compilations**, catalog/44 clips/two profiles and production build passed.
- Final Studio engine suite: **28/28**, exit 0. Includes mansion doorways/objective floors, quarter-turn player transport, cast locking, protected/open boss phases, early/repeated claw rejection, lane-gap safety, health-floor retry and mid-turn cleanup. Existing movement/security/animation checks also pass.
- Focused Tsuzumi two-client suite: **2/2**, exit 0, `RUNTIME_JSON.failures=0`. All sixteen stages/lines, client-observed unaccelerated room turn and HUD phases, real Water remote hit, private ownership, 210 XP once, chapter-seven unlock, saved kit restoration and camera/actor/map/slot cleanup passed. A separate check leaves during a room turn.
- Full six-chapter regression: **27/27**, exit 0, `RUNTIME_JSON.failures=0`. All six routes unlock naturally with no fallback seeds; rewards, saved kits, exits/cleanup, profile/sword replication, directional movement, forged-position correction and PvP passed. W+Q: 16.0242 studs server / 14.2670 client, largest frame 3.33334 studs at 0.06636 s. The October 5 section below preserves earlier evidence.
- Intermediate results: initial Studio launch timed out after an updater restart; the verified installed executable/content registry pointer was repaired. First engine run was **27/28**, exposing a rest-house approach blocked by its side wall; the path was corrected. First focused launch failed before tests because two clients did not join. The subsequent focused run passed.

## Previous movement validation (October 5)

- October 5 `python scripts/check.py`: catalog/44 clips/two profiles, **6 Python authoring tests, 19 core tests, 32 Luau compilations** and production build passed.
- Final Studio engine suite: **26/26**, exit 0. Includes path/speed/reach/vertical validation, late upward-flight rejection, swept collision through a newly added wall and correction before casts. Twelve-rig animator benchmark: **0.883 ms/frame**.
- Focused dash candidate: **8/8**, exit 0. Three W+Q attempts each had a largest client frame displacement of about 3.3333 studs, with server travel 15.97–16.19 studs. A real client teleporting 40 studs sideways was corrected on both server and owner.
- Final full two-client suite: **25/25**, exit 0, `RUNTIME_JSON.failures=0`. All five story routes, natural sequential unlocks, rewards, exits/cleanup, profile/sword observations, jump/fall/landing, directional dashes, forged-position rejection and PvP passed. W+Q: **15.9524 studs server / 14.2956 client**, largest frame **3.3333 studs** at 0.0665 s. No movement threshold was weakened.
- An intermediate full run was 24/25 on the old jump observation fixture. It now uses a grounded, held virtual Space input with all three animation phases still required. Experiments and failures remain in QA/WORKLOG; a passing final run does not qualify arbitrary latency or every device.
- Native Windows UI automation is unavailable in the current tool set. No new visual review, human route playthrough or manual Animation Editor round-trip occurred. Automated routes reposition actors and accelerate selected timings; appearance, difficulty and pacing remain unqualified.

## Next work

1. Verify the latest delivery/CI in WORKLOG.md. Retain `--tsuzumi-only` for isolated diagnostics; seeded access cannot replace natural sequential-unlock coverage.
2. Review all six chapters and base/Tanjiro animation in Studio when native UI tooling is available. Test the importer with an actual editor save/export. Refine observed sword paths, movement, acting, navigation and difficulty. Retain `--dash-only` for movement/security diagnostics and qualify network latency and human traversal.
3. Continue chronologically with Mount Natagumo and the spider family using primary references. Expand Nezuko/Giyu profiles alongside story work; refine unfinished Tsuzumi choreography and room mechanics.
4. Finish the later arcs, unique boss mechanics, character models, weapons, technique choreography, sound and exploration. Keep all existing cast/PvP/progression objectives.
5. Qualify physical touch/controller controls, small screens, low-FPS/lag dash behavior, performance, balance and live DataStores. Public-release settings and owner-dashboard checks remain open.

## Artifact and delivery

Local production place: `build/WisteriaChronicles.rbxlx`, **3,422,912 bytes**, SHA-256 `434eebd2ddb4e1ed95976663c6496237e6a82df2f32198f4ce982426aae49aea`. Build output and Studio logs are ignored. The shipping place excludes test bridges/hooks.

Movement checkpoint [e9625a4](https://github.com/aaaditt/demon-slayer-roblox/commit/e9625a4380d91aa123a7ef3822f29abfe0dccb45) is pushed and its [portable CI passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/37321126525). Tsuzumi source/test delivery will be recorded in WORKLOG.md. Player motion retains client simulation with independent server path/collision validation; Tsuzumi adds no client action. The last release download remains [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), chapters 1-3; build current source for all six. No new release or Roblox upload occurred.

The [private Roblox target](DEPLOYMENT.md) remains universe `10766590718`, place `139004028759819`, containing the earlier upload. No new cloud upload, public-access success or live-save validation is claimed. GitHub pushes do not update Roblox automatically.
