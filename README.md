# Demon Slayer: Wisteria Chronicles

A Roblox action RPG and PvP project. Minimum cast: **Infinity Castle (2025)**, all nine Hashira, Tanjiro and friends, Muzan, and the Twelve Kizuki across the anime.

**Status: playable development build; not a finished or published Roblox experience.** Source, research, test results, and continuation notes are versioned here. See [project status](docs/STATUS.md), [plan](docs/PLAN.md), and [work log](docs/WORKLOG.md).

## Project principles

- Server decides damage, cooldowns, energy, progression, arena membership, and rewards.
- PvP uses equal combat stats; story progression never buys a PvP advantage.
- Every researched technique is distinguishable from an original gameplay adaptation.
- Unrevealed canon techniques remain unknown; invented abilities are labeled.
- Original procedural assets ship first; authored animation/model replacements are tracked.
- Small, documented Git commits preserve context between sessions.

## Play locally

Run `python scripts/check.py`, open `build/WisteriaChronicles.rbxlx` in Roblox Studio, and press **Play (F5)**. The world generates on play. On a fresh machine, run `python scripts/bootstrap.py` first. Full instructions: [setup and controls](docs/SETUP.md).

Select a fighter, choose four techniques, fight training constructs, play the campaign, or enter the PvP courtyard. Multiplayer requires at least two Studio clients or a published Roblox experience.

## Implemented

- **44 selectable characters**, including all nine Hashira, Tanjiro, Nezuko, Zenitsu, Inosuke, Kanao, Genya, Muzan, and all named anime-era Upper/Lower Moons.
- **210 technique entries** with selectable loadouts, energy/cooldowns, shared procedural animation, colored effects, and canon/adaptation labels.
- **22 campaign chapters**, generated themed encounter rooms, character-specific enemy loadouts, chapter unlocking, rank and mastery progression.
- **PvP free-for-all**, three-minute rounds, five-elimination victory, respawns, equal health/energy, and opt-in combat.
- Server-side action validation, hit geometry/line-of-sight checks, guard/parry, dodge, status effects, and DataStore session ownership.
- Keyboard/mouse, controller and touch bindings; UI with roster search, technique descriptions, a world atlas, and reduced effects.

## Verified

Eight portable core tests, seven Studio engine tests, and eight real two-client Studio integration checks passed. GitHub Actions builds a downloadable place artifact on each push. See [test evidence and limitations](docs/QA.md).

## Still in production

Character models and movement are original procedural blockouts. Authored R15 likenesses, per-technique anime choreography, sound/music, complete exploration maps, cinematic storyline, and canonical multi-phase boss rules remain open. The full researched inventory is not a claim of finished assets or complete anime fidelity. [Research](docs/RESEARCH.md) documents source limits and unrevealed forms.
