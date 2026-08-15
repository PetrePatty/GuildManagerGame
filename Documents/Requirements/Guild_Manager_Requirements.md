# Guild Manager — Requirements & Use Case Document

| | |
| --- | --- |
| **Project** | Guild Manager (working title) |
| **Document type** | Requirements & Use Case Document |
| **Genre** | Fantasy management simulation |
| **Platform (V1)** | PC |
| **Engine** | Godot |
| **Team** | Nik Uys, Petré van der Merwe |
| **Status** | Draft |

## Document History

| Version | Date | Summary of changes |
| --- | --- | --- |
| 0.1 | 2026-08-04 | Initial draft — concept, V1 pillars, use cases, V2 vision, open questions |
| 0.2 | 2026-08-05 | Added quest structure (encounters, win condition), personality-driven resolution, and spectator-style quest updates |
| 0.3 | 2026-08-06 | Restructured to standard requirements-doc format (metadata, changelog, target audience, glossary, risks, milestones); removed references to third-party games/products |
| 0.4 | 2026-08-10 | Full content pass: core gameplay loop, reprioritized pillars, encounter resolution system, personality trait catalog, relationship/morale system, exhaustion/injury/death system, endgame, towns/shops/recruitment, V1 content scope, updated V2 vision, trimmed open questions |

---

## 1. Concept Overview

A fantasy guild management simulation in which the player runs an adventuring guild rather than a sports team or army: recruiting adventurers, negotiating contracts, managing finances and morale, sending parties out on quests, and growing the guild's wealth and reputation while moving between towns on a procedural world map.

**Tone/style direction:** A classic fantasy aesthetic — atmospheric menus and panels, with fantasy-styled typography rather than a modern management-sim look.

**Design touchstones:** Quest/encounter resolution draws inspiration from tabletop RPG encounter-balancing frameworks (turn-based combat resolution, ability-score-driven skill checks); the inter-character relationship system draws inspiration from persistent per-pair opinion systems found in character-driven strategy games; the exhaustion/attrition system draws inspiration from dungeon-crawler roguelites where risk accumulates the longer a party stays in the field. These are design references only, not technical dependencies.

---

## 2. Vision Statement

The player builds and manages a fantasy adventuring guild over time — recruiting and developing characters, taking on quests, managing finances and logistics, directing and observing the stories of the guild members, building reputation, and shaping the story of the world they live in (V1). The long-term goal is to add multiplayer - guilds interacting with each other through shared-world features like tournaments, bidding wars over quests, and large-scale world events (V2).

---

## 3. Target Audience

Classic fantasy fans, management/simulation game fans, tabletop RPG (TTRPG) fans, and fans of emergent, character-driven storytelling.

---

## 4. Core Gameplay Loop

The game has two nested loops:

1. **Quest loop (in the field):** a party of adventurers is sent out, works through a series of encounters, and returns with an outcome (success/failure, rewards, injuries, relationship/morale shifts).
2. **Guild loop (between quests):** the primary "management" layer — recruiting, training, healing, equipping, and negotiating — where most of the player's strategic decisions happen.

**Top-level loop:**

> Find and/or accept an available quest → Execute the quest and receive the outcome/reward → While waiting for the next quest opportunity, improve the guild (recruit better adventurers, upgrade facilities, heal/train the roster, negotiate terms) → Repeat.

The guild loop is considered the primary design focus for V1; the quest/encounter loop is intentionally scoped to lean on existing, well-understood resolution frameworks (see Section 6.6) rather than being designed from scratch, so that development effort concentrates on the guild-management layer.

---

## 5. V1 Scope — Core Pillars

V1 is scoped as a **single-player management sim**, with pillars ranked by priority (most to least important — see Section 11 open item on trimming if scope needs to shrink):

1. **Adventuring guild management** — the guild loop: recruitment, contracts, facilities, finances, roster health.
2. **TTRPG-style quest storyteller** — the quest loop: multi-encounter quests resolved via an RNG/stat-driven system with narrative flavor text. Delivered as a text-based simulator for V1, but conceptually a "storyteller" system rather than strictly a text-only feature.
3. **Comprehensive fantasy database** — characters, stats, items, quests, and enemies.
4. **Randomised, procedural, and interactive world** — the world map and town network.
5. **Generative encounter-creation tool** — a system/tool to help construct sensible, balanced encounters rather than requiring every encounter to be fully hand-authored.

### 5.1 Presentation Layer (per feature)

| System | Interface Style |
| --- | --- |
| World Map | Graphical (GUI) |
| Quests | Text-based |
| Everything else (database, finance, team management, contracts, shops, facilities) | Text-based (panel UI) |

**Visual style:** classic fantasy font and panel styling throughout — decorative, immersive UI rather than a generic/modern management-sim look.

---

## 6. Use Cases (V1)

### 6.1 World Map & Travel

- **As a player**, I want to move my guild between towns on a procedural world map, so that I can explore new opportunities and expand my reputation.
- **As a player**, I want my choice of location to affect the quests, prices, and reputation available to me, so that travel is a meaningful strategic decision.

### 6.2 Towns

- **As a player**, I want towns to support recruiting, shopping, and healing, so that towns function as my guild's operational hubs.
- **As a player**, I want some towns to have specialties (e.g., better recruits of a certain type, better prices on certain goods), so that where I travel is a meaningful choice.
- **As a player**, I want larger towns to have their own fixed, hand-authored storyline (not randomly generated), so that key locations feel distinct and memorable rather than procedurally generic.

### 6.3 Recruitment & Contracts

- **As a player**, I want to see a pool of recruitable adventurers available in the town I'm currently in, so that I can decide who to bring into my guild.
  - *Note: candidate pool is fully visible while in a town (no scouting/fog-of-war in V1 — see Section 9, Scouting is deferred to V2).*
  - *Open sub-question: whether the pool itself is randomly generated per visit or drawn from a set/curated list — see Section 11.*
- **As a player**, only adventurers (not support staff) should be recruitable in V1, so that the recruitment system stays scoped to the core roster (support-staff hiring is a V2 feature).
- **As a player**, I want to negotiate a new recruit's salary and contract length, so that building my roster is a real cost/benefit decision.

### 6.4 Guild Facilities

- **As a player**, I want to pay to upgrade support facilities (e.g., training, social, infirmary) that improve my adventurers over time, so that investing in my guild's infrastructure is a core strategic layer.
  - *Crafting facilities are deferred to V2 (see Section 9); V1 equipment is static — see Section 6.10.*
- **As a player**, I want to use my facilities to make my adventurers better, whether that be through training, healing, or building their bonds.

### 6.5 Shops & Equipment

- **As a player**, I want to buy equipment at town shops, so that I have a way to gear up my adventurers.
- **As a player**, I want some equipment to be found as quest rewards, so that quests have loot incentive beyond gold.
  - *Equipment in V1 is static: it can be bought or found, but not crafted or upgraded (crafting is deferred to V2 — see Section 9).*

### 6.6 Quests & Encounter Resolution

#### 6.6.1 Quest Structure

A quest is composed of multiple **encounters**, each with its own difficulty rating, balanced using a tabletop-style encounter-balancing framework:

- **Main encounter** — the core objective of the quest; must be won for the quest to be considered complete.
- **Lead-up encounters** — encountered on the way to the main encounter.
- **Optional side-encounters** — not required, but available.

Side and lead-up encounters:

- Can affect party **morale**.
- Can affect adventurer **HP** (damage) and apply **buffs/debuffs**.
- Grant **XP** for being attempted (more XP if succeeded).
- Grant **reward** (gold/items) if succeeded.

**Win condition:** A quest is completed successfully if the party wins the main encounter with **at least one party member still alive**.

**Quest failure consequences:** the guild loses a moderate amount of **reputation**, and party members may be injured or die (see Section 6.8).

#### 6.6.2 Encounter Categories
Encounters fall into three categories:

- **Combat encounters** — resolved as simplified turn-based combat: standard round-by-round resolution (no graphical battle rendering), with narrative flavor text describing attacks, spells, and outcomes.
- **Non-combat encounters** — skill challenges resolved using core ability scores; typically attempted by whichever party member is best suited to the check.
- **Character interactions** — small chance encounters between party members that influence the **relationship** stat between them (see Section 6.7).

#### 6.6.3 Resolution System
- Success/failure is determined by an RNG roll, heavily modified by character stats — following a tabletop-RPG-style modified-roll framework, dressed with narrative flavor text and inter-party interaction effects.
- This system is intentionally scoped to lean on a well-understood, pre-existing style of resolution mechanics rather than being designed from scratch, so V1 development effort can focus on the guild-management layer (see Section 4).

#### 6.6.4 Party Autonomy & Retreat
- **As a player**, I do not directly control party actions during a quest. The party **autonomously decides how to approach each encounter based on personality traits** (see Section 6.7), so outcomes feel emergent rather than player-scripted.
- **As a player**, I want my party to be able to retreat from a quest, so that not every dangerous situation ends in death. The decision to retreat is made autonomously by the adventurers themselves, based on their personality traits and current morale — not a direct player choice.

#### 6.6.5 Spectating Quests
- **As a player**, I want frequent text updates as my party progresses through a quest, so I stay engaged with the outcome despite not directly controlling the action.
- Update cadence: **before and after every encounter, after every roll, after every round of combat, and before and after every quest.**

### 6.7 Personality Traits & Relationships

Each adventurer has may have traits which must not be mutually contradictory (see exclusion groups below). Some traits have positive bonuses whilst others negative.

| Trait | Positive Effect | Negative Effect |
|---|---|---|
| **Greedy** | All rolls get a bonus when quest monetary reward is high | Demands a higher salary; will never ignore side-encounters with monetary reward |
| **Frugal** | Accepts lower salary in negotiation | Suffers morale loss if guild treasury drops below a certain amount |
| **Mercenary** | Combat bonus on all quests | Highly prone to buyout by other in-game guilds |
| **Loyalist** | Immune to buyout by other guilds + small general morale bonus | Expects a long contract length |
| **Fame-Seeker** | +25% additional Guild Reputation upon returning from successful quests | More likely to push into optional side-encounters |
| **Fickle** | Bigger morale bonus from positive outcomes | Bigger morale decrease from negative outcomes |
| **Natural Leader** | Passive morale bonus to the whole party | Larger party-wide morale hit if this character is injured or dies |
| **Abrasive** | Bonus on intimidation/aggressive-flavored non-combat checks | Passive relationship decay with other party members over time |
| **Mentor** | Passive training-speed bonus to lower-level party members | Relationship friction with peers of similar or higher skill |
| **Lone Wolf** | Stat bonus when deployed in smaller parties | Party morale decrease when in a large party |
| **Inspirational** | Passive morale regeneration for the party | Larger party-wide morale crash if this character is injured or dies |
| **Peacemaker** | Dampens negative relationship swings between other party members | -10% personal damage output when overall party morale drops below 50% |
| **Stoic** | Greatly reduced negative morale swings | Reduced positive morale swings |
| **Pack Rat** | Bonus to loot and quest rewards in all encounters | Higher salary in general |
| **Cowardly** | Much higher chance of surviving injuries | More prone to retreat |
| **Iron Constitution** | Reduced injury severity in combat | More likely to resist retreating, even past the point of good judgment |
| **Workaholic** | Faster XP gain for the adventurer overall | Morale decays if left idle without a quest too long |
| **Brave** | Combat bonus against high-difficulty encounters | Resists retreating even when it's the wise choice |
| **Cautious** | More likely to retreat before a fight turns fatal | Less likely to engage optional side-encounters |
| **Reckless** | Combat bonus on aggressive/first-strike actions | Resists retreating, raising injury/death risk |
| **Scholar** | Bonus on knowledge/lore-flavored non-combat checks | Combat penalty |
| **Bloodthirsty** | Combat bonus | Refuses to retreat from combat encounters |
| **Pragmatist** | Favours the "correct" choice in all encounters | Morale debuff when the party makes a non-optimal choice |
| **Superstitious** | Better at avoiding unusually dangerous side-encounters | Morale penalty following "bad omen"-flavored events |
| **Claustrophobic** | Bonus in open/outdoor encounters | Penalty in enclosed environments (dungeons, caves) |

(examples)

**Trait exclusion groups (traits within a group cannot be combined on one character):**
- Greedy / Frugal
- Loyalist / Mercenary
- Bloodthirsty / Peacemaker
- Reckless / Survivalist-type caution *(see Section 11 — Cowardly's exclusion-group membership still to be confirmed)*
- Brave / Cautious / Reckless (max one of the three)

#### 6.7.1 Relationship Stat
- A single, persistent **per-pair relationship value** between two characters, starting at 0 and moving up or down over time.
- Influenced by: personality-trait baseline modifiers, and how a character perceives another character's individual successes/failures during encounters.
- Crossing certain positive/negative thresholds applies modifiers to **party morale**.
- Having a positive link with a character will provide a bonus when the interact in a quest.
- Whilst having a negative link between characters will make them suffer a debuff when interacting.

#### 6.7.2 Party Morale
- A tracked party-wide stat, influenced by quest outcomes, relationship thresholds, and individual trait effects (see table above).
- Morale affects combat/non-combat performance and retreat likelihood. Additionally it can lead to party members wanting to leave the guild.

### 6.8 Adventurer Health, Injury, Exhaustion & Death
- **As a player**, I want character death to be permanent, so that risk in quests feels meaningful. Dying outright can occur through situational failed roles whereby the result is death. Furthermore, should the damage dealt to the character in combat be double that of their maximum hp then they will have been slain. Alternatively if the whole party is defeated in combat only a character can perish given their stats.
- **As a player**, I want characters to pass through progressive injury stages before dying from combat losses (rather than dying outright), so that injuries feel like a warning system rather than instant loss.
- **As a player**, I want injured characters to heal by resting for a set amount of time back at the guild, so that recovery has a real time cost.
- **As a player**, I want adventurers to accumulate **exhaustion** the more encounters (combat and non-combat) they go through on a quest, so that sending a party on back-to-back quests without rest carries real risk (attrition-based risk, in the style of dungeon-crawler roguelites).
- **As a player**, I want exhausted or injured adventurers to require downtime at the guild to recover, so that roster management (who's fit to deploy) is an ongoing decision, not a one-time setup.
- **Party size:** up to **5 characters** may be sent on a single quest. World quests may allow up to 8. "Raids" will allow up to 20 (RAID A POSSIBLE IDEA FOR V2).

### 6.9 Finance
- **As a player**, I want to track my guild's income and expenses, so that I can keep the guild financially solvent.
- **As a player**, I want financial state to constrain my decisions (hiring, equipment, travel), so that money management is a real strategic layer.

### 6.10 Progression & Reputation
- **As a player**, I want my guild's reputation to grow based on completed quests and choices, so that I unlock access to access to other towns, quests, and become more appealing for adventurers to join over time.
- **As a player**, I want quest failure to cost reputation, so that failure has weight beyond just the immediate quest outcome.

### 6.11 Endgame
- **As a player**, I want the game to end meaningfully rather than continuing indefinitely once my guild is dominant.
- **V1 endgame:** the game ends upon the **retirement of the guild master**, capped at **age 75** or can be initiated early.
- **(V2 direction, not built in V1):** playable races with different natural lifespans, and means for the guild master to unnaturally extend their lifespan — see Section 9.

---

## 7. Non-Functional Requirements

- **Save/Load:** the game should support saving and loading guild state (roster, finances, world position, quest/reputation progress) between sessions.
- **Performance:** world map and panel UI should remain responsive on typical PC hardware; the text simulator should not require heavy real-time computation.
- **Data-driven design:** characters, items, quests, and enemies should be defined in a way that allows content (new quests, items, enemies) to be added without code changes, to support future content growth and V2 features.
- **Continue button:** When the button is pressed the game simulates till the next event/instance that requires your attention. Time passes in game when this button is pressed.

---

## 8. V1 Content Scope ("Definition of Done")

A complete V1 (for now) is defined as shipping with:

| Content type | Target quantity |
|---|---|
| Towns | 1 |
| Adventurers (recruitable pool, total) | 8 |
| Quests | 8 |
| Enemies | 30 |
| Items | 20 |
| Encounter-creation tool | A generative tool for constructing sensible, balanced encounters (Section 5, Pillar 5) |

This is a content floor, not a ceiling — intended to validate that the full guild loop + quest loop is complete and playable end-to-end before expanding content volume.

---

## 9. Post-V1 / Future Vision (V2+)

Explicitly **out of scope for V1**, but worth keeping in mind while architecting V1 systems so they aren't precluded later:

- **Playable races** with different natural lifespans, and mechanisms for the guild master to unnaturally extend their lifespan (extending the endgame beyond the fixed V1 age-75 retirement).
- **Support staff** as a hireable, separate category from adventurers.
- **Scouting** — revealing/vetting recruitment candidates before they're available to recruit (currently the full pool is visible in V1 — see Section 6.3).
- **Crafting** — creating and upgrading equipment (V1 equipment is static — see Section 6.5).
- **Deeper logistics** — real mechanics for transport, food/survival, etc. (V1 logistics are intentionally light).
- **Squad tactics** - players can assign party members to be either dps/tank/healer for combat encounters which will influence their choices in combat but not dictate it. Additionally can provide instructions for how the party must act (aggressive, passive, etc.) for out of combat, again it will influence but not dictate their behavior. 
- **Combat/encounter simulator** as a deeper standalone system.
- **World events** — large, occasional events which can allow parties up to 10 characters to interact with. May have multiplayer elements where every guild chooses a stance (help / hinder / do nothing).
- **Multiplayer / shared-world guild interaction**, including:
  - **Guild vs. Guild tournaments** — competing in a shared dungeon or duel format.
  - **Quest bidding** — guilds competing against each other for the same contracts.
  - **Rival-guild roster poaching ("buyout")** — some V1 personality traits (Mercenary, Loyalist) already reference buyout risk/immunity; whether this activates against AI-controlled rival guilds within V1 or stays dormant until V2 is still to be decided (see Section 11).
  - **Limited direct operations** between rival guilds.
  - **Collaborative quests** — guilds working together, not just competing.

The intent is that two friends could eventually run their own guilds in a shared world, crossing paths through tournaments, world events, or quest competition — but this depends on V1 first establishing a working simulation core.

---

## 10. Risks

| Risk | Notes |
|---|---|
| Scope creep toward V2 features | The multiplayer/tournament vision is compelling and could distract from shipping a solid V1 core loop. |
| Two-person team bandwidth | Guild management, quest resolution, and a generative encounter tool is a substantial scope for two people; pillar priority (Section 5) exists to guide trimming if needed. |
| Encounter resolution complexity | The team has deliberately chosen to lean on an existing tabletop-style resolution framework rather than design one from scratch, specifically to manage this risk — but tuning/balancing still requires real effort. |
| Trait/relationship/morale system tuning | A fully custom system (24 traits, per-pair relationships, party morale) will need playtesting to balance; current trait effects are a strong first draft, not final numbers. |

---

## 11. Open Questions / Design Decisions Needed

### V1 — Still Open
- **Recruitment pool generation:** is the town candidate pool randomly generated per visit, or drawn from a set/curated list? - I think it should be generated upon first visit then overtime the pool empties and refreshes.
- **Rival-guild buyout activation:** do the Mercenary/Loyalist buyout effects require active AI-controlled rival guilds in V1, or do they stay dormant until guild rivalry ships in V2?
- **Cowardly's exclusion group:** should Cowardly join the Brave/Cautious/Reckless exclusion group (i.e., become a 4-way "max one" group), given its "more prone to retreat" effect echoes Cautious?
- **Claustrophobic's environment tag:** Claustrophobic requires encounters to be tagged indoor/enclosed vs. outdoor/open — no other system currently requires this. Confirm whether this tag gets added to the V1 encounter data model, or the trait is adjusted to not require it.

### V2 — Deferred (revisit after V1 is underway/complete)
- **Guild interactivity shape:** how much direct interaction vs. indirect/asynchronous competition (bidding, world events) between guilds?
- **Multiplayer architecture direction:** real-time, server-based, or asynchronous/turn-based interaction between guilds?
- **Quest bidding mechanics:** how does competing for the same quest against another guild actually resolve?
- **World event structure:** how often do these occur, and how are simultaneous player choices (help/hinder/nothing) reconciled into one outcome?

---

## 12. Milestones (placeholder — dates TBD)

| Milestone | Description |
|---|---|
| **M0 — Data model & schema** | Define the character/item/quest/enemy database structure, including trait, relationship, morale, and exhaustion fields. |
| **M1 — Core loop prototype** | Minimal, possibly non-graphical prototype of the quest simulator (select quest → resolve encounters → outcome), to validate the loop is engaging before engine work begins. |
| **M2 — Vertical slice** | One full loop in Godot: world map → quest selection → text-based quest resolution → finance/reputation update → return to map, with placeholder art. |
| **M3 — Alpha** | All V1 pillars implemented at a rough-but-functional level; internal playtesting. |
| **M4 — Beta** | Visual style pass, content population to the Section 8 targets (2 towns, generative adventurers, 8 quests, 30 enemies, 20 items), balancing. |
| **M5 — V1 Release** | Polish, save/load, bug fixing, release build. |

---

## 13. Glossary

- **Guild** — the player's organization of adventurers, managed across finances, roster, and reputation.
- **Encounter** — a discrete challenge within a quest, with its own difficulty rating; categorized as combat, non-combat, or character interaction.
- **Main encounter** — the encounter that determines quest success or failure.
- **Lead-up / side-encounter** — encounters that occur before, or optionally alongside, the main encounter.
- **Party** — the subset of guild members (up to 8) sent on a given quest.
- **Relationship stat** — a persistent per-pair value tracking how one character views another.
- **Morale** — a tracked party-wide stat affecting performance and retreat likelihood.
- **Exhaustion** — accumulated fatigue from encounters that requires downtime to recover.
- **Retirement** — the V1 endgame trigger, occurring when the guild master reaches age 75.

---

## 14. Next Steps

1. Finalize individual panel designs (world map, character sheet, quest log, finance, contracts, shops, facilities) — noted as already in progress.
2. Define the data model for the comprehensive database (characters, stats, items, quests, enemies, traits, relationships) so V1 systems and future V2 multiplayer features share the same schema.
3. Prototype the quest/encounter resolution system as the core quest-loop mechanic (M1), since it gates the vertical slice.
4. Resolve the remaining V1 open questions in Section 11, particularly recruitment pool generation and the encounter environment tag, since both affect the data model (M0).
5. Establish the visual style guide (fonts, panel frames, color palette).

---

*This document is a living document — revise as remaining open questions get resolved, as panel designs are finalized, and as milestones progress. Update the Document History table with each meaningful revision.*
