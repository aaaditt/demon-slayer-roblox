# Technique VFX and animation standard

Recorded 2026-09-19 at the owner's request. **Hard requirement for all technique work.**

Current state is not acceptable for release: techniques are shown as small circles/parts in a line and generic arcs. Every breathing form and Blood Demon Art must look like it does in the anime (ufotable TV series) and the theatrical films (Mugen Train, Infinity Castle), as if made by a professional VFX artist and animator:

- **Full-body choreography** per form: anticipation, the actual swing path from the anime, follow-through, recovery. No shared generic swing.
- **Signature visual language per style**: e.g. Water Breathing's ukiyo-e water ribbons and foam following the blade; Hinokami Kagura/Flame's fire ribbons; Thunder's lightning afterimages; Beast's jagged double-blade tears.
- **Layered VFX**: blade trail + primary shape (water dragon, wave, whirlpool) + secondary particles (spray, embers, sparks) + ground/impact decal + screen flash/shake where the anime has one.
- **Camera and timing**: hit-stop and speed ramps where the anime has impact frames.
- Reference frames for each form must be listed in the form's record (episode/timestamp or film scene) before implementation, and the result compared side by side in review.
- Performance: bounded lifetimes and particle budgets stay mandatory (see AGENTS.md).

First target: Tanjiro's Water Breathing forms, after the Tanjiro combat slice (`docs/superpowers/specs/2026-09-19-tanjiro-combat-design.md`).
