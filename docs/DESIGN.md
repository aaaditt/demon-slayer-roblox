# Gameplay specification

## Play loop

Start in the Butterfly Mansion's wisteria courtyard. Choose any implemented character, equip four techniques, practice on constructs, play the next unlocked story chapter, or opt into the arena. Story encounters are private per player in this build. PvP is a shared opt-in free-for-all. A round ends at five eliminations or after three minutes with at least two contestants.

## Combat

- Everyone has 160 HP and 100 energy in PvP. Campaign mastery gives rank and completion records, not extra PvP health or damage.
- Basic three-hit attacks supply low-cost pressure; techniques require energy and have server cooldowns.
- Guard is directional, consumes energy when hit, and breaks when exhausted. A short initial guard window parries. Dodge grants a short evasion window; recovery prevents unrestricted spam.
- Skill hit shapes include frontal cuts, thrusts, sweeping circles, rushes, bursts, ranged lines, delayed fields, and repeated pulses. `summon` currently means a repeated field projection; independent canonical minions are not implemented.
- Poison/burn deal capped periodic damage, chill slows, root/sleep briefly restrict movement, and shock briefly interrupts. Status durations and visual cues are original adaptations.
- Every hit checks actor identity, life, mode, zone, range, height, sight obstruction, and defensive state. Clients never send damage, targets, XP, or money.
- Players may change character/loadout only in the hub. Leaving combat requires an out-of-combat delay. Spawn protection expires quickly.

## Art direction

Original geometric Japanese-inspired architecture, dark indigo skies, teal shadow, warm lanterns, and violet wisteria. The UI uses warm ivory text and restrained gold accents. Models are procedural block characters with stylized hair, coats, distinctive weapon silhouettes, and local joint animation. Detailed likenesses and R15 authored animations are future production work.

## Story adaptation

Chronological playable encounter chain, with brief original mission introductions and progressively tougher opponents. Later-story missions are labeled. Defeat returns the player to the hub with the chapter still available. Completion awards XP once per successful run and advances the next unlocked chapter. Replays are allowed.

The broad chronology exists; the complete anime storyline, cutscenes, every village/interior, canonical multi-phase boss rules, and character-specific side stories remain production tasks. Track these in STATUS.md rather than equating catalog coverage with finished content.

## Scope of this build

No monetization, purchases, licensed asset claims, or public Roblox deployment. The repository and locally built place are the deliverables that can be tested immediately. A released game needs an owner-controlled Roblox experience, runtime and device QA, polished assets/audio, and balance work.
