# Current status

Updated: 2026-10-08

Start fresh sessions with [HANDOFF.md](HANDOFF.md). **Full two-client regression passes 25/25; Studio engine checks pass 26/26.** The prologue input race and dash ownership catch-up are resolved in the tested build. Player motion now retains client simulation with independent server path/collision validation; actual forged movement is rejected and corrected. Visual/editor review and later story production remain open.

## Current build: 0.6.0

Five chapters have staged story implementations: Kamado home/prologue, Sagiri training, Final Selection/homecoming, northwest town/Swamp Demon and **Lights of Asakusa**. Chapter five has fifteen stages, city streets and a noodle stall, Muzan and a civilian emergency, Tamayo/Yushiro, an enterable clinic/garden, Yahaba, a nonlethal Susamaru defense phase and departure. Dialogue, geography, encounter rules and acting are condensed original adaptations; see RESEARCH.md.

There are **44 bundled R15 clips** and two motion profiles. Tanjiro has six stance/walk/combo/guard overrides. Base clips cover locomotion, directional dashes, attacks and sword handling; the two new restraint clips support the civilian rescue. The checked Studio importer validates exports, backs up prior clips and preserves editor changes during generation. Manual editor round-trip and visual refinement remain pending.

Chapters **6-22 remain encounter previews**. The full objective remains all nine Hashira, protagonists, Muzan, Upper/Lower Moons, Infinity Castle (2025 minimum), story locations, PvP and progression. Catalog coverage is **83 cast records, 44 selectable fighters, 210 techniques, 19 location concepts and 22 chapter definitions**; these are data counts, not completed assets.

## Current validation

- October 5 `python scripts/check.py`: catalog/44 clips/two profiles, **6 Python authoring tests, 19 core tests, 32 Luau compilations** and production build passed.
- Final Studio engine suite: **26/26**, exit 0. Includes path/speed/reach/vertical validation, late upward-flight rejection, swept collision through a newly added wall and correction before casts. Twelve-rig animator benchmark: **0.883 ms/frame**.
- Focused dash candidate: **8/8**, exit 0. Three W+Q attempts each had a largest client frame displacement of about 3.3333 studs, with server travel 15.97–16.19 studs. A real client teleporting 40 studs sideways was corrected on both server and owner.
- Final full two-client suite: **25/25**, exit 0, `RUNTIME_JSON.failures=0`. All five story routes, natural sequential unlocks, rewards, exits/cleanup, profile/sword observations, jump/fall/landing, directional dashes, forged-position rejection and PvP passed. W+Q: **15.9524 studs server / 14.2956 client**, largest frame **3.3333 studs** at 0.0665 s. No movement threshold was weakened.
- An intermediate full run was 24/25 on the old jump observation fixture. It now uses a grounded, held virtual Space input with all three animation phases still required. Experiments and failures remain in QA/WORKLOG; a passing final run does not qualify arbitrary latency or every device.
- Native Windows UI automation is unavailable in the current tool set. No new visual review, human route playthrough or manual Animation Editor round-trip occurred. Automated routes reposition actors and accelerate selected timings; appearance, difficulty and pacing remain unqualified.

## Next work

1. Review the new client-driven dash and all five chapters in Studio when native UI tooling is available. Retain `--dash-only` for repeated movement and rejection diagnostics; qualify network latency, physical controls and human traversal.
2. Review all five chapters and base/Tanjiro animation in Studio. Test the importer with an actual editor save/export. Refine observed sword paths, movement, acting, navigation and difficulty.
3. Continue chronologically with Tsuzumi Mansion, Zenitsu/Inosuke introductions and rotating-room encounters, using primary references. Expand Nezuko/Giyu profiles alongside story work.
4. Finish the later arcs, unique boss mechanics, character models, weapons, technique choreography, sound and exploration. Keep all existing cast/PvP/progression objectives.
5. Qualify physical touch/controller controls, small screens, low-FPS/lag dash behavior, performance, balance and live DataStores. Public-release settings and owner-dashboard checks remain open.

## Artifact and delivery

Local production place: `build/WisteriaChronicles.rbxlx`, **3,377,746 bytes**, SHA-256 `4d7b1b965604544c2c7c4d0db90fe5e44e99c72952bf91a2455a9bea15f9949c`. Build output and Studio logs are ignored. The shipping place excludes test bridges/hooks.

Movement checkpoint [e9625a4](https://github.com/aaaditt/demon-slayer-roblox/commit/e9625a4380d91aa123a7ef3822f29abfe0dccb45) is pushed and its [portable CI passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/37321126525). Tsuzumi production is beginning; source/test results will be recorded in WORKLOG.md. This production build supersedes the earlier server-ownership dash implementation. The last release download remains [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), chapters 1-3; build current source for all five. No new release or Roblox upload occurred.

The [private Roblox target](DEPLOYMENT.md) remains universe `10766590718`, place `139004028759819`, containing the earlier upload. No new cloud upload, public-access success or live-save validation is claimed. GitHub pushes do not update Roblox automatically.
