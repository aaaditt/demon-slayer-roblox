# Roblox deployment

The owner authorized creating a **new** Roblox experience. Studio confirmed successful publication on 2026-09-15 at 19:38 UTC (23:38 Dubai).

- Name: **Demon Slayer: Wisteria Chronicles**
- [Experience page](https://www.roblox.com/games/139004028759819)
- [Creator Dashboard](https://create.roblox.com/dashboard/creations/experiences/10766590718/overview)
- Universe ID: `10766590718`
- Start place ID: `139004028759819`
- Audience: **Private**, confirmed by the Studio success dialog.
- Enabled devices: computer, phone, tablet. VR and console are disabled pending device QA.
- Team Create and experience data sharing were turned off at creation.
- Machine-readable target: [deploy/roblox.json](../deploy/roblox.json).

This is the development build described in STATUS.md, with procedural assets and shared move patterns. Publication does not mark the full production game complete.

## Access and live testing

Unauthenticated Roblox playability returned `ContextualPlayabilityUnrated` and `isPlayable: false`. General online play, live saves, and cross-computer multiplayer have **not** passed verification. Public release requires the account's applicable eligibility and content-maturity settings in Creator Dashboard. Current Roblox requirements are documented in [publishing games](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

On 2026-09-16, **View on Creator Hub** opened the Roblox login screen in Chrome. The signed-in Studio account is sufficient to upload, but the browser needs the owner to sign in before dashboard release settings can be reviewed. An asynchronous sign-in request is pending; no credentials were requested or copied.

## Updating this experience

1. Read STATUS.md and the latest WORKLOG.md entries; use the target IDs above. Do not create another universe for an update.
2. Run `python scripts/check.py` and the appropriate Studio tests.
3. Open the fresh `build/WisteriaChronicles.rbxlx`. Keep Rojo disconnected from unrelated local projects. Verify `ReplicatedStorage.Shared.Content` contains the Wisteria character catalog.
4. Use **File → Publish to Roblox As** to select this exact experience and start place; review the target before overwriting it. For an already opened cloud place, ordinary **Publish to Roblox** updates that place.
5. Verify the success dialog and game IDs, test access/save behavior, then update this document, STATUS.md, and WORKLOG.md; commit and push.

Do not upload a test-injected place. The generated multiplayer runner modifies a temporary test copy only. Never store account cookies, authentication tickets, or Studio logs in Git.

## 2026-09-17 downloadable revision (cloud unchanged)

The new [v0.2.0-dev.1 development release](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.2.0-dev.1) contains the Kamado prologue and movement/sword revision at source `68d3421`. Its place and checksum are uploaded to GitHub, and the source build passed GitHub Actions. Open that file in Studio to review Journey -> 01 A Trail in the Snow.

No Roblox cloud upload or audience change was performed for this revision. The experience linked above still has the earlier published build. Updating it remains a separate deployment step using the exact existing place/universe IDs and the production place, never a test-injected copy.
