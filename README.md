# Demon Slayer: Wisteria Chronicles

A Roblox action RPG and PvP project. Minimum cast: **Infinity Castle (2025)**, all nine Hashira, Tanjiro and friends, Muzan, and the Twelve Kizuki across the anime.

**Status: story-first development build; full production remains in progress.** The existing private Roblox upload is the earlier version until a new cloud upload is recorded. [Experience page](https://www.roblox.com/games/139004028759819) · [deployment and access status](docs/DEPLOYMENT.md). Source, research, test results, and continuation notes are versioned here. See [project status](docs/STATUS.md), [plan](docs/PLAN.md), and [work log](docs/WORKLOG.md).

## Project principles

- Server decides damage, cooldowns, energy, progression, arena membership, and rewards.
- PvP uses equal combat stats; story progression never buys a PvP advantage.
- Every researched technique is distinguishable from an original gameplay adaptation.
- Unrevealed canon techniques remain unknown; invented abilities are labeled.
- Original procedural assets ship first; authored animation/model replacements are tracked.
- Small, documented Git commits preserve context between sessions.

## Play locally

Download the place from the [0.2.0 development release](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.2.0-dev.1), or build it from source below.

Run `python scripts/check.py`, open `build/WisteriaChronicles.rbxlx` in Roblox Studio, and press **Play (F5)**. The world generates on play. On a fresh machine, run `python scripts/bootstrap.py` first. Full instructions: [setup and controls](docs/SETUP.md).

Select a fighter, choose four techniques, fight training constructs, play the campaign, or enter the PvP courtyard. Multiplayer requires at least two Studio clients or a published Roblox experience.

## Implemented

- **44 selectable characters**, including all nine Hashira, Tanjiro, Nezuko, Zenitsu, Inosuke, Kanao, Genya, Muzan, and all named anime-era Upper/Lower Moons.
- **210 technique entries** with selectable loadouts, energy/cooldowns, shared procedural animation, colored effects, and canon/adaptation labels.
- **A staged opening story chapter** with the Kamado home, family, charcoal route, Nezuko rescue, Giyu scenes, dialogue, objectives and chapter rewards. **21 later chapters remain encounter previews**, with the full storyline still in production.
- **PvP free-for-all**, three-minute rounds, five-elimination victory, respawns, equal health/energy, and opt-in combat.
- Server-side action validation, hit geometry/line-of-sight checks, guard/parry, dodge, status effects, and DataStore session ownership.
- Visible procedural walk/run, jump/fall/landing and combat poses; timed directional dashes; single-blade sword drawing/sheathing with **R**, controller D-pad right or the Sword button.
- Keyboard/mouse, controller and touch bindings; UI with roster search, technique descriptions, a world atlas, reduced effects, and optional basic combat audio.

## Verified

Portable validation, Roblox engine checks and real two-client Studio integration cover the current development systems. New checks measure joint animation, held W + Q input, replicated sword state, opening-story stage validation/rewards and camera restoration. [QA evidence](docs/QA.md) records exact results, intermediate failures and the limits of automated route tests.

To review the new opening, choose **Journey -> 01 A Trail in the Snow**, including on an existing save. Use E / controller X / the prompt to interact, and E / controller A / Continue for dialogue. Skip Scene skips only that conversation. M -> Return to Hub leaves the chapter. [Story production roadmap](docs/STORY_PRODUCTION.md).

## Still in production

Character models and movement are original procedural blockouts. Authored R15 likenesses, per-technique anime choreography, authored sound/music, complete exploration maps, the remaining cinematic storyline, and canonical multi-phase boss rules remain open. The full researched inventory is not a claim of finished assets or complete anime fidelity. [Research](docs/RESEARCH.md) documents source limits and unrevealed forms.
