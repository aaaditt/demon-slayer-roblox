# Research and canon boundaries

Reviewed 2026-09-15. Minimum film: **Infinity Castle (2025)**, confirmed by the owner. This is a broad implementation inventory, not a completed frame-by-frame anime audit. The catalog contains later-manga material to support the requested eventual storyline; conservative `spoiler` flags identify that material. Some flags may over-label techniques already animated. Translation names differ between subtitles, dubs, VIZ, and community references.

## Evidence hierarchy

1. Official anime pages establish cast and arc context. The [Japanese Infinity Castle roster](https://kimetsu.com/anime/mugenjyohen_movie/character/) explicitly includes the protagonists, active Hashira, Tengen, Muzan, Kokushibo, Doma, Akaza, Nakime, and Kaigaku. The [Hashira Training roster](https://demonslayer-anime.com/hta/character/) supports Corps roles.
2. [Official season-one episode pages](https://demonslayer-anime.com/risshihen/story/), including [Tsuzumi Mansion](https://demonslayer-anime.com/risshihen/story/11.html), and the [Mugen Train story](https://demonslayer-anime.com/mugentrain/story/) establish location/arc context.
3. Technique names and broad mechanics use the community wiki's indexed technique sections. Direct Fandom fetches returned errors/robots restrictions; search-index excerpts were available. These are **secondary references**, not independently verified translations or frame-exact choreography. Every style/move links its reference in [the generated inventory](CONTENT_INVENTORY.md) and `data/catalog.json`.
4. Damage, energy, timings, hit volumes, balance, arena geography, dialogue summaries, and procedural animation are original game design. None are claimed to be canon measurements.

## Critical distinctions

- [Water](https://kimetsu-no-yaiba.fandom.com/wiki/Water_Breathing): ten standard forms, Giyu's personal eleventh, and known variants. Dead Calm is restricted to Giyu. Individual use of all standard forms by trainers is an explicitly stated style-level extrapolation.
- [Thunder](https://kimetsu-no-yaiba.fandom.com/wiki/Thunder_Breathing): Zenitsu's kit uses first-form variants and his seventh form. Kaigaku uses forms two through six. They must not inherit one another's restricted forms.
- [Insect](https://kimetsu-no-yaiba.fandom.com/wiki/Insect_Breathing): include the Infinity Castle anime-original Horsefly technique. It is separate from licensed-game-exclusive moves.
- [Flame](https://kimetsu-no-yaiba.fandom.com/wiki/Flame_Breathing), [Sound](https://kimetsu-no-yaiba.fandom.com/wiki/Sound_Breathing), [Love](https://kimetsu-no-yaiba.fandom.com/wiki/Love_Breathing), [Flower](https://kimetsu-no-yaiba.fandom.com/wiki/Flower_Breathing), and [Moon](https://kimetsu-no-yaiba.fandom.com/wiki/Moon_Breathing) have gaps in demonstrated numbered forms. Missing forms stay absent; known counts do not imply every form is named or shown.
- Nakime controls castle space; [her reference](https://kimetsu-no-yaiba.fandom.com/wiki/Nakime) does not establish canon named attack techniques. Her gameplay labels are descriptive/original.
- Many Blood Demon Art category names are community descriptions. `named`, `descriptive`, `anime-original`, and `original` distinguish technique nomenclature; all executable mechanics are adaptations.
- Lower ranks: Enmu (1), Rokuro (2), Wakuraba (3), Mukago (4), Rui (5), Kamanue (6); Kyogai is a former Lower Six. Four unshown rank holders have **original generic combat kits**, not invented canonical Blood Demon Arts. The archive mission is original.
- Upper ranks span replacements: Kokushibo (1), Doma (2), Akaza (3), Hantengu then Nakime (4), Gyokko (5), Daki/Gyutaro then Kaigaku (6). These are chronological alternatives, not simultaneous occupants.
- Nezuko's canon blood flames have selective properties; symmetric PvP damage is an explicit balance adaptation. Muzan and demon regeneration are limited by energy/cooldowns for fair play.

## Animation and map research backlog

For each technique, obtain a lawful scene reference, episode/movie plus timestamp, first anticipation pose, strike path, footwork, recovery pose, weapon attachment, and camera/VFX notes. No timestamps are invented here. Current procedural poses are shared by attack pattern. They are useful for playtesting timing, but they do not reproduce the anime's choreography.

The current locations are compact procedural encounter interpretations. They do not yet reconstruct full canonical geography. Add location-specific navigation, interiors, exploration objectives, civilians, authored cinematics, dynamic castle transformations, Daki/Gyutaro linked defeat conditions, Hantengu's hidden core, Enmu's dream rescue sequence, and a true timed sunrise encounter.

Supporting cast are catalog records; they are not all realized as individual quest scenes. Hairo, Ubume and supplementary-work-only material need a separately sourced expansion. Costume variants, Demon Slayer Marks, Transparent World, Selfless State, red blades, all combat passives, and every anime-original variant remain subject to a scene audit.

## Technical sources

- [Roblox client/server boundary security](https://create.roblox.com/docs/scripting/security/client-server-boundary): server validation, rate limits, combat hit admission.
- [Roblox remote events](https://create.roblox.com/docs/scripting/events/remote): action requests and state/effect replication.
- [Rojo project/build workflow](https://rojo.space/docs/v7/getting-started/new-game/): reproducible place compilation.
- [run-in-roblox](https://github.com/rojo-rbx/run-in-roblox): local Studio script execution for runtime smoke tests.

No anime footage, ripped models, soundtrack recordings, or commercial-game animation files were downloaded into the project.

## 2026-09-17 opening chapter audit

Read the official [episode 1 synopsis](https://demonslayer-anime.com/risshihen/story/01.html) and [episode 2 synopsis](https://demonslayer-anime.com/risshihen/story/02.html). These support the family/charcoal premise, discovery at the home, carrying Nezuko down the snowy mountain, her transformation, Giyu sending Tanjiro toward Sagiri, and the temple encounter occurring afterward. Removed the temple demon from chapter one.

The prologue's dialogue, errands, layout, camera positions, non-graphic depiction of loss and brief joint choreography are original condensed game adaptations. The primary synopsis is not a detailed scene audit: Saburo dialogue, exact family blocking, Giyu's choreography and costume/prop details still need a lawful episode-level review. We have not read or ingested the entire manga in this session. Later chapters remain encounter previews with the production sequence tracked in STORY_PRODUCTION.md.

Technical behavior was checked against Roblox's [Motor6D reference](https://create.roblox.com/docs/reference/engine/classes/Motor6D). Procedural joints are now discovered across character replication/lifecycle events and posed locally on every observing client. Authored animation asset IDs are still absent by design at this checkpoint; animation visibly running in a client must be tested, not inferred from successful compilation.

The revised dash uses the official [LinearVelocity constraint API](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity) and [WorldRoot block casts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Blockcast). Server physics ownership is retained briefly after stopping to allow the final transform to replicate before control returns to the player.

## 2026-09-18 Sagiri chapter audit

Read the official [episode 2](https://demonslayer-anime.com/risshihen/story/02.html), [episode 3](https://demonslayer-anime.com/risshihen/story/03.html) and [episode 4](https://demonslayer-anime.com/risshihen/story/04.html) synopses. They establish the route to Sagiri with Nezuko, an axe used against the temple demon, Urokodaki's mountain traps/sword swings/waterfall/breathing regimen, the boulder hurdle after a year, and two years of preparation before Final Selection.

The chapter's dialogue, map, visible timing windows, short survival timer, nonlethal sparring and marked checkpoints are original condensed gameplay. Temple dismemberment/rescue choreography is summarized non-graphically; Sabito and Makomo's exact acting and the final exchange still need an episode-level audit. The splitting boulder is a procedural effect. A wooden practice sword throughout these lessons is an explicit asset/gameplay simplification, not a claim about every canonical training weapon. No entire-manga reading, exact scene reconstruction or imported anime assets are claimed.
