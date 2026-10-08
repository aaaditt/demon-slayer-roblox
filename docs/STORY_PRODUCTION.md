# Story production and next sessions

Updated 2026-10-08. The whole intended campaign remains the goal. Six locally staged chapters and 16 encounter previews are not a finished storyline. Current runtime evidence is in QA.md and STATUS.md.

## Current playable chapter: A Trail in the Snow

The first chapter replaces the generic temple-demon room with an original snowy mountain set. It has an enterable Kamado home with a veranda, hearth, table and sleeping mats; a market; Saburo's shelter; a woodland route; a clearing; and an eastward exit. Geometry, staging and dialogue are original interpretations, not a reconstruction of exact canonical geography or an episode transcript.

1. Establish the family home in daylight.
2. Speak with Kie, with Tanjiro's siblings present.
3. Collect and visibly carry charcoal.
4. Deliver it in town.
5. Speak with Saburo and stay overnight.
6. Return to the changed home at dawn. Loss is conveyed without graphic bodies or gore.
7. Find Nezuko and visibly carry her down the mountain.
8. Stage her transformation, Giyu's intervention, and her protection of Tanjiro.
9. Hear Giyu's direction to seek Urokodaki.
10. Depart toward Sagiri, receive the chapter reward, and restore the player's hub fighter.

The player takes the role of pre-training Tanjiro. Breathing skills, sword attacks and sword drawing are disabled here on the server. No temple demon is placed at the Kamado home. The temple encounter belongs on the subsequent route. The carry model depicts Nezuko on Tanjiro's back; her later wooden travel box is still to be introduced in the proper sequence.

Dialogue is advanced with E, controller A, or the Continue button. Y / controller Y / Skip Scene skips the current conversation, not the travel objectives. E, controller X or the proximity prompt performs interactions. M opens Journey, including Return to Hub. Prompts verify the owner, active objective, living actor and distance on the server. Progression is awarded once at the end. Leaving, dying or disconnecting discards the current prologue attempt; within-chapter save checkpoints are not implemented yet.

## What this checkpoint does not finish

The rigs and sets are procedural art. Cutscenes use original camera shots and joint poses with limited Giyu movement, not anime-quality acting. Voice acting, facial animation, music, cinematic sound design, exact costumes, per-character locomotion and authored R15 animation clips remain production work. The remaining chapter cards explicitly say Encounter Preview. Their combat scaffolding has not been presented as completed story scenes.

## Second playable chapter: The Mountain Trial

An original forest set connects an enterable temple and Urokodaki's house, an elevated mountain course, practice yard, waterfall, sparring clearing and splitting boulder. Thirteen stages cover the road, temple struggle, Urokodaki's introduction, Nezuko resting at the house, mountain descent, sword repetitions, breathing practice, the stone hurdle, Sabito, Makomo, rematch, boulder cut and departure for Final Selection.

The temple exercise uses a visible axe, three controlled hits and an 18-second survival requirement. Nezuko's intervention and dawn are narrated in a condensed result scene. Training uses a wooden sword, nonlethal Sabito sparring, ordered course markers and three telegraphed traps. Breathing requires standing still near the objective and one input per gold window; cutting the boulder requires an accepted breath followed by a hit within four seconds. The server controls all objectives, damage, timing and completion. Scene skipping cannot complete an exercise. Defeat or timeout restarts the current lesson; leaving the chapter still discards the attempt.

These short exercises represent two years through original scene transitions. They do not reproduce exact canonical durations, geography, fights or shot composition. Axe/practice-sword basics are available only in the relevant lessons; selectable breathing forms stay locked. Completing the chapter unlocks the staged Final Selection chapter below.

## Third playable chapter: Final Selection

Thirteen stages cover arrival beneath wisteria, the guides' briefing, first-night demons, a candidate's warning, the Hand Demon, a patrol representing the remaining nights, the surviving candidates, ore selection, the crow, return to Sagiri, sword delivery, Nezuko's box and the first assignment. A separate Fujikasane set has connected forest paths, a gathering court and a boss clearing. The return replaces that set with Urokodaki's Sagiri home in the same private mission slot.

The chapter equips a fixed Water loadout (forms 1, 2, 4 and 8), while preserving the player's saved hub loadout and fighter. The borrowed sword can be drawn/sheathed. The Hand Demon has six additional animated arms and original reach/sweep telegraphs. Its guarded neck rejects damage until the recovery window; the boss encounter ends on defeat. The three-stop patrol requires the enemies and a minimum survival time. Encounters restart locally on defeat or timeout. These mechanics, checkpoint protection and brief durations are explicit game adaptations, not canon measurements or a literal seven-day simulation.

The return scenes add a reunion pose, Corps belt/buttons, a shoulder crow, Haganezuka, a black blade and a wooden travel box. These are original procedural props and limited poses. Exact costume, facial acting, mask breakage, sword-color transformation, reunion choreography and the Hand Demon's memories/defeat animation still need authored production. Chapter four continues with the sword, uniform and box.

## Fourth playable chapter: Beneath the Town

Thirteen stages connect the northwest town arrival, Kazumi, two investigation stops, an open-house rescue, the three-body ambush, Nezuko's intervention, the pool entrance, two bodies below, the last body above, a recovered keepsake, farewell and departure for Asakusa. The player begins with a black sword and travel box. Nezuko leaves it for a short moving kick scene, stays above during the swamp fight and lunges during the final body's openings. The box is visibly open while she is outside and closes for dawn departure.

The ambush requires three damaging hits and sixteen seconds; the later encounters require actual defeats. Bodies emerge from fixed pools, mark a claw reach, expose themselves briefly and sink. Only the surfaced opening takes damage. This sequential pattern, nonlethal player retry, compact layout and walkable swamp floor are original gameplay adaptations. Forms 1/2/6/8 are a temporary chapter kit. Server checks enforce owner/distance/objective order, combat permissions, timers and rewards; leaving discards the current attempt. Exact rescue choreography, swimming/oxygen, interrogation, acting and the complete keepsake sequence remain production work. Runtime test status and limits are recorded in QA.md.

## Proposed session sequence

- **Next:** visually review the six staged chapters and base/Tanjiro clips, complete an Animation Editor export/import round-trip, and refine navigation, acting and difficulty. Continue chronologically with Mount Natagumo and the spider family from primary references; refine Tsuzumi alongside the earlier chapters. See STATUS.md for current validation and delivery.
- **Training refinement:** authored temple intervention, Sabito/Makomo acting, expanded mountain routes, waterfall animation/sound and persistent within-chapter checkpoints. The current chapter uses condensed narrated transitions and shared procedural poses.
- **Selection refinement:** final boss art/acting, expanded survival exploration, candidate interactions, physical route playtesting and scene-level costume/choreography audit. The current boss's attack/recovery cycle is original gameplay.
- **Early missions:** first town disappearances and swamp rescue, Asakusa civilians and Muzan, Tamayo/Yushiro, Susamaru/Yahaba, Tsuzumi Mansion's rotating rooms and character introductions.
- **Middle campaign:** Natagumo rescue and Rui, Hashira judgment and Butterfly Mansion recovery, Mugen Train dream rescue and linked train boss, Rengoku/Akaza resolution.
- **Later campaign:** Entertainment District infiltration and linked siblings' defeat, Swordsmith Village evacuation with hidden-core Hantengu and Gyokko phases, Hashira Training with all nine Hashira represented across the chronological game.
- **Final campaign:** Infinity Castle branches and canonical boss conditions; keep the confirmed 2025 film cast baseline. Clearly identify later-manga spoilers in the dawn finale.
- **Alongside story chapters:** replace Tanjiro's shared procedural choreography first, then expand to Nezuko, Giyu and the remaining cast without removing the existing roster, PvP or progression scope.

## Source and completion discipline

Catalog story steps, actors, shots, sources and original dialogue live in `data/catalog.json`; generate `src/shared/Content.luau`. Primary official episode summaries establish the broad opening sequence. No full manga reading, shot-by-shot audit, licensed media extraction or authored motion-capture work has occurred. See RESEARCH.md.

A chapter is ready for review only after its objectives are navigable, story actions are validated, camera/input state is restored on exits, rewards cannot duplicate, and the actual runtime has been checked. Automated route tests may reposition a player to objective anchors; that verifies state progression, not a human walking the entire route. Record that distinction in QA.md.

## Fifth chapter first pass: Lights of Asakusa

Fifteen stages cover city arrival, a noodle stall, the scent trail, Muzan, civilian restraint, Tamayo's help, returning for Nezuko, Yushiro's lane, the hidden clinic, consultation, the attack, Yahaba, Susamaru's defense phase, trust and departure. The house is a separate map in the same private mission slot, with an enterable clinic, patient mats, medicine table and garden.

The civilian is never a combat target. Sword use and skills are disabled during four timed, stationary bracing inputs near the marker; `restrain` and `struggle` are bundled body clips. Ownership, distance, phase, timing and repeated-input rejection are server-checked. Yahaba uses his existing Arrow techniques; Susamaru uses Temari techniques and stays alive until the three-hit/20-second defense objective triggers Tamayo's scene. Nezuko plays repeated short kicks beside that encounter. Defeat/timeout restarts the current challenge, and chapter completion restores the saved hub fighter/loadout.

Portable validation, the 25-check engine suite and both focused two-client chapter checks pass. Tests cover map access, restraint restrictions and client playback, nonlethal defense, real Water attacks, ownership, progression/rewards and cleanup. They reposition actors and accelerate clocks/damage; this is not a manual route or difficulty review. The chapter has not been uploaded to Roblox. Exact boss choreography/physics, blood-collection scenes, detailed acting and visual refinement remain work.

## Sixth chapter first pass: The Shifting Mansion

Sixteen stages cover Zenitsu on the road, the children, setting down Nezuko's box, entering and becoming separated, Inosuke, the missing brother, two parallel-fight cutaways, Kyogai, gathering the children, the box defense/reunion, a wisteria rest house and departure. The original set contains a turning chamber, annex, shaded roadside and enterable rest house. All dialogue is original; episode synopses establish only the broad sequence.

Kyogai's server-controlled cycle turns the room and player horizontally by 90 degrees, marks three claw lanes, resolves at most one hit, and exposes the boss for a short Water-attack opening. It cancels pending movement/attacks during the turn and restores control afterward. Defeat, timeout or leaving the encounter radius restarts locally; exit during rotation clears temporary locks, actors and the mission room. No new client action is exposed. The box's static prop appears when set down and disappears when collected. Completion awards 210 XP once, unlocks chapter seven and restores the saved kit.

Horizontal turns, guarded/open phases and short cutaways are gameplay adaptations. They do not implement gravity inversion, full room rearrangement, exact Thunder/Beast choreography, the entire outside fight, Kyogai's memories/manuscripts, facial acting or scene-accurate costumes. Human navigation, appearance and balance remain unqualified even when automated checks pass. The next chronological story slice is Natagumo; all later arcs and the full cast remain in scope.
