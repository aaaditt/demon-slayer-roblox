# Story production and next sessions

Updated 2026-09-17. The whole intended campaign remains the goal. One staged prologue and 21 encounter previews are not a finished storyline.

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

## Proposed session sequence

- **Next:** road to Sagiri, sourced temple encounter, Urokodaki's introduction, mountain descent with traps and training objectives. Introduce a practice sword in training. Replace the current direct jump to Sabito's fight with staged progression.
- **Then:** Sabito and Makomo, boulder test, Final Selection exploration and Hand Demon mechanics, Corps induction, Nichirin delivery and Nezuko's travel box. Audit the exact presentation order against lawful episode/manga references before implementation.
- **Early missions:** first town disappearances and swamp rescue, Asakusa civilians and Muzan, Tamayo/Yushiro, Susamaru/Yahaba, Tsuzumi Mansion's rotating rooms and character introductions.
- **Middle campaign:** Natagumo rescue and Rui, Hashira judgment and Butterfly Mansion recovery, Mugen Train dream rescue and linked train boss, Rengoku/Akaza resolution.
- **Later campaign:** Entertainment District infiltration and linked siblings' defeat, Swordsmith Village evacuation with hidden-core Hantengu and Gyokko phases, Hashira Training with all nine Hashira represented across the chronological game.
- **Final campaign:** Infinity Castle branches and canonical boss conditions; keep the confirmed 2025 film cast baseline. Clearly identify later-manga spoilers in the dawn finale.
- **Alongside story chapters:** replace Tanjiro's shared procedural choreography first, then expand to Nezuko, Giyu and the remaining cast without removing the existing roster, PvP or progression scope.

## Source and completion discipline

Catalog story steps, actors, shots, sources and original dialogue live in `data/catalog.json`; generate `src/shared/Content.luau`. Primary official episode summaries establish the broad opening sequence. No full manga reading, shot-by-shot audit, licensed media extraction or authored motion-capture work has occurred. See RESEARCH.md.

A chapter is ready for review only after its objectives are navigable, story actions are validated, camera/input state is restored on exits, rewards cannot duplicate, and the actual runtime has been checked. Automated route tests may reposition a player to objective anchors; that verifies state progression, not a human walking the entire route. Record that distinction in QA.md.
