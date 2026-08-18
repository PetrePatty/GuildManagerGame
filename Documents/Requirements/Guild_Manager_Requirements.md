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
| 0.5 | 2026-08-13 | Scope reduction to a single static town for V1 (rotating recruitment roster, no travel); introduced the encounter builder and tag system as a first-class V1 feature; reframed the resolution system as a bespoke numerical system (loosely tabletop-inspired, no saving throws); reframed personality traits as reactive/stat-threshold-driven; added quest text presentation requirements (readability, colour-coding, visible calculations); restructured future scope into a V1 / V2 / V3+ roadmap |
| 0.6 | 2026-08-13 | Resolved open questions: no cap on active traits (fully stat-driven); moved persistent antagonist memory from V3+ to V2 (V3+ is multiplayer-only for now); confirmed multiplayer stays in V3+; roster rotation is time-based; V1 quest count means 8 quests unique in main objective, with the encounter builder producing their functional encounters |
| 0.7 | 2026-08-13 | Added the individual & party decision-making system (V2): multi-approach encounter resolution (combat/stealth/social/etc.), with a two-tier decision layer (individual stat-based evaluation vs. party-level social arbitration); clarified V1's decision-making as a simpler precursor to this system |
| 0.8 | 2026-08-13 | Replaced the V2 decision-making draft with the confirmed Party Arbitration Mechanic (appraisal/proposal/adoption/execution); added quest type tag as a 4th quest-generator input alongside length, theme, and difficulty; added the approach database (hand-authored, skill-check-based) and clarified that the generator sets roll difficulty rather than approaches carrying a fixed difficulty |

---

## 1. Concept Overview

A fantasy guild management simulation in which the player runs a single adventuring guild operating out of **one town**: recruiting adventurers from a rotating local roster, negotiating contracts, managing finances and morale, sending parties out on quests assembled by a tag-driven **encounter builder**, and growing the guild's wealth and reputation. The wider world exists as background context in V1 but is not yet traversable or procedurally generated (see Section 9).

**Tone/style direction:** a classic fantasy aesthetic — painterly, atmospheric menus and panels, with fantasy-styled typography rather than a generic or modern management-sim look.

**Design touchstones:** quest/encounter resolution is being designed as a **bespoke numerical system** — its own stats, combat math, and check mechanics — loosely inspired by tabletop RPG frameworks rather than adapted wholesale from an existing one. Notably, there are no saving-throw-equivalent mechanics; only stats. The inter-character relationship system draws inspiration from persistent per-pair opinion systems found in character-driven strategy games. The exhaustion/attrition system draws inspiration from dungeon-crawler roguelites where risk accumulates the longer a party stays in the field. These remain design references only, not technical dependencies. *The full adventurer stat list is still being finalized — see Section 11.*

---

## 2. Vision Statement

The player builds and manages a fantasy adventuring guild over time — recruiting and developing characters, taking on quests, managing finances and logistics, directing and observing the personal stories of guild members, building reputation, and working toward becoming the most powerful guild in the land, all wrapped around a core of engaging questing (**V1**). The longer-term goal is a world that procedurally generates towns and quests, where the player's actions have real, lasting effects and the world reacts in kind (**V2**). Multiplayer — guilds interacting through tournaments, quest-bidding wars, and large-scale world events — is a further-out stretch goal (**V3+**).

*This revision separates "procedural world" (V2) from "multiplayer" (V3+) rather than grouping both as V2, since multiplayer is a substantially larger and more speculative undertaking — confirmed.*

---

## 3. Target Audience

Classic fantasy fans, management/simulation game fans, tabletop RPG (TTRPG) fans, and fans of emergent, character-driven storytelling.

---

## 4. Core Gameplay Loop

The game has two nested loops:

1. **Quest loop (in the field):** a party of adventurers is sent out, works through a series of encounters assembled by the encounter builder, and returns with an outcome (success/failure, rewards, injuries, relationship/morale shifts).
2. **Guild loop (at the town):** the primary "management" layer — recruiting, training, healing, equipping, and negotiating — where most of the player's strategic decisions happen.

**Top-level loop:**

> Find and/or accept an available quest → Execute the quest and receive the outcome/reward → While waiting for the next quest opportunity, improve the guild (recruit from the rotating roster, upgrade facilities, heal/train the roster, negotiate terms) → Repeat.

The guild loop remains the primary design focus for V1, but the quest loop has grown in scope compared to earlier drafts: making questing itself feel fun and varied — via the encounter builder, tag system, and quest text presentation — is now an explicit, co-equal focus rather than something leaned entirely on borrowed frameworks to de-risk.

---

## 5. V1 Scope — Core Pillars

V1 is scoped as a **single-player management sim**, with pillars ranked by priority (most to least important — see Section 12 open item on trimming if scope needs to shrink):

1. **Adventuring guild management** — the guild loop: recruitment, contracts, facilities, finances, roster health.
2. **Custom quest storyteller** — the quest loop: multi-encounter quests resolved via a bespoke, stat-driven system with narrative flavor text, loosely inspired by tabletop RPG frameworks.
3. **Comprehensive fantasy database** — characters, stats, items, quests, enemies, encounter types, challenges, rewards, and the tags that connect them.
4. **Encounter builder** — a tag-driven system that assembles sensible, thematically coherent, appropriately difficult encounters from the database, rather than requiring every encounter to be fully hand-authored.
5. **Static world and town** — the guild exists in a larger world, but for V1 the guild operates from a **single, static town**; the world is not yet procedural or traversable.

### 5.1 Presentation Layer (per feature)

| System | Interface Style |
| --- | --- |
| Town Hub | Graphical (GUI) — a static illustrated view of the guild's home town, not a travel map in V1 |
| Quests | Text-based, with colour-coded formatting (see Section 6.5.6) |
| Everything else (database, finance, team management, contracts, shops, facilities) | Text-based (panel UI) |

**Visual style:** classic fantasy font and panel styling throughout — decorative, immersive UI rather than a generic/modern management-sim look.

---

## 6. Use Cases (V1)

### 6.1 The Guild's Home Town

- **As a player**, I want my guild to operate out of a single, static home town in V1, so that the scope stays achievable while the core loops are being built and tuned.
- **As a player**, I want the town to have its own fixed, hand-authored identity and story, so that it feels like a real place rather than a generic hub.
- **As a player**, I want the town to support recruiting, shopping, and healing, so that it functions as my guild's complete operational base for V1.
- *Note: travel between towns and a procedural/interactive world map are deferred to V2 — see Section 9.*

### 6.2 Recruitment & Rotating Roster

- **As a player**, I want a rotating roster of recruitable adventurers available in my town, so that who I can recruit changes over time rather than being a single static list.
  - The roster rotates based on a set duration of in-world time.
- **As a player**, only adventurers (not support staff) should be recruitable in V1, so that the recruitment system stays scoped to the core roster (support-staff hiring is a V2 feature).
- **As a player**, I want to negotiate a new recruit's salary and contract length, so that building my roster is a real cost/benefit decision.

### 6.3 Guild Facilities

- **As a player**, I want to pay to upgrade support facilities (e.g., training, social, infirmary) that improve my adventurers over time, so that investing in my guild's infrastructure is a core strategic layer.
- **As a player**, I want to use my facilities to make my adventurers better — through training, healing, or building their bonds — so that downtime between quests is productive, not just idle waiting.
  - *Crafting facilities are deferred to V2 (see Section 9); V1 equipment is static — see Section 6.4.*

### 6.4 Shops & Equipment

- **As a player**, I want to buy equipment at my town's shop, so that I have a way to gear up my adventurers.
- **As a player**, I want some equipment to be found as quest rewards, so that quests have loot incentive beyond gold.
  - *Equipment in V1 is static: it can be bought or found, but not crafted or upgraded (crafting is deferred to V2 — see Section 9).*

### 6.5 Quests & Encounter Resolution

#### 6.5.1 Quest Structure

A quest is composed of multiple **encounters**, each with its own difficulty rating:

- **Main encounter** — the core objective of the quest; must be won for the quest to be considered complete.
- **Lead-up encounters** — encountered on the way to the main encounter.
- **Optional side-encounters** — not required, but available.

Side and lead-up encounters:

- Can affect party **morale**.
- Can affect adventurer **HP** (damage) and apply **buffs/debuffs**.
- Grant **XP** for being attempted (more XP if succeeded).
- Grant **reward** (gold/items) if succeeded.

**Win condition:** A quest is completed successfully if the party wins the main encounter with **at least one party member still alive**.

**Quest failure consequences:** the guild loses a moderate amount of **reputation**, and party members may be injured or die (see Section 6.7).

#### 6.5.2 Encounter Categories

Encounters fall into three categories:

- **Combat encounters** — resolved as simplified turn-based combat: standard round-by-round resolution (no graphical battle rendering), with narrative flavor text describing attacks, spells, and outcomes.
- **Non-combat encounters** — skill challenges resolved using core stats; typically attempted by whichever party member is best suited to the check.
- **Character interactions** — small chance encounters between party members that influence the **relationship** stat between them (see Section 6.6).

#### 6.5.3 Encounter Builder & Tag System

- **As a developer/designer**, I want a database of individual encounter building blocks — enemies, encounter types, challenges, and rewards — each tagged with descriptive attributes, so that encounters can be assembled from reusable, well-defined pieces rather than fully hand-written each time.
- **As a player**, I want the encounters I face to make thematic sense for the quest's context (e.g., a quest into a human settlement mostly featuring human enemies), so that the world feels coherent.
- **As a system**, the quest generator assembles a quest from four inputs: **quest length**, **theme tag**, **quest type tag**, and **difficulty rating**. Encounters in the database are tagged for relevance to specific quest types and themes, and the generator selects/matches against those tags when assembling a quest. The tags "theme tag" describes flavor/setting (e.g., undead, bandits, human settlement), while "quest type tag" describes the structural objective (e.g., escort, retrieval, clear-out). Flag if this isn't the intended split.*
- **As a system**, the quest generator also sets the target difficulty for individual rolls within an encounter, scaled from the quest's overall difficulty rating — encounters and approaches don't carry a single fixed difficulty on their own.
- *This tag system also underpins Section 6.11 (thematic and reactive tags more broadly) — this subsection covers its use specifically within the encounter builder.*

#### 6.5.3a Approach Database

- **As a designer**, I want a database of hand-authored approaches for each encounter, so that the party has a defined, curated set of ways to tackle it rather than an open-ended choice.
- Each approach is, mechanically, a **skill check** — unless the encounter is a straight combat encounter, in which case it resolves via the combat rules (Section 6.5.2) instead.
- A skill check's outcome is determined by a combination of **RNG and the stats of the character(s) attempting it** (see Section 6.5.4).

#### 6.5.4 Resolution System

- Success/failure is determined by an RNG roll, heavily modified by character stats, following a **bespoke stat-driven framework** (see Section 1) rather than a direct adaptation of an existing tabletop ruleset. There are no saving-throw-equivalent mechanics — only stats.
- The specific stat list, and exactly how stats modify rolls, is still being finalized and will be incorporated once available (see Section 11).
- This system is dressed with narrative flavor text and inter-party interaction effects to keep quests feeling distinct from one another.

#### 6.5.5 Party Autonomy & Retreat

- **As a player**, I do not directly control party actions during a quest. The party **autonomously decides how to approach each encounter based on personality traits** (see Section 6.6), so outcomes feel emergent rather than player-scripted.
- **As a player**, I want my party to be able to retreat from a quest as an approach option, so that not every dangerous situation ends in death. The decision to retreat is made autonomously by the adventurers themselves, based on their personality traits and current morale — not a direct player choice.
- **As a player**. I want my party to decide how to approach each encounter, based on their personalities and characteristics/stats. The engine to decide this will be called the **Party Arbitration Mechanic**, and is described in a section 6.5.8. This mechanic means the party's actual choice emerges from a weighted-average vote.

#### 6.5.6 Quest Text Presentation

- **As a player**, I want the text describing quest events to be well-articulated and varied, so that questing doesn't feel repetitive over time.
- **As a player**, I want the text feed to use colour-coding to distinguish different kinds of information — e.g., different encounter types, or unusually high-level/dangerous enemies — so that important information is scannable at a glance.
- **As a player**, I want to be able to see the calculations behind a success or failure result, so that outcomes feel transparent and fair rather than arbitrary.

#### 6.5.7 Spectating Quests

- **As a player**, I want frequent text updates as my party progresses through a quest, so I stay engaged with the outcome despite not directly controlling the action.
- Update cadence: **before and after every encounter, after every roll, after every round of combat, and before and after every quest.**

#### 6.5.8 Party Arbitration Mechanic

- **As a player**, I want encounters (main, lead-up, and side) to be solveable through multiple distinct authored approaches — such as sneaking, fighting, or charming — so that how a party gets through a quest varies and feels character-driven.
- **As a player**, I want the approach chosen to determine how the encounter actually resolves — e.g., a successfully snuck-past or talked-down encounter never escalates to combat, while a failed or aggressive approach does — so that combat isn't the only, or default, outcome.
- The party settles on an approach through four phases, run once per encounter:

  1. **Appraisal** — every party member independently evaluates every available approach, estimating their own perceived success chance for each. Accuracy of this estimate is governed by the member's **decision-making** stat (a poor decision-maker's perceived chance may diverge from the true probability). For combat encounters, the appraisal instead estimates the likely battle outcome. The approach with the highest perceived success chance becomes the party member's proposal.
  2. **Proposal** — each party member's generates a proposal: the approach with which he/she has the highest perceived success chance. Each party member proposal's success chance is then modified with his/her leadership and decision-making stats. The resulting success chance becomes the shared perceived success chance for that proposal (i.e. the best perceived approach by that party member). A shared perceived success chance is calculated for each party member for his/her proposal.
  3. **Adoption** — the proposal with the highest shared perceived success chance is adopted by the party.
  4. **Execution** — the party carries out the adopted approach. The relevant character(s) make the required roll (RNG + stats, see Section 6.5.4), further modified by party morale and by "synergy" — which, meaning the established relationship system (Section 6.6.1), not a new stat. How many/which characters contribute to a given approach's roll is defined per-approach in the database, decided case by case rather than by a universal rule.

- This system is a deeper evolution of the V1 engage/retreat decision layer (Section 6.5.5) rather than a separate mechanic, and depends on the finalized adventurer stat list (see Section 11).

### 6.6 Personality Traits & Relationships

Each adventurer's personality traits are **reactive**, emerging automatically from their underlying stats rather than being assigned directly. For example: a character whose Bravery stat exceeds a threshold (e.g., 80) automatically gains the **Brave** trait, with its associated positive and negative effects.

There is no cap on the number of active traits — a character can hold any number of traits at once, depending on how many of their stats have crossed a threshold. Traits can also change over time as stats change (a character could gain or lose a trait mid-game as their stats shift). *The exact thresholds depend on the finalized stat list — see Section 11.*

The traits are as follow:

| Trait | Positive Effect | Negative Effect |
| --- | --- | --- |
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

**Trait exclusion groups (traits within a group cannot be active on one character simultaneously):**

- Greedy / Frugal
- Loyalist / Mercenary
- Bloodthirsty / Peacemaker
- Brave / Cautious / Reckless / Cowardly (max one of the three)

*Note: under the reactive/stat-threshold model, some of these exclusions may resolve naturally (e.g., if Brave and Cautious key off opposite ends of the same stat, a character can never cross both thresholds at once) — this depends on the final stat design and doesn't need to be manually enforced in every case. To be confirmed once the stat list exists.*

#### 6.6.1 Relationship Stat

- A single, persistent **per-pair relationship value** between two characters, starting at 0 and moving up or down over time.
- Influenced by: personality-trait baseline modifiers, and how a character perceives another character's individual successes/failures during encounters.
- Crossing certain positive/negative thresholds applies modifiers to **party morale**.

#### 6.6.2 Party Morale

- A tracked party-wide stat, influenced by quest outcomes, relationship thresholds, and individual trait effects (see table above).
- Morale affects combat/non-combat performance and retreat likelihood for trait-sensitive characters (e.g., Peacemaker, Lone Wolf).

### 6.7 Adventurer Health, Injury, Exhaustion & Death

- **As a player**, I want character death to be permanent, so that risk in quests feels meaningful. Dying outright can occur through situational failed roles whereby the result is death. Furthermore, should the damage dealt to the character in combat be double that of their maximum hp then they will have been slain. Alternatively if the whole party is defeated in combat only a character can perish given their stats.
- **As a player**, I want characters to pass through progressive injury stages before dying (rather than dying outright), so that injuries feel like a warning system rather than instant loss.
- **As a player**, I want injured characters to heal by resting for a set amount of time back at the guild, so that recovery has a real time cost.
- **As a player**, I want adventurers to accumulate **exhaustion** the more encounters (combat and non-combat) they go through on a quest, so that sending a party on back-to-back quests without rest carries real risk.
- **As a player**, I want exhausted or injured adventurers to require downtime at the guild to recover, so that roster management (who's fit to deploy) is an ongoing decision, not a one-time setup.
- **Party size:** up to **5 characters** may be sent on a single quest. World quests may allow up to 8. "Raids" will allow up to 20 (RAID A POSSIBLE IDEA FOR V2).

### 6.8 Finance

- **As a player**, I want to track my guild's income and expenses, so that I can keep the guild financially solvent.
- **As a player**, I want financial state to constrain my decisions (hiring, equipment, travel), so that money management is a real strategic layer.

### 6.9 Progression & Reputation

- **As a player**, I want my guild's reputation to grow based on completed quests and choices, so that I unlock access to better quests, recruits, and shop inventory over time.
- **As a player**, I want quest failure to cost reputation, so that failure has weight beyond just the immediate quest outcome.
  - *In V1, reputation gates what's available within the single town; unlocking access to other towns becomes relevant once travel exists in V2.*

### 6.10 Endgame

- **As a player**, I want the game to end meaningfully rather than continuing indefinitely once my guild is dominant.
- **V1 endgame:** the game ends upon the **retirement of the guild master**, capped at **age 75** or can be initiated early.
- **(V2 direction, not built in V1):** playable races with different natural lifespans, and means for the guild master to unnaturally extend their lifespan — see Section 9.

### 6.11 Tag System (Thematic & Reactive)

Beyond their role in the encounter builder (Section 6.5.3), tags are intended to be a general-purpose association system applied across the game's content:

- **As a designer**, I want every meaningful game element (characters, enemies, items, quests, environments) to carry descriptive tags, so that thematic coherence and cross-references between systems are possible (e.g., matching "human" enemies to "human settlement" quests).
- **As a player**, I want characters to be able to gain tags reactively, based on what happens to them during play — for example, gaining a "fear of zombies" tag after being downed by one — so that the world remembers and reflects what my adventurers have been through.
- **As a player**, I want the possibility of persistent, recurring antagonists who remember prior interactions with specific characters, so that the world feels like it has memory and continuity.

*This rolls out in phases: static/thematic tagging that powers the encounter builder (6.5.3) is V1, since the encounter builder depends on it. Reactive/event-driven character tags and persistent-antagonist memory are both V2 — there is currently no planned V3+ expansion of the tag system beyond this.*

---

## 7. Non-Functional Requirements

- **Save/Load:** the game should support saving and loading guild state (roster, finances, town/quest/reputation progress) between sessions.
- **Performance:** the town hub and panel UI should remain responsive on typical PC hardware; the text simulator should not require heavy real-time computation.
- **Data-driven design:** characters, items, quests, enemies, encounter pieces, and tags should be defined in a way that allows content to be added without code changes, to support the encounter builder and future content growth.
- **Text variety:** the quest narration system should be built to minimize repeated phrasing across quests, per Section 6.5.6.
- **Accessibility consideration:** colour-coded quest text (Section 6.5.6) should be paired with a non-colour indicator (e.g., icon or label) where practical, so the information isn't colour-dependent only.
- **Continue button:** When the button is pressed the game simulates till the next event/instance that requires your attention. Time passes in game when this button is pressed.

---

## 8. V1 Content Scope ("Definition of Done")

A complete V1 (for now) is defined as shipping with:

| Content type | Target quantity |
| --- | --- |
| Towns | 1 |
| Adventurers (recruitable pool feeding the rotating roster) | 8 |
| Quests | 8, each unique in main objective |
| Enemies | 30 |
| Items | 20 |
| Encounter builder | Functional tag-driven system, capable of producing all 8 quests' worth of functional encounters (Section 5, Pillar 4) |

*"8 quests" means 8 quests that are unique in terms of their main objective; the encounter builder is responsible for producing the functional (lead-up/side) encounters that populate each one.*

This is a content floor, not a ceiling — intended to validate that the full guild loop + quest loop is complete and playable end-to-end before expanding content volume.

---

## 9. Version Roadmap

### 9.1 V1 — Single Town, Core Loops

- Everything in Sections 5–8: one static town, rotating recruitment roster, guild facilities, static equipment via shop/quest rewards, the encounter builder and its tag-driven content database, the bespoke resolution system, reactive personality traits, and the age-75 retirement endgame.
- The Quest Generator (QGen), the system that generates quests based on the mentioned parameters.
- Party arbitration mechanic, the four-phase (appraisal/proposal/adoption/execution) system for how the party settles on an approach to an encounter (see Section 6.5.8).

### 9.2 V2 — Expanding the World

- **Multiple towns and travel** between them; the world map becomes interactive.
- **Support staff** as a hireable category separate from adventurers.
- **Scouting** — revealing/vetting recruitment candidates before they're available.
- **Crafting** — creating and upgrading equipment.
- **Deeper logistics** — real mechanics for transport, food/survival, etc.
- **Playable races** with different natural lifespans, and means to unnaturally extend the guild master's lifespan.
- **Reactive/event-driven character tags** (e.g., fear-of-X after a bad encounter).
- **Persistent antagonist memory** — recurring named enemies who remember specific past interactions with characters.
- **Rival-guild roster poaching ("buyout")** — some V1 traits (Mercenary, Loyalist) already reference this; whether it needs active AI rival guilds in V1 or stays dormant until here is open — see Section 11.
- **Procedural world/quest generation**, where the world reacts to the player's actions.
- **Squad tactics** - players can assign party members to be either dps/tank/healer for combat encounters which will influence their choices in combat but not dictate it. Additionally can provide instructions for how the party must act (aggressive, passive, etc.) for out of combat, again it will influence but not dictate their behavior.

### 9.3 V3+ — Stretch Goals

- **World events** — large, occasional events which can allow parties up to 10 characters to interact with. May have multiplayer elements where every guild chooses a stance (help / hinder / do nothing).
- **Multiplayer / shared-world guild interaction**, including:
  - **Guild vs. Guild tournaments** — competing in a shared dungeon or duel format.
  - **Quest bidding** — guilds competing against each other for the same contracts.
  - **Rival-guild roster poaching ("buyout")** — some V1 personality traits (Mercenary, Loyalist) already reference buyout risk/immunity; whether this activates against AI-controlled rival guilds within V1 or stays dormant until V2 is still to be decided (see Section 11).
  - **Limited direct operations** between rival guilds.
  - **Collaborative quests** — guilds working together, not just competing.
  The intent is that two people could eventually run their own guilds in a shared world, crossing paths through tournaments, world events, or quest competition — but this depends on V1 first establishing a working, fun simulation core.

## 9. Post-V1 / Future Vision (V2+)

Explicitly **out of scope for V1**, but worth keeping in mind while architecting V1 systems so they aren't precluded later:

- **Playable races** with different natural lifespans, and mechanisms for the guild master to unnaturally extend their lifespan (extending the endgame beyond the fixed V1 age-75 retirement).
- **Support staff** as a hireable, separate category from adventurers.
- **Scouting** — revealing/vetting recruitment candidates before they're available to recruit (currently the full pool is visible in V1 — see Section 6.3).
- **Crafting** — creating and upgrading equipment (V1 equipment is static — see Section 6.5).
- **Deeper logistics** — real mechanics for transport, food/survival, etc. (V1 logistics are intentionally light).

---

## 10. Risks

| Risk | Notes |
| --- | --- |
| Scope creep toward V2/V3 features | The wider-world and multiplayer vision is compelling and could distract from shipping a solid, fun V1 core. |
| Two-person team bandwidth | Guild management, a bespoke resolution system, and an encounter builder is a substantial scope for two people; pillar priority (Section 5) exists to guide trimming if needed. |
| Bespoke numerical system design & balancing | Building a fully custom stat/combat/check system (rather than adapting an existing framework) is a larger undertaking than originally scoped, and carries real balancing risk — early prototyping and playtesting will matter more than usual here. |
| Encounter builder & content variety | The "non-repetitive, well-articulated" quest text goal depends on having enough tagged content variety and flavor-text templates; underestimating this could make quests feel samey despite the builder's flexibility. |
| Trait/relationship/morale system tuning | A fully custom system (24 traits, per-pair relationships, party morale) will need playtesting to balance; current trait effects are a strong first draft, not final numbers. |

---

## 11. Open Questions / Design Decisions Needed

### V1 — Still Open

- **Adventurer stat list:** Nik finalising the full stat list; several systems (resolution system, reactive traits) depend on it and are placeholders until it's available.
- **Reactive traits:** how do they interact with the resolution system?

### V2 — Needs Confirmation

- **Rival-guild buyout activation:** do the Mercenary/Loyalist buyout effects require active AI-controlled rival guilds, and if so, which phase introduces that?

---

## 12. Milestones (placeholder — dates TBD)

| Milestone | Description |
| --- | --- |
| **M0 — Data model & schema** | Define the character/item/quest/enemy/encounter-piece/tag database structure, including trait, relationship, morale, and exhaustion fields. Depends on the finalized stat list. |
| **M1 — Core loop prototype** | Minimal, possibly non-graphical prototype of the quest simulator and encounter builder (select quest → assemble encounters → resolve → outcome), to validate both the resolution system and the builder before engine work begins. |
| **M2 — Vertical slice** | One full loop in Godot: town hub → quest selection → text-based quest resolution → finance/reputation update → return to town, with placeholder art. |
| **M3 — Alpha** | All V1 pillars implemented at a rough-but-functional level; internal playtesting. |
| **M4 — Beta** | Visual style pass, content population to the Section 8 targets (1 town, 8 adventurers, 8 quests, 30 enemies, 20 items), balancing. |
| **M5 — V1 Release** | Polish, save/load, bug fixing, release build. |

---

## 13. Glossary

- **Guild** — the player's organization of adventurers, managed across finances, roster, and reputation.
- **Encounter** — a discrete challenge within a quest, with its own difficulty rating; categorized as combat, non-combat, or character interaction.
- **Main encounter** — the encounter that determines quest success or failure.
- **Lead-up / side-encounter** — encounters that occur before, or optionally alongside, the main encounter.
- **Encounter builder** — the tag-driven system that assembles encounters from the database based on a quest's length, theme tag, quest type tag, and difficulty rating.
- **Approach** — a distinct, hand-authored method of tackling an encounter (e.g., combat, stealth, social) — see Party Arbitration Mechanic.
- **Party Arbitration Mechanic** — the four-phase system (appraisal, proposal, adoption, execution) by which a party settles on its approach to an encounter: individual stat-based appraisal, weighted-average aggregation into a shared party score, adoption of the highest-scoring approach, and stat-modified execution.
- **Tag** — a descriptive label attached to a game element (character, enemy, item, quest, environment) used to drive thematic coherence and, in later phases, reactive behavior.
- **Party** — the subset of guild members (up to 8) sent on a given quest.
- **Relationship stat** — a persistent per-pair value tracking how one character views another.
- **Morale** — a tracked party-wide stat affecting performance and retreat likelihood.
- **Exhaustion** — accumulated fatigue from encounters that requires downtime to recover.
- **Retirement** — the V1 endgame trigger, occurring when the guild master reaches age 75.

---

## 14. Next Steps

1. Finalize the adventurer stat list (Nik) — this gates the resolution system, reactive trait thresholds, and the M0 data model.
2. Finalize individual panel designs (town hub, character sheet, quest log, finance, contracts, shops, facilities).
3. Define the data model for the comprehensive database (characters, stats, items, quests, enemies, encounter pieces, tags, traits, relationships), incorporating the stat list once available.
4. Prototype the encounter builder and resolution system together (M1), since they're now the highest-risk, highest-focus systems in V1.
5. Resolve the remaining open questions in Section 11 (Cowardly's exclusion group, rival-guild buyout activation timing).
6. Establish the visual style guide (fonts, panel frames, colour palette) — including the colour-coding scheme for quest text (Section 6.5.6).

---

*This document is a living document — revise as remaining open questions get resolved, as panel designs are finalized, and as milestones progress. Update the Document History table with each meaningful revision.*
