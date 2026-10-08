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

## 2026-09-19 Final Selection and return

Read the official [episode 4](https://demonslayer-anime.com/risshihen/story/04.html), [episode 5](https://demonslayer-anime.com/risshihen/story/05.html) and [episode 6](https://demonslayer-anime.com/risshihen/story/06.html) summaries. They establish the seven-day trial at Fujikasane, Tanjiro using his training against demons, a morphed opponent, four candidates present at the closing briefing, uniforms/messengers/ore selection, and departure with the awakened Nezuko in Urokodaki's box. [Bandai Namco's official PROPLICA description](https://www.bandainamco.co.jp/files/ir/newsletter/pdf/BN63.pdf) supports the black finish of Tanjiro's blade as a prop reference, not a scene-timing source.

The thirteen-stage chapter condenses the trial and homecoming. Forest geography, dialogue, patrol timer, selected ore, fixed Water kit, retry protection, the Hand Demon's guarded/recovery windows and its additional-arm posing are original game design. The candidate interaction, guides' individual lines, exact rank/induction blocking, mask details, reunion, Haganezuka acting and defeat memory still require a lawful scene-level audit. The current delivery scene presents the black sword directly; it does not animate the exact color-change sequence. No seven-day real-time simulation, full manga ingestion or frame-exact anime reconstruction is claimed.

For stationary story actors, the [Humanoid API's EvaluateStateMachine property](https://create.roblox.com/docs/reference/engine/classes/Humanoid#EvaluateStateMachine) is disabled so script-driven posing and explicit collision settings govern the rig. Combatants retain normal humanoid simulation. This was investigated after a real client strike was admitted during boss recovery but failed its line-of-sight check near the hidden cinematic double.

## 2026-09-29 first assignment audit

Read official [episode 6](https://demonslayer-anime.com/risshihen/story/06.html), [episode 7](https://demonslayer-anime.com/risshihen/story/07.html) and [episode 8](https://demonslayer-anime.com/risshihen/story/08.html) summaries. They support the northwest town assignment, Kazumi's missing girlfriend, Tanjiro detecting the demon's scent, three bodies, Nezuko intervening, pursuit into the swamp and the subsequent Asakusa assignment. The Japanese episode 7 synopsis gives the same broad sequence. Search-index excerpts from the community [Kazumi synopsis](https://kimetsu-no-yaiba.fandom.com/wiki/Kazumi) support the rescued young woman, the lost fiancée and keepsakes; this is secondary evidence, not a primary scene review.

Chapter four uses original dialogue, lantern streets, an open rescue house, marked investigation stops and a walkable separate swamp space. It condenses the rescue and grief without graphic remains. Submerged invulnerability, sequential pool attacks, survival/hit requirements, recovery openings, nonlethal player retries and the ally lunge are game mechanics. The swamp does not implement underwater swimming or oxygen; it does not reproduce exact geography, costumes, horn/body assignments, dialogue or canon combat choreography. The returned keepsake and farewell are condensed staging. A primary scene-level audit, the demon's fear of Muzan, full interrogation and authored rescue/fight animation remain production work. No anime footage, extracted assets or full manga ingestion was used.

## 2026-09-29 nichirin sword fittings

- Tanjiro's black blade was already sourced (`nichirin_proplica`, Bandai Namco primary merchandise reference).
- The fandom Nichirin Sword page returned HTTP 402 and was not read. Secondary editorial and retail guides (`sword_guides`) agree on:
  - Giyu: deep blue blade, hexagonal bronze tsuba
  - Rengoku: red blade, flame tsuba
  - Kanao: pink blade, flower-petal tsuba
  - Tanjiro: green four-point "wheel" tsuba
- These four are the only character overrides in `data/catalog.json`. They are blocky approximations, not likeness-accurate fittings.
- All other sword users get the original `nichirin_base` preset until their fittings are sourced from primary material.
- Tanjiro's later tsuba change (story-dependent) is not modelled yet.

## 2026-09-30 Asakusa first-pass audit

Read the official [episode 8](https://demonslayer-anime.com/risshihen/story/08.html), [episode 9](https://demonslayer-anime.com/risshihen/story/09.html) and [episode 10](https://demonslayer-anime.com/risshihen/story/10.html) summaries. They support the urban Asakusa setting, Tanjiro following Muzan's scent, a civilian transformation causing a diversion, Tamayo/Yushiro's assistance, the concealed house, discussion of a possible cure, the two pursuers' attack and Tamayo intervening during the fight. These are primary synopsis sources, not a scene-level manga/anime audit.

The 15-stage chapter is a condensed original adaptation. Street/stall architecture, garden/clinic layout, dialogue, four timed nonlethal bracing inputs, spell colors, camera positions, fight order, hit/time requirements and protected retries are game design. The story preserves civilian survival and gives Susamaru a nonlethal gameplay phase before Tamayo's result scene. Her exact curse/death sequence, Yahaba's forced trajectory mechanics, simultaneous split combat, Nezuko's regeneration/temari choreography, blood-collection details, costumes and scene-accurate acting are unfinished. The Arrow/Temari encounters use the existing shared technique primitives; they are not new canonical boss simulations. Transitioning to dawn and the next route is a condensed gameplay ending. No whole-manga reading or frame-exact reconstruction is claimed; no extracted anime assets were used.


## 2026-10-05 dash ownership and validation

Reviewed official [network ownership documentation](https://create.roblox.com/docs/physics/network-ownership) and the [LinearVelocity API](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity). Roblox documents both possible server-owned physics jitter and the lack of engine verification for client-owned physics. Isolated tests showed that removing the root rotation write or adding an ownership delay did not eliminate catch-up; retaining player ownership produced even movement but required server reconciliation of delayed positions.

The current implementation therefore retains client simulation only for player movement with server-created constraints, independently validating its path, speed, reach, jump/fall bounds and swept collision before gameplay actions/damage. Clients supply no trusted timings or limits. The server corrects violations, cancels the movement/action token and bounds endpoint receipt to 0.5 s beyond the movement duration. That grace is an original implementation choice, not a Roblox guarantee or an extension of dodge reach/i-frames. NPC movement stays server-simulated. This supersedes the older universal server-ownership approach described in the September 17 research entry; it does not claim full exploit or arbitrary-latency qualification.

## 2026-10-08 Tsuzumi Mansion first pass

Read the official [episode 11](https://demonslayer-anime.com/risshihen/story/11.html), [episode 12](https://demonslayer-anime.com/risshihen/story/12.html), [episode 13](https://demonslayer-anime.com/risshihen/story/13.html) and [episode 14](https://demonslayer-anime.com/risshihen/story/14.html) summaries. They establish meeting Zenitsu on the road, the children whose brother was taken, drum-driven room changes and separation, Zenitsu protecting Shoichi, the boar-mask swordsman, injured Tanjiro fighting Kyogai, and the aftermath with Zenitsu protecting Nezuko's box. Episode 14's title establishes the wisteria-crest rest house. These summaries are not a scene-level audit; the younger sister and older brother remain generically named here.

The sixteen-stage chapter uses original dialogue, cameras, procedural geography and brief parallel-fight cutaways. Horizontal quarter-turns, anchored player transport during each turn, three marked claw lanes, protected boss phases, attack openings, health-floor retries and the fixed Water kit are original game rules. The room does not invert gravity or reproduce the anime's full room-rearrangement choreography. Zenitsu/Inosuke's cutaways use shared dash/barrage poses and short effects, not player-controlled battles or exact Thunder/Beast choreography. The outside quarrel and recovery are condensed non-graphic staging. Exact costumes, manuscript/backstory details, fight choreography, gravity-axis changes, facial acting and a lawful scene-level audit remain production work. No copied dialogue, anime media or extracted commercial assets were used.
