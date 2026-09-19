# Continuation instructions

Read README.md, docs/STATUS.md, docs/PLAN.md, and the latest entries in docs/WORKLOG.md before changing code. Read docs/RESEARCH.md for canon/source boundaries once present.

The user explicitly authorizes implementation, research, testing, and pushes to https://github.com/aaaditt/demon-slayer-roblox.git. Log every meaningful change/result, commit each coherent checkpoint, and push it. Never commit credentials, downloaded tool binaries, or Studio logs. Record actual test results; never claim Studio playtesting if only compilation ran.

The minimum movie cast is Infinity Castle (2025), confirmed by the user. The intended end state includes all nine Hashira, protagonists, Muzan, Upper/Lower Moons, story locations, PvP, and campaign progression. Do not silently reduce that objective to a prototype. Track remaining production work honestly.

Source of truth for game content is data/catalog.json, generated to src/shared/Content.luau by scripts/generate_content.py. Do not hand-edit generated files. Keep server validation authoritative. Use bounded effect lifetimes and an allowlist for network actions. No external asset may be *required* for basic play: optional uploaded clothing, accessories, sounds and published animations live in data/assets.json and data/animations.json (generated to src/shared/Assets.luau and AnimIds.luau), and every empty ID must fall back to part-built looks, built-in sounds and the code keyframe player. Author sword-kit animations in src/shared/Anims/*.luau; see docs/ASSETS.md. Technique visuals must meet docs/VFX_STANDARD.md.

Run python scripts/check.py after implementation changes; it will validate content, compile Luau, execute core logic tests, and build the Roblox place when tools are installed. Keep docs/STATUS.md and docs/WORKLOG.md current with every commit. Push at each checkpoint unless authentication/network failure prevents it, and record failures.

