# Delivery plan

## Intended game

Third-person arena combat and a chronological, replayable story campaign. A wisteria hub connects training, character selection, unlocked missions, and opt-in PvP. Characters have complete researched technique libraries and a selectable four-slot loadout. All characters are available for fair PvP; campaign XP gives rank/mastery and unlocks chapters, not paid combat power.

## Milestones and acceptance

1. **Research and durable project setup** — sourced roster, known forms, demon abilities, anime locations, spoiler/unknown flags, GitHub checkpoints, continuation documents.
2. **Combat foundation** — server-validated hits, telegraphs, basic combo, guard/parry, dodge, energy/cooldowns, statuses, character selection and move loadouts; pure logic tests and a compilable place.
3. **Playable campaign and PvP** — procedural hub and themed locations, mission progression, boss AI, training targets, opt-in arena scoring, persistence, desktop/touch/gamepad controls.
4. **Character and audiovisual production** — authored R15 characters, distinct weapon rigs, per-technique animation clips, VFX and sound, cinematic encounters, navigation, accessibility and performance refinement.
5. **Release qualification** — actual Studio solo and multi-client tests, phone/controller checks, exploit testing, balance sessions, datastore failure testing, publish to an owner-controlled Roblox experience and run live multiplayer QA.

## World route

Kamado mountain → Mount Sagiri → Fujikasane Final Selection → first mission town → Asakusa → Tsuzumi Mansion → Mount Natagumo → Butterfly Mansion → Mugen Train → Entertainment District → Swordsmith Village → Hashira Training → Infinity Castle → dawn finale (later-story spoiler). Optional Twelve Kizuki archive encounters cover ranks whose combat is not shown.

## Combat design

Four equipped techniques chosen from each character's library; Q dodge; F guard; basic attack combo; energy regenerates outside recovery. A readable windup precedes powerful attacks. Each technique defines shape, reach, startup, recovery, damage, energy, cooldown, movement, effect color, and status. All numeric timings/damage are original game balancing, not canon claims. Shared combat primitives allow the entire catalog to function while authored move-specific choreography is produced.

## Quality boundaries

- Do not invent missing numbered forms or unshown Lower Moon Blood Demon Arts as canon.
- Research inventory, playable mechanical adaptation, and final authored asset are separate completion states.
- Local compilation and unit tests cannot substitute for Roblox multiplayer testing.
- DataStore failures must not overwrite a prior save with fallback defaults.
- No copied anime footage, music, dialogue scripts, or extracted commercial-game assets in the repository.


## Story-first continuation (2026-09-17)

Owner review found missing visible locomotion, a teleport-like dash and an opening with no house or narrative. Prioritize a chronological story experience and readable movement before more roster breadth or public release settings. The current work builds the Kamado prologue and repairs shared movement/sword handling. See STORY_PRODUCTION.md for the part-by-part route, acceptance boundaries and next Sagiri session. The remaining full game objective is unchanged.

2026-09-18: the second staged chapter now spans the temple through Urokodaki's training, Sabito/Makomo and the boulder test. Final Selection is the next chronological implementation slice. Keep chapter review, authored animation and persistent lesson checkpoints on the production backlog; twenty later chapters remain encounter previews.

2026-09-19: Final Selection now has a staged forest chapter, a Hand Demon attack/recovery cycle, a patrol, Corps induction and the return for the sword/box. The next slice is the first town investigation and Swamp Demon rescue. Nineteen later chapters remain encounter previews. The completed data/state flows do not replace visual, manual-route, balance, authored animation or physical-device qualification.

2026-09-29: chapter four's town investigation, rescue, three-body swamp sequence and farewell are implemented locally. Portable, engine and full two-client checks passed; Git checkpoint/release is blocked by the read-only `.git` environment. Eighteen later chapters remain encounter previews. Next chronological production is Asakusa, Muzan and the civilian emergency, followed by Tamayo/Yushiro. Keep authored choreography, manual map/navigation review and the wider cast/PvP/progression objectives in scope.

2026-09-30: chapter four and animation phases 1-8 were subsequently committed (HEAD on entry: `4fd6110`). This continuation adds the first Tanjiro motion profile, shared clip resolution and checked Studio imports (ANIMATION.md phases 9-10). Next: visually review the clips and four staged chapters, refine observed problems, then build Asakusa. The complete cast, later arcs, PvP and progression remain in scope; a first profile is not completion of character animation production. See STATUS.md and WORKLOG.md for current tests and delivery restrictions rather than the historical Git blockage above.

Later September 30 continuation: Asakusa now has a 15-stage source implementation, civilian restraint, separate city/clinic maps, existing Arrow/Temari encounters, a nonlethal defense phase and departure. Five chapters are staged locally; chapters 6-22 remain previews. Portable checks pass, but Studio execution and visual qualification remain blocked/pending. Next production order: qualify this checkpoint, review/refine the five chapters and animation, then Tsuzumi Mansion. Local commit attempts still fail at `.git/index.lock`; preserve both staged and unstaged work.

2026-10-04 handoff: Studio and GitHub access recovered without registry edits. The 0.6.0 Tanjiro/import/Asakusa checkpoint passes portable checks, engine 25/25 and focused chapter integration 2/2 after fixing immediate auto-sheathe on encounter start. Full-regression/delivery outcome is in WORKLOG.md. User requested a fresh-session handoff; next priorities are outstanding qualification, visual/editor review and refinement, then Tsuzumi Mansion. See HANDOFF.md for exact continuation instructions.


2026-10-05 continuation: prologue input timing and dash replication qualification are resolved in the tested checkpoint: portable 6 authoring/19 core/32 compilations, engine 26/26, full two-client 25/25. Player dash simulation retains client ownership inside independently validated server speed/reach/collision bounds; forged positions are corrected in real-client testing. Next are human visual/editor review and refinement, then Tsuzumi Mansion and Zenitsu/Inosuke, alongside character motion production. Native Windows UI tooling is unavailable in this session; no review or editor round-trip is claimed. All remaining arcs, cast, PvP, progression, live saves and release qualification remain in scope.

2026-10-08 continuation: chapter six now has sixteen staged Tsuzumi scenes, Zenitsu/Inosuke cutaways, box continuity, an original quarter-turn/claw-lane boss and wisteria rest. Six chapters are staged; chapters 7–22 remain previews. Portable checks, 28 engine checks, both focused Tsuzumi checks and all 27 full two-client checks pass; consult STATUS/QA for evidence and limits. Continue with Natagumo/spider-family production while retaining pending human visual/editor/device qualification and all later cast/story/PvP/progression work. Full gravity inversion and exact Tsuzumi fight choreography remain unfinished.
