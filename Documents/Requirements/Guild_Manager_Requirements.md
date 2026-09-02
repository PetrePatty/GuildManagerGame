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
| 0.9 | 2026-08-14 | Cleanup pass: removed leftover duplicate "Section 9" content; confirmed Party Arbitration Mechanic + Approach Database as deliberate V1 scope (accepted risk); unified party size to 5, folded "world quests" into "world events" (V2) with raids as their V3+ form; confirmed the Proposal phase never merges/averages duplicate proposals; fixed 6.5.1/6.5.3 difficulty-rating inconsistency, the trait exclusion group count, a stray formatting artifact in 6.5.3, and removed the redundant duplicate phase description in 6.5.8 |
| 0.10 | 2026-08-14 | Added the full Resolution System (3d6+modifiers, dual-track Ability Contribution/Proficiency Tier/Item-bonus modifiers, DC/AC baseline, crit rules); added the Combat System (turn-based, symmetric per-combatant aggro, four combat roles with role-based decision logic, combat skill database schema); added Adventurer Races (Human/Elf/Dwarf with lifespans) and Leveling & Progression (three XP sources, non-linear stat growth, age-related decline at 75% of lifespan); fixed a stale party-size reference in the glossary; fixed the 6.5.3 non-combat DC wording to reflect fixed, generator-selected values |
| 0.11 | 2026-08-14 | Reworked the Party Arbitration Mechanic's math: Proposal now uses an additive modifier centered on the stat scale's midpoint (so strong Leadership/Decision-Making genuinely raises the shared success chance, not just shrinks it less); Appraisal noise now formalized as a normal-distribution formula driven by Decision-Making, replacing the earlier undefined "may diverge" language; updated worked example and glossary to match |
| 0.12 | 2026-08-15 | Added new reference sections 6.14 (Stats Reference) and 6.15 (Skills & Abilities Reference), separating stat/skill/ability data from use-case narrative; realigned terminology so "Skill" = non-combat approach implementation and "Ability" = combat approach implementation throughout Section 6.5, the Risks table, and the glossary; fixed the 1–20/1–100 stat scale contradiction in 6.5.4 by documenting both as open candidates (Section 6.14) rather than asserting one |

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

## 4. Core Gameplay Loops

The game has two nested loops:

1. **Quest loop (in the field):** a party of adventurers is sent out, works through a series of encounters assembled by the encounter builder, and returns with an outcome (success/failure, rewards, injuries, relationship/morale shifts).
2. **Guild loop (at the town):** the primary "management" layer — recruiting, training, healing, equipping, and negotiating — where most of the player's strategic decisions happen.

**Top-level loop:**

> Find and/or accept an available quest → Execute the quest and receive the outcome/reward → While waiting for the next quest opportunity, improve the guild (recruit from the rotating roster, upgrade facilities, heal/train the roster, negotiate terms) → Repeat.

*The guild loop remains the primary design focus for V1, but the quest loop has grown in scope compared to earlier drafts: making questing itself feel fun and varied — via the encounter builder, tag system, and quest text presentation — is now an explicit, co-equal focus rather than something leaned entirely on borrowed frameworks to de-risk.*

---

## 5. Core Pillars

This game is scoped as a **fantasy guild management sim**, with pillars ranked by priority (most to least important — see Section 12 open item on trimming if scope needs to shrink):

1. **Fantasy questing engine** — a tag-driven quest generator that assembles sensible, thematically coherent, appropriately difficult encounters from the database.The quest loop: multi-encounter quests resolved via a bespoke, stat-driven system with narrative flavor text, ASCII art, and a simple, intuitive UI. The adventurers make all of the decisions, and the game presents the results. The player chooses the party composition, loadout and strategy for the party.
2. **Adventuring guild management** — the guild loop: recruitment, contracts, facilities, finances, roster health, training, crafting, and reputation.
3. **Comprehensive fantasy database** — characters, stats, items, materials, quests, enemies, encounter types, challenges, rewards, and the tags that connect them.
4. **World map and factions** — the guild exists in a larger world, with many settlements, locations and rival factions. Interacting with and exploring different towns and regions will unlock new quests, items, and characters. The player can choose to travel to different settlements for the benefits offered by that settlement. The player can influence the world by completing quests, building facilities, and recruiting characters.
5. **Fantasy character system** — a stat-driven character system with a focus on emergent storytelling and emergent character relationships.

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

A quest is composed of multiple **encounters**, whose skill checks carry fixed, pre-authored difficulty values that the quest generator selects to match the quest's target difficulty (see Section 6.5.3):

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
- **As a system**, the quest generator assembles a quest from four inputs: **quest length**, **theme tag**, **quest type tag**, and **difficulty rating**. Encounters in the database are tagged for relevance to specific quest types and themes, and the generator selects/matches against those tags when assembling a quest. "Theme tag" describes flavor/setting (e.g., undead, bandits, human settlement), while "quest type tag" describes the structural objective (e.g., escort, retrieval, clear-out).
- **As a system**, non-combat DCs are fixed values authored directly on each skill check in the database (see Section 6.5.3a); the quest generator selects encounters whose stored DC matches the difficulty tier it's targeting for that quest, rather than computing or scaling a DC on the fly.
- *This tag system also underpins Section 6.11 (thematic and reactive tags more broadly) — this subsection covers its use specifically within the encounter builder.*

#### 6.5.3a Skill Database (Non-Combat)

- **As a designer**, I want a database of hand-authored skills for each encounter — the non-combat implementation of an approach (Section 6.5.8) — so that the party has a defined, curated set of ways to tackle it rather than an open-ended choice.
- Combat encounters resolve via the Ability Database instead (Section 6.5.9).
- *Full schema: see Section 6.15.*

#### 6.5.4 Resolution System

- Rolls use **3d6 + modifiers**, chosen deliberately over a flatter distribution (e.g., a single d20) to produce a bell curve — this keeps outcomes less swingy and gives stats a bigger, more reliable influence on the result, in line with the goal of stats mattering more than in typical tabletop systems.
- Adventurer stats' scale is not yet finalized — two candidate systems (1–100 and 1–20) are under consideration; see Section 6.14 for both, with their respective Ability Contribution bands. The rest of this section describes the modifier math in general, using the 1–100 candidate as its worked example.
- **Modifiers are calculated across three independent categories, all of which sum together:**

  1. **Ability Contribution** — each stat relevant to a given roll is converted into a small modifier via a banded lookup (not a continuous formula), so raw stats can't dominate the dice. Where a roll draws on more than one stat, each contributing stat's band is added — being good at multiple relevant stats helps additively. *Shown here for the 1–100 candidate; see Section 6.14 for the 1–20 equivalent. Exact band widths for either are still being tuned — the table below is a provisional scaffold, not final:*

     | Stat range | Ability Contribution |
     | --- | --- |
     | 1–20 | −2 |
     | 21–40 | −1 |
     | 41–60 | +0 |
     | 61–80 | +1 |
     | 81–100 | +2 |

  2. **Proficiency Tier** — a separate progression axis representing training in a specific skill, independent of the raw stat (e.g., Untrained/Trained/Expert/Master, each a small flat bonus) — this gives a trained-but-not-naturally-gifted character a real path to competence, and vice versa.
  3. **Item bonuses** — bonuses from equipment. Multiple item bonuses **stack** *(whether all items stack, or only the single best, is still open — see Section 11)*. There is deliberately **no circumstance bonus category**.
- **Difficulty Class (DC)** for skill checks and **Armour Class (AC)** for combat to-hit share a common baseline range of roughly **8–16**, scaled by the quest's target difficulty. Rolling exactly the DC/AC counts as a **success** (meet-or-beat).
- **Critical success/failure:** a result **10 or more above or below** the target number is a critical success or failure. Crit *effects* are defined per individual skill/ability rather than following one universal rule.
- Non-combat **DCs are fixed values authored per skill** in the database (see Section 6.5.3a); the quest generator selects skills whose stored DC matches its target difficulty, rather than computing one dynamically.
- Combat **AC** is calculated from the defending combatant's own relevant stats via the same Ability Contribution + Proficiency system above, rather than being a stored fixed value. *(Working assumption, not yet explicitly confirmed — see Section 11.)*
- The specific stat list — which stats exist and which feed which rolls — is still being finalized (see Section 11).
- Results are dressed with narrative flavor text and inter-party interaction effects to keep quests feeling distinct from one another.

#### 6.5.5 Party Autonomy & Retreat

- **As a player**, I do not directly control party actions during a quest. The party **autonomously decides how to approach each encounter based on personality traits** (see Section 6.6), so outcomes feel emergent rather than player-scripted.
- **As a player**, I want my party to be able to retreat from a quest as an approach option, so that not every dangerous situation ends in death. The decision to retreat is made autonomously by the adventurers themselves, based on their personality traits and current morale — not a direct player choice.
- **As a player**. I want my party to decide how to approach each encounter, based on their personalities and characteristics/stats. The engine to decide this will be called the **Party Arbitration Mechanic**, and is described in a section 6.5.8. This mechanic means the party's actual choice emerges from each member's individually-weighted proposal, with the highest-scoring proposal winning.

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

The party settles on an approach through four phases, run once per encounter:

1. **Appraisal** — every party member independently evaluates every available approach, estimating their own perceived success chance for each. For combat encounters, the appraisal instead estimates the likely battle outcome. The approach with the highest perceived success chance becomes that member's proposal.

   Accuracy of this estimate is governed by the member's **Decision-Making** stat, via added noise drawn from a **normal distribution**:

   ```
   decision_making_left = (100 - decision_making) * j      # j = 0.4
   std_dev = decision_making_left / 2
   noise = randfn(0, std_dev)                                # normal distribution, mean 0
   perceived_success_chance = clamp(success_chance + noise, 0, 100)
   ```

   Higher Decision-Making narrows the noise's typical spread (`std_dev`), so a skilled decision-maker's perceived chance clusters close to the true value; a poor decision-maker's estimate can diverge substantially, including — rarely, at very low Decision-Making — reading as flatly overconfident (perceiving near-100% on a task that isn't). Normal (rather than uniform) noise means small errors are the common case and large swings are rare, which is intentional.
2. **Proposal** — each party member's proposal (their own highest-perceived approach) is adjusted using their own Leadership and Decision-Making stats, via an **additive modifier centered on the stat scale's midpoint (50)** — this ensures a genuinely strong Leadership/Decision-Making combination can raise the shared value above what the member personally perceived, not just shrink it less:

   ```
   stat_average = (leadership + decision_making) / 2
   modifier = (stat_average - 50) * k                        # k = 0.4
   shared_perceived_success_chance = clamp(perceived_success_chance + modifier, 0, 100)
   ```

   A member with high Leadership and high Decision-Making gets a genuine boost — reflecting a socially persuasive member proposing a plan that's *also* well-reasoned. A member weak in both gets pulled down. If two or more members happen to propose the same approach, their proposals are **not** merged or averaged — each is still scored independently on that proposing member's own stats, and stands as its own separate proposal.

   *Worked example:* a party of 3 (A: Leadership 70/Decision-Making 60, B: L80/D40, C: L50/D90) appraises Sneak/Fight/Bribe. C proposes Sneak (75% perceived), B proposes Fight (60%), A proposes Bribe (70%). Modifiers: A's average = 65 → modifier +6 → 76%; B's average = 60 → modifier +4 → 64%; C's average = 70 → modifier +8 → 83%.
3. **Adoption** — the individual proposal with the highest shared perceived success chance is adopted by the party (in the example above, C's Sneak at 83%), regardless of whether other members proposed the same or a different approach.
4. **Execution** — the party carries out the adopted approach. The relevant character(s) make the required roll (RNG + stats, see Section 6.5.4), further modified by party morale and by "synergy" — meaning the established relationship system (Section 6.6.1), not a new stat. How many/which characters contribute to a given approach's roll is defined per-approach in the database, decided case by case rather than by a universal rule.

This system is a deeper evolution of the engage/retreat decision layer described in Section 6.5.5, and depends on the finalized adventurer stat list (see Section 11). *The `j` and `k` constants above are provisional starting points, not final — see Section 11.*

#### 6.5.9 Combat System

- **As a player**, I want combat to be turn-based and legible, so each actor's contribution to the outcome is clear. V1 has no positional movement — combat is resolved purely through actions, to-hit rolls, and damage rolls.
- Each actor gets **one action per turn**, using an available ability (offensive, defensive, or hybrid).
- Adventurers start combat-ready with **3 abilities from their class and 1 from their race**, and unlock further class abilities as they level — the player chooses which to unlock at each level-up threshold (see Section 6.13).

**Combat Roles:** every combatant — adventurer or enemy — is assigned exactly one combat role: **Tank**, **DPS**, **Utility**, or **Healer**. The player assigns roles to their own adventurers; enemy roles are pre-set in the enemy database.

**Aggro System:**

- Aggro (threat) is tracked **independently per combatant, against each opposing combatant** — not as one shared party-wide number. This is symmetric: adventurers generate and react to aggro from enemies, and enemies generate and react to aggro from adventurers, using the same system.
- **Generating aggro is a property of individual abilities** (see the Ability Database, Section 6.15), not a flat per-role multiplier — a Tank's high threat generation comes from having more threat-generating abilities available by class design, not a separate system-level bonus.
- **Starting aggro:** each combat role begins an encounter with a flat baseline aggro value, set by class (for adventurers) or by role (for enemies, using the same four roles).
- **Decay:** aggro decays by **20% per round**.
- **Reset:** aggro resets to starting values between encounters.
- **Targeting:** absent a role-specific override (below), an attacker targets whoever currently holds the highest aggro against them — deterministic, no randomness.

**Role-based decision logic** (evaluated each turn, in priority order):

- **All roles:** if a combatant's own HP falls below a low-HP threshold and a defensive option is available, it's taken — this supersedes everything below. **DPS uses a stricter "exceptionally low" threshold** instead, reflecting a more aggressive playstyle that doesn't back off as readily.
- **Tank:** use an aggro-generating skill on self if not already holding highest aggro against the active target(s); otherwise, attack the current priority (highest-aggro) target.
- **DPS:** if a target is killable this turn, take the kill — **unless another target's aggro is exceptionally high**, in which case attack that high-aggro target instead; otherwise, attack the highest-aggro target.
- **Utility:** apply a status effect to an eligible target that doesn't already have one, if available; otherwise, attack the highest-aggro target.
- **Healer:** if an ally's HP is below a threshold, heal the most at-risk ally; otherwise, contribute offensively or defensively.
- *There's no separate, hard-coded "protect an ally from a killing blow" rule — that kind of protective behavior is intended to emerge from the Tank's threat-holding priority combined with the DPS's aggro-based override, rather than a bolted-on exception. This will need playtesting to confirm it produces the intended effect.*

*Ability schema: see Section 6.15.*

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
- Brave / Cautious / Reckless / Cowardly (max one of the four)

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
- **Party size:** up to **5 characters** may be sent on a single quest. Larger-scale outings (world events, and their largest form, raids) are addressed separately — see Section 9.2 and 9.3.

**Death conditions:** Character death occurs when: (a) a situational failure results in death, OR (b) damage dealt ≥ (2 × current maximum HP), OR (c) total party defeat in combat where only one character can perish, determined by the member with the lowest Constitution stat.

#### 6.7.1 Injury Types

Injuries are categorized into progressive stages, each with specific mechanical effects:

1. **Minor Scratch** — -5% current HP (heals naturally over time)
2. **Bruised Limb** — -10% Strength/Agility for 3 quests
3. **Concussion** — -15% Decision-Making stat for 2 quests
4. **Sprained Ankle** — -20% movement speed, increases retreat likelihood by 25%
5. **Deep Wound** — -25% maximum HP until healed at infirmary

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
- **(V2 direction, not built in V1):** playable races for the guild master with different natural lifespans, and means to unnaturally extend the guild master's lifespan — see Section 9. *(Adventurer races are separate and already V1 — see Section 6.12.)*

### 6.11 Tag System (Thematic & Reactive)

Beyond their role in the encounter builder (Section 6.5.3), tags are intended to be a general-purpose association system applied across the game's content:

- **As a designer**, I want every meaningful game element (characters, enemies, items, quests, environments) to carry descriptive tags, so that thematic coherence and cross-references between systems are possible (e.g., matching "human" enemies to "human settlement" quests).
- **As a player**, I want characters to be able to gain tags reactively, based on what happens to them during play — for example, gaining a "fear of zombies" tag after being downed by one — so that the world remembers and reflects what my adventurers have been through.
- **As a player**, I want the possibility of persistent, recurring antagonists who remember prior interactions with specific characters, so that the world feels like it has memory and continuity.

*This rolls out in phases: static/thematic tagging that powers the encounter builder (6.5.3) is V1, since the encounter builder depends on it. Reactive/event-driven character tags and persistent-antagonist memory are both V2 — there is currently no planned V3+ expansion of the tag system beyond this.*

### 6.12 Adventurer Races

V1 introduces a small set of playable adventurer races, needed because several already-established V1 systems depend on race as a data dimension: stat growth rates during leveling (Section 6.13), starting abilities (one of an adventurer's starting abilities comes from race — Section 6.5.9), and lifespan-driven aging effects (Section 6.13).

| Race | Lifespan |
| --- | --- |
| Human | 85 years |
| Elf | 800 years |
| Dwarf | 360 years |

*Note: this is distinct from the V2 "playable races" item in Section 9.2, which is specifically about the player's own guild-master character and extending their lifespan — adventurer races, covered here, are already V1 scope.*

### 6.13 Leveling & Progression

- **As a player**, I want adventurers to grow more capable over time through play, so that investing in a roster member has a lasting payoff.
- Adventurers gain **XP from three sources**, each contributing at a different rate:
  - **Aging** — a slow, constant trickle of XP over time, kept deliberately small so that keeping an adventurer benched in reserve is never the optimal strategy.
  - **Quests** — a lump sum of XP gained from attempting and/or completing a quest, **split evenly across all party members present**.
  - **Training** — a medium trickle of XP gained during downtime at the guild's training facility (Section 6.3).
  - *V1 scope note: aging XP applies only to adventurers already recruited into the guild — the wider world's recruitable pool isn't simulated over time until V2 (Section 9.2), consistent with V1's single-town scope.*
- XP converts into stat growth **non-linearly** — it takes progressively more XP to raise a stat the higher that stat already is, producing a soft cap without a hard ceiling.
- **Class and race act as multipliers** on how efficiently XP converts into growth for a given stat (e.g., a class/race combination suited to Strength converts XP into Strength growth faster than into an unrelated stat).
- Adventurers unlock new abilities at discrete XP thresholds; the player chooses which ability to unlock from a small set of options at each threshold (starting abilities: 3 from class, 1 from race — see Section 6.5.9).
- **Age-related decline:** once an adventurer passes **75% of their race's natural lifespan** (Section 6.12), their stats begin to decline rather than grow, giving older adventurers real "past their prime" texture rather than being strictly better with time forever.

### 6.14 Stats Reference

*This section is the canonical home for stat definitions, compiled from stats already referenced elsewhere in this document. It is not yet a complete list — the full stat list is still being finalized (see Section 11) — this is a starting scaffold, not a proposed final roster.*

**Open decision: stat scale.** Two candidate systems are currently under consideration, not yet finalized (see Section 11):

- **1–100 scale** — used in the Resolution System's worked examples (Section 6.5.4) and the Party Arbitration Mechanic (Section 6.5.8). Ability Contribution bands:

  | Stat range | Ability Contribution |
  | --- | --- |
  | 1–20 | −2 |
  | 21–40 | −1 |
  | 41–60 | +0 |
  | 61–80 | +1 |
  | 81–100 | +2 |

- **1–20 scale** — an alternative, with an analogous banded structure:

  | Stat range | Ability Contribution |
  | --- | --- |
  | 1–4 | −2 |
  | 5–8 | −1 |
  | 9–12 | +0 |
  | 13–16 | +1 |
  | 17–20 | +2 |

Both produce the same shape of modifier (five bands, −2 to +2) — the choice is really about which raw scale reads better elsewhere (trait thresholds, character-sheet display, XP/leveling granularity) rather than changing the underlying roll math. *This decision affects Sections 6.5.4, 6.6, and 6.13, and the worked examples throughout — once resolved, update all affected sections.*

**Stats referenced so far in this document:**

| Stat | Referenced in | Notes |
| --- | --- | --- |
| Leadership | Party Arbitration Mechanic (6.5.8) | Weights a member's Proposal alongside Decision-Making |
| Decision-Making | Party Arbitration Mechanic (6.5.8), Concussion injury (6.7.1) | Governs Appraisal noise; also weights Proposal |
| Bravery | Personality Traits (6.6) | Threshold example for the reactive Brave trait |
| Strength | Bruised Limb injury (6.7.1) | |
| Agility | Bruised Limb injury (6.7.1) | |
| Constitution | Party-wipe death rule (6.7), Iron Constitution trait (6.6) | Determines which character perishes in a total party defeat |

### 6.15 Skills & Abilities Reference

*This section is the canonical home for the Skill and Ability schemas referenced throughout Section 6.5. Both are authored implementations of an **approach** (Section 6.5.8) — **Skills** for non-combat encounters, **Abilities** for combat.*

**Skill Database** *(non-combat — see Section 6.5.3a for use-case context)*

| Field | Description |
| --- | --- |
| Skill type | Skill check |
| DC | Fixed, authored value; the quest generator selects skills whose DC matches its target difficulty (Section 6.5.3) |
| Relevant stat(s) | Which stat(s) feed the Ability Contribution modifier for this check (Section 6.5.4) |
| Outcome | Resolved via RNG + modifiers (Section 6.5.4) |

**Ability Database** *(combat — see Section 6.5.9 for use-case context)*

| Field | Description |
| --- | --- |
| Ability type | Offensive / Defensive / Hybrid |
| Target type | Self / single ally / all allies / single enemy / all enemies |
| Success-chance formula | Which stat(s) and modifiers (Section 6.5.4) determine this ability's roll |
| HP effect | Healing or damage amount/formula |
| Status effect | Any status effect applied on success |
| Uses per encounter | Limited-use resource |
| Aggro change | How much threat this ability generates (or reduces) |
| Source | Class / race / trait |

*Both databases are expected to be large content-authoring efforts — see Section 10, Risks.*

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
- **Time Model:** V1 uses a hybrid time model — quest resolution is turn-based (actions occur when the player presses "Continue"), but time advances between quests based on a configurable calendar system. The "Continue" button advances time to the next scheduled event (quest completion, injury healing, contract expiration, etc.) rather than simulating continuous real-time.

### 9.2 V2 — Expanding the World

- **Multiple towns and travel** between them; the world map becomes interactive.
- **Support staff** as a hireable category separate from adventurers.
- **Scouting** — revealing/vetting recruitment candidates before they're available.
- **Crafting** — creating and upgrading equipment.
- **Deeper logistics** — real mechanics for transport, food/survival, etc.
- **Playable races (for the guild master)** with different natural lifespans, and means to unnaturally extend the guild master's lifespan, extending the endgame beyond the fixed V1 age-75 retirement. *(Distinct from adventurer races, which are already V1 scope — see Section 6.12.)*
- **Reactive/event-driven character tags** (e.g., fear-of-X after a bad encounter).
- **Persistent antagonist memory** — recurring named enemies who remember specific past interactions with characters.
- **Rival-guild roster poaching ("buyout")** — some V1 traits (Mercenary, Loyalist) already reference this; whether it needs active AI rival guilds in V1 or stays dormant until here is open — see Section 11.
- **Procedural world/quest generation**, where the world reacts to the player's actions.
- **Squad tactics** - players can assign party members to be either dps/tank/healer for combat encounters which will influence their choices in combat but not dictate it. Additionally can provide instructions for how the party must act (aggressive, passive, etc.) for out of combat, again it will influence but not dictate their behavior.
- **World events** — large-scale events that appear as special quests in the world, supporting larger party sizes than the standard 5. *(Exact party size not yet set — see Section 11.)*

### 9.3 V3+ — Stretch Goals

- **Raids** — the largest-scale form of world events, supporting parties of up to 20, tied into multiplayer guild interaction (e.g., every guild choosing a stance: help / hinder / do nothing).
- **Multiplayer / shared-world guild interaction**, including:
  - **Guild vs. Guild tournaments** — competing in a shared dungeon or duel format.
  - **Quest bidding** — guilds competing against each other for the same contracts.
  - **Rival-guild roster poaching ("buyout")** — some V1 personality traits (Mercenary, Loyalist) already reference buyout risk/immunity; whether this activates against AI-controlled rival guilds within V1 or stays dormant until V2 is still to be decided (see Section 11).
  - **Limited direct operations** between rival guilds.
  - **Collaborative quests** — guilds working together, not just competing.
  The intent is that two people could eventually run their own guilds in a shared world, crossing paths through tournaments, world events, or quest competition — but this depends on V1 first establishing a working, fun simulation core.

## 10. Risks

| Risk | Notes |
| --- | --- |
| Scope creep toward V2/V3 features | The wider-world and multiplayer vision is compelling and could distract from shipping a solid, fun V1 core. |
| Two-person team bandwidth | Guild management, a bespoke resolution system, and an encounter builder is a substantial scope for two people; pillar priority (Section 5) exists to guide trimming if needed. |
| Bespoke numerical system design & balancing | Building a fully custom stat/combat/check system (rather than adapting an existing framework) is a larger undertaking than originally scoped, and carries real balancing risk — early prototyping and playtesting will matter more than usual here. |
| Encounter builder & content variety | The "non-repetitive, well-articulated" quest text goal depends on having enough tagged content variety and flavor-text templates; underestimating this could make quests feel samey despite the builder's flexibility. |
| Trait/relationship/morale system tuning | A fully custom system (24 traits, per-pair relationships, party morale) will need playtesting to balance; current trait effects are a strong first draft, not final numbers. |
| Ability Database authoring effort | Alongside the Skill Database, a full combat ability database (offensive/defensive/hybrid, per-ability formulas, status effects) is a second large writing effort for a two-person team — see Section 6.15. |
| Combat role emergent behavior | Protective behaviors (e.g., a Tank shielding a low-HP ally) are intended to emerge from role logic and aggro interactions rather than being explicitly coded — this needs real playtesting to confirm it produces the intended feel rather than degenerate or exploitable behavior. |

---

## 11. Open Questions / Design Decisions Needed

### V1 — Still Open

- **Adventurer stat list:** Nik finalising the full stat list; several systems (resolution system, reactive traits) depend on it and are placeholders until it's available.
- **Stat scale:** 1–100 vs. 1–20 — both candidates are documented in Section 6.14 but not yet decided between.
- **Reactive traits:** how do they interact with the resolution system?
- **Ability Contribution band widths:** exact stat-range bands (Section 6.5.4) are still being tuned; the current table is a provisional scaffold.
- **Item bonus stacking:** do multiple item bonuses all stack, or only the single best one (Section 6.5.4)?
- **Combat AC calculation:** confirm whether AC is calculated from the defender's own stats (current working assumption, Section 6.5.4) or handled some other way.
- **Arbitration constants:** the `j` (Appraisal noise) and `k` (Proposal modifier) constants in Section 6.5.8 are provisional (both 0.4) and need playtesting to tune.

### V2 — Needs Confirmation

- **Rival-guild buyout activation:** do the Mercenary/Loyalist buyout effects require active AI-controlled rival guilds, and if so, which phase introduces that?
- **World event party size:** exact larger-than-5 party size for world events still needs to be set (previous drafts inconsistently suggested 8 or 10).

---

## 12. Milestones (placeholder — dates TBD)

| Milestone | Description |
| --- | --- |
| **M0 — Data model & schema** | Define the character/item/quest/enemy/encounter-piece/tag/skill/ability/race database structure, including trait, relationship, morale, exhaustion, aggro, and XP fields. Depends on the finalized stat list. |
| **M1 — Core loop prototype** | Minimal, possibly non-graphical prototype of the quest simulator, encounter builder, and combat system (select quest → assemble encounters → resolve, including combat rounds → outcome), to validate the resolution system, builder, and combat roles before engine work begins. |
| **M2 — Vertical slice** | One full loop in Godot: town hub → quest selection → text-based quest resolution → finance/reputation update → return to town, with placeholder art. |
| **M3 — Alpha** | All V1 pillars implemented at a rough-but-functional level; internal playtesting. |
| **M4 — Beta** | Visual style pass, content population to the Section 8 targets (1 town, 8 adventurers, 8 quests, 30 enemies, 20 items), balancing. |
| **M5 — V1 Release** | Polish, save/load, bug fixing, release build. |

---

## 13. Glossary

- **Guild** — the player's organization of adventurers, managed across finances, roster, and reputation.
- **Encounter** — a discrete challenge within a quest, categorized as combat, non-combat, or character interaction; difficulty lives on its skills/abilities (Section 6.15), not the encounter itself.
- **Main encounter** — the encounter that determines quest success or failure.
- **Lead-up / side-encounter** — encounters that occur before, or optionally alongside, the main encounter.
- **Encounter builder** — the tag-driven system that assembles encounters from the database based on a quest's length, theme tag, quest type tag, and difficulty rating.
- **Approach** — the umbrella concept for a distinct method of tackling an encounter (e.g., stealth, social, combat) — see Party Arbitration Mechanic (6.5.8). Implemented as either a Skill (non-combat) or an Ability (combat).
- **Skill** — the hand-authored, non-combat implementation of an approach, resolved as a skill check. See the Skill Database (6.5.3a, 6.15).
- **Ability** — the hand-authored, combat implementation of an approach, used during the Combat System's turn resolution. See the Ability Database (6.5.9, 6.15).
- **Party Arbitration Mechanic** — the four-phase system (appraisal, proposal, adoption, execution) by which a party settles on its approach to an encounter: individual stat-based appraisal, weighted-average aggregation into a shared party score, adoption of the highest-scoring approach, and stat-modified execution.
- **Tag** — a descriptive label attached to a game element (character, enemy, item, quest, environment) used to drive thematic coherence and, in later phases, reactive behavior.
- **Party** — the subset of guild members (up to 5) sent on a given quest.
- **Relationship stat** — a persistent per-pair value tracking how one character views another.
- **Morale** — a tracked party-wide stat affecting performance and retreat likelihood.
- **Exhaustion** — accumulated fatigue from encounters that requires downtime to recover.
- **Retirement** — the V1 endgame trigger, occurring when the guild master reaches age 75.
- **Shared Perceived Success Chance** — an individual party member's proposal (their own highest-perceived approach), adjusted by an additive modifier from their own Leadership and Decision-Making stats, centered on the stat scale's midpoint — a strong combination genuinely raises the value, a weak one lowers it. Each member's proposal is scored independently — proposals are never merged or averaged across members, even if two members propose the same approach. See Section 6.5.8.
- **Synergy** — the combined effect of relationship stats between participating characters that modifies roll outcomes during the execution phase. See Section 6.5.8.
- **Ability Contribution** — the small, banded modifier a stat contributes to a roll, derived from the 1–100 stat scale. See Section 6.5.4.
- **Proficiency Tier** — a separate, training-based roll modifier, independent of raw stats. See Section 6.5.4.
- **Aggro (Threat)** — a value tracked independently per combatant against each opposing combatant, determining targeting priority in combat; generated by individual skills, decays 20% per round, resets between encounters. See Section 6.5.9.
- **Combat Role** — one of four roles (Tank, DPS, Utility, Healer) assigned to every combatant, determining their turn-by-turn decision logic in combat. See Section 6.5.9.
- **Adventurer Race** — Human, Elf, or Dwarf in V1, each with its own lifespan affecting stat growth multipliers, starting skills, and age-related decline. See Section 6.12.

---

## 14. Next Steps

1. Finalize the adventurer stat list (Nik) — this gates the resolution system, reactive trait thresholds, and the M0 data model.
2. Finalize individual panel designs (town hub, character sheet, quest log, finance, contracts, shops, facilities).
3. Define the data model for the comprehensive database (characters, stats, items, quests, enemies, encounter pieces, tags, traits, relationships), incorporating the stat list once available.
4. Prototype the encounter builder, resolution system, and combat system together (M1), since they're now the highest-risk, highest-focus systems in V1.
5. Resolve the remaining open questions in Section 11 (Ability Contribution band widths, item bonus stacking, combat AC calculation, rival-guild buyout activation timing, world event party size).
6. Establish the visual style guide (fonts, panel frames, colour palette) — including the colour-coding scheme for quest text (Section 6.5.6).

---

*This document is a living document — revise as remaining open questions get resolved, as panel designs are finalized, and as milestones progress. Update the Document History table with each meaningful revision.*
