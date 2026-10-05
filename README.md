# Demon Slayer: Wisteria Chronicles

A Roblox action RPG and PvP project. Minimum cast: **Infinity Castle (2025)**, all nine Hashira, Tanjiro and friends, Muzan, and the Twelve Kizuki across the anime.

**Status: story-first development build; full production remains in progress.** The existing private Roblox upload is the earlier version until a new cloud upload is recorded. [Experience page](https://www.roblox.com/games/139004028759819) · [deployment and access status](docs/DEPLOYMENT.md). Source, research, test results, and continuation notes are versioned here. See [project status](docs/STATUS.md), [plan](docs/PLAN.md), and [work log](docs/WORKLOG.md).

## Project principles

**Continuing in a fresh session:** read [the current handoff](docs/HANDOFF.md) first. It records the Tanjiro animation and Asakusa checkpoint, validation limits and next work; verify the latest workspace before continuing.

- Server decides damage, cooldowns, energy, progression, arena membership, and rewards.
- PvP uses equal combat stats; story progression never buys a PvP advantage.
- Every researched technique is distinguishable from an original gameplay adaptation.
- Unrevealed canon techniques remain unknown; invented abilities are labeled.
- Procedural models and bundled R15 animation clips support basic play without uploaded assets; character-specific motion and likeness production remain tracked work.
- Small, documented Git commits preserve context between sessions.

## Play locally

Download the place from the [0.4.0 development release](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), or build it from source below.

Run `python scripts/check.py`, open `build/WisteriaChronicles.rbxlx` in Roblox Studio, and press **Play (F5)**. The world generates on play. On a fresh machine, run `python scripts/bootstrap.py` first. Full instructions: [setup and controls](docs/SETUP.md).

Select a fighter, choose four techniques, fight training constructs, play the campaign, or enter the PvP courtyard. Multiplayer requires at least two Studio clients or a published Roblox experience.

## Implemented

- **44 selectable characters**, including all nine Hashira, Tanjiro, Nezuko, Zenitsu, Inosuke, Kanao, Genya, Muzan, and all named anime-era Upper/Lower Moons.
- **210 technique entries** with selectable loadouts, energy/cooldowns, shared attack clips, colored effects, and canon/adaptation labels. Tanjiro has the first motion profile (six stance/walk/combo/guard clips); individual technique choreography remains unfinished. See the [animation tracker and Studio workflow](docs/ANIMATION.md).
- **Five staged story chapters**: the Kamado prologue; Sagiri training; Final Selection and homecoming; northwest town/Swamp Demon; and the new Asakusa first pass. **17 later chapters remain encounter previews**. Asakusa has passed engine and focused two-client checks; visual review remains pending. The published 0.4.0 download contains the first three chapters; build current source for version 0.6.0.
- **PvP free-for-all**, three-minute rounds, five-elimination victory, respawns, equal health/energy, and opt-in combat.
- Server-side action validation, hit geometry/line-of-sight checks, guard/parry, dodge, status effects, and DataStore session ownership.
- Visible procedural walk/run, jump/fall/landing and combat poses; camera-relative directional dashes (W/Q front dash, A or D + Q sidestep, S + Q back-hop); single-blade sword drawing/sheathing with **R** (the blade slides out of and back into the saya; a slow noto sheathe out of combat, a fast one in combat, and auto-sheathe after 8 s idle), controller D-pad right or the Sword button.
- Keyboard/mouse, controller and touch bindings; UI with roster search, technique descriptions, a world atlas, reduced effects, and optional basic combat audio.

## Verified

Portable validation passes; the unchanged production build previously passed the 25-check Studio engine suite. The October 5 full two-client run passes all five story routes, natural sequential unlocks and PvP, but **full regression remains unresolved (23 passed / 1 failed)** because W+Q showed a visible frame jump. The prologue E-input test race is fixed. [QA evidence](docs/QA.md) records the results and limitations. Automated checks do not establish visual quality or a human playthrough.

To review the new opening, choose **Journey -> 01 A Trail in the Snow**, including on an existing save. Use E / controller X / the prompt to interact, and E / controller A / Continue for dialogue. Skip Scene skips only that conversation. M -> Return to Hub leaves the chapter. [Story production roadmap](docs/STORY_PRODUCTION.md).

After the opening, choose **02 The Mountain Trial**. Follow the marked course, use basic attacks with the axe/practice sword, and press E / controller X / Breathe during the gold timing window. Exercises restart on a timeout or defeat; their progress is checked by the server. Breathing forms remain locked during this training chapter.

**03 Final Selection** opens an original Fujikasane forest with a wisteria entrance, demon encounters and a night patrol. Use the chapter's four Water forms. Against the Hand Demon, evade its marked reach/sweep and strike during recovery. The chapter continues through ore selection, a Kasugai Crow, reunion at Sagiri, the black Nichirin blade and Nezuko's visible travel box. Seven days are condensed into gameplay and scenes; leaving discards the current attempt.

**04 Beneath the Town** continues with the black sword, Corps uniform and Nezuko's box. Investigate the lantern streets with Kazumi, rescue a young woman, hold off three swamp bodies, and descend while Nezuko guards the survivors. Watch the pools, evade the marked claw attacks, then strike during exposure. A keepsake and farewell lead toward Asakusa. This chapter is in the local build; its current validation/delivery status is in [STATUS.md](docs/STATUS.md).

**05 Lights of Asakusa** adds streets, a noodle stall, Muzan's encounter, a nonlethal civilian restraint exercise, Yushiro's route and Tamayo's house/garden. Defeat Yahaba, then distract Susamaru with Nezuko until Tamayo intervenes. This tested 15-stage first pass includes original dialogue and acting clips; visual review and refinement remain pending. The fights use the shared Arrow/Temari mechanics, with exact canon choreography still in production.

## Still in production

Character models and movement are original procedural blockouts. Authored R15 likenesses, per-technique anime choreography, authored sound/music, complete exploration maps, the remaining cinematic storyline, and canonical multi-phase boss rules remain open. The full researched inventory is not a claim of finished assets or complete anime fidelity. [Research](docs/RESEARCH.md) documents source limits and unrevealed forms.
