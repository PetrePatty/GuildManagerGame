# README

Game        - The actual Godot project. Everything Godot needs to open and run lives here — this is the folder to point Godot's project manager at.
Content     - The source-of-truth game data as JSON/CSV — adventurers, quests, encounters, items, enemies, traits. Databases to be edited by hand here.
Databases   - The pipeline that turns content/ into the actual SQLite database — the schema definition and the build script.
Documents   - Design docs (like the requirements doc) and data-schema notes. Non-code.
Tools       - Any dev-side tooling that is build.