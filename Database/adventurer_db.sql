-- =====================================================================
--  ADVENTURER DATABASE  -  Football Manager style CA / PA model
--  Dialect: SQLite 3
--  Build with:  sqlite3 adventurers.db < adventurer_db.sql
-- =====================================================================
--
--  THE CORE IDEA
--  -------------
--  Current Ability (CA) and Potential Ability (PA) are both numbers from
--  1 to 200. PA is a hard ceiling that CA can approach but never pass.
--
--  CA is NOT a pool of stat points. It is a BUDGET, and attributes are
--  bought out of it at a price set by how much that class cares about
--  the skill. Raising a Wizard's Spell Casting is expensive; raising
--  their Unarmed is nearly free. This is why two adventurers with the
--  same CA can look completely different, and why class_stat_weights
--  MUST be populated - without weights, CA has no meaning.
--
--      CA = 200 * SUM(attribute * weight) / SUM(20 * weight)
--
--  AGE DRIVES EVERYTHING
--  ---------------------
--  Age does not just gate growth, it decides how much potential has
--  ALREADY been realised when you meet the character. A prodigy is
--  PA 170 / CA 60 - visibly poor right now, worth every coin later. A
--  veteran is PA 140 / CA 138 - what you see is all you will ever get.
--
--  Races have wildly different lifespans, so age is normalised into a
--  career position between anchor ages, never compared in raw years.
--  An 18 year old Orc and a 130 year old Elf are both prodigies.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- =====================================================================
--  1. REFERENCE / LOOKUP TABLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1.1 RACES
-- Four age anchors define a lifetime:
--   age_adult_min .. age_peak_start  -> the growth years
--   age_peak_start .. age_peak_end   -> the prime
--   age_peak_end .. age_max          -> the decline
-- ---------------------------------------------------------------------
CREATE TABLE races (
    race_id        INTEGER PRIMARY KEY,
    name           TEXT    NOT NULL UNIQUE,
    description    TEXT,
    age_adult_min  INTEGER NOT NULL,
    age_peak_start INTEGER NOT NULL,
    age_peak_end   INTEGER NOT NULL,
    age_max        INTEGER NOT NULL,
    CHECK (age_adult_min < age_peak_start
       AND age_peak_start < age_peak_end
       AND age_peak_end   < age_max)
);

-- ---------------------------------------------------------------------
-- 1.2 CLASSES
-- ---------------------------------------------------------------------
CREATE TABLE classes (
    class_id       INTEGER PRIMARY KEY,
    name           TEXT    NOT NULL UNIQUE,
    description    TEXT,
    is_spellcaster INTEGER NOT NULL DEFAULT 0 CHECK (is_spellcaster IN (0,1))
);

-- ---------------------------------------------------------------------
-- 1.3 STAT CATEGORIES AND STATS
-- ---------------------------------------------------------------------
CREATE TABLE stat_categories (
    category_id INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE,
    description TEXT,
    -- Physical skills wither with age; mental ones do not. This flag is
    -- what makes an ageing adventurer lose Speed but keep their Warfare.
    decays_with_age INTEGER NOT NULL DEFAULT 0 CHECK (decays_with_age IN (0,1)),
    sort_order  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE stats (
    stat_id     INTEGER PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES stat_categories(category_id),
    code        TEXT    NOT NULL UNIQUE,
    name        TEXT    NOT NULL UNIQUE,
    description TEXT,
    min_value   INTEGER NOT NULL DEFAULT 1,
    max_value   INTEGER NOT NULL DEFAULT 20,
    sort_order  INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------
-- 1.4 STAT MODIFIER SCALE
-- Turns a final stat value into the bonus applied to rolls.
-- Bands must not overlap and must cover every legal value.
-- ---------------------------------------------------------------------
CREATE TABLE stat_modifier_scale (
    band_id   INTEGER PRIMARY KEY,
    min_value INTEGER NOT NULL,
    max_value INTEGER NOT NULL,
    modifier  INTEGER NOT NULL,
    CHECK (min_value <= max_value)
);

-- ---------------------------------------------------------------------
-- 1.5 RACIAL STAT MODIFIERS  (structure only - populate later)
-- Applied on read, never baked into the stored roll.
-- ---------------------------------------------------------------------
CREATE TABLE race_stat_modifiers (
    race_id   INTEGER NOT NULL REFERENCES races(race_id) ON DELETE CASCADE,
    stat_id   INTEGER NOT NULL REFERENCES stats(stat_id) ON DELETE CASCADE,
    modifier  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (race_id, stat_id)
);

-- ---------------------------------------------------------------------
-- 1.6 CLASS STAT WEIGHTS  -  THE PRICE LIST
-- How much one point of a skill costs a class out of its CA budget, and
-- equally how much that skill contributes to CA. Seeded below for all
-- six classes: change these numbers and you change what each class is.
-- ---------------------------------------------------------------------
CREATE TABLE class_stat_weights (
    class_id INTEGER NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    stat_id  INTEGER NOT NULL REFERENCES stats(stat_id)    ON DELETE CASCADE,
    weight   REAL    NOT NULL DEFAULT 1.0 CHECK (weight > 0),
    PRIMARY KEY (class_id, stat_id)
);

-- ---------------------------------------------------------------------
-- 1.6b RACE STAT WEIGHTS  -  what a race TENDS toward
--
-- These never touch the CA price list. They bias only WHERE points land
-- during generation, so an Elf naturally accumulates Spell Casting and
-- an Orc naturally accumulates Strength - without either being handed
-- free ability. A missing row means 1.0 (no leaning either way).
--
-- Keep the CA price list and this table separate. Weighting the price
-- list by race would make some race/class pairs strictly better; this
-- only changes flavour.
-- ---------------------------------------------------------------------
CREATE TABLE race_stat_weights (
    race_id INTEGER NOT NULL REFERENCES races(race_id) ON DELETE CASCADE,
    stat_id INTEGER NOT NULL REFERENCES stats(stat_id) ON DELETE CASCADE,
    weight  REAL    NOT NULL DEFAULT 1.0 CHECK (weight > 0),
    PRIMARY KEY (race_id, stat_id)
);

-- ---------------------------------------------------------------------
-- 1.6c RACE / CLASS AFFINITY  -  which combinations exist in the world
--
-- Relative odds that a recruit of a given race follows a given class.
-- Human is 1.0 across the board as the generalist baseline, so every
-- other row reads as a deviation from it. A missing row means 1.0.
-- ---------------------------------------------------------------------
CREATE TABLE race_class_affinity (
    race_id  INTEGER NOT NULL REFERENCES races(race_id)   ON DELETE CASCADE,
    class_id INTEGER NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    weight   REAL    NOT NULL DEFAULT 1.0 CHECK (weight >= 0),
    PRIMARY KEY (race_id, class_id)
);

-- ---------------------------------------------------------------------
-- 1.6d LOCATIONS  -  where the guild is based
--
-- The single biggest influence on who walks through the door. A guild in
-- an elven forest sees elves; one in a halfling village sees halflings.
-- Moving the guild changes the whole character of recruitment.
--
-- population_size scales how many recruits appear per refresh.
-- prosperity shifts the quality of those recruits: a rich city attracts
-- better adventurers than a struggling frontier village.
-- ---------------------------------------------------------------------
CREATE TABLE locations (
    location_id     INTEGER PRIMARY KEY,
    name            TEXT    NOT NULL UNIQUE,
    region_type     TEXT    NOT NULL,
    description     TEXT,
    population_size INTEGER NOT NULL DEFAULT 6 CHECK (population_size > 0),
    prosperity      REAL    NOT NULL DEFAULT 1.0 CHECK (prosperity > 0),
    -- 'weighted' reads location_race_weights, so the local population
    -- dominates. 'equal' ignores those weights entirely and gives every
    -- race identical odds - the massive free cities, where the whole
    -- world passes through and nobody is a local.
    --
    -- Using a flag rather than seeding equal weights row by row means a
    -- seventh race added later stays automatically equal here, instead
    -- of silently never appearing because someone forgot a row.
    race_distribution TEXT NOT NULL DEFAULT 'weighted'
                        CHECK (race_distribution IN ('weighted','equal'))
);

-- Relative odds of each race appearing here. Missing row means 1.0.
CREATE TABLE location_race_weights (
    location_id INTEGER NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
    race_id     INTEGER NOT NULL REFERENCES races(race_id)         ON DELETE CASCADE,
    weight      REAL    NOT NULL DEFAULT 1.0 CHECK (weight >= 0),
    PRIMARY KEY (location_id, race_id)
);

-- Optional: some places breed certain professions regardless of race.
-- A war camp turns out warriors; a library city turns out wizards.
CREATE TABLE location_class_weights (
    location_id INTEGER NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
    class_id    INTEGER NOT NULL REFERENCES classes(class_id)      ON DELETE CASCADE,
    weight      REAL    NOT NULL DEFAULT 1.0 CHECK (weight >= 0),
    PRIMARY KEY (location_id, class_id)
);

-- ---------------------------------------------------------------------
-- 1.6e THE GUILD
-- One row per save. Where the guild sits determines recruitment.
-- ---------------------------------------------------------------------
CREATE TABLE guild (
    guild_id    INTEGER PRIMARY KEY CHECK (guild_id = 1),
    name        TEXT    NOT NULL DEFAULT 'The Guild',
    location_id INTEGER NOT NULL REFERENCES locations(location_id),
    gold        INTEGER NOT NULL DEFAULT 500
);

-- ---------------------------------------------------------------------
-- 1.7 REPUTATION TIERS
-- Purely a display layer over CA, the way FM shows stars. Five bands so
-- the recruitment screen can say "Elite" instead of "CA 172".
-- ---------------------------------------------------------------------
CREATE TABLE reputation_tiers (
    tier         INTEGER PRIMARY KEY CHECK (tier BETWEEN 1 AND 5),
    name         TEXT    NOT NULL UNIQUE,
    description  TEXT,
    ca_min       INTEGER NOT NULL,
    ca_max       INTEGER NOT NULL,
    -- Relative odds of a recruit having their POTENTIAL in this band.
    spawn_weight REAL    NOT NULL DEFAULT 1.0 CHECK (spawn_weight >= 0),
    CHECK (ca_min <= ca_max)
);

-- ---------------------------------------------------------------------
-- 1.8 AGE DEVELOPMENT CURVE  -  the heart of the FM model
--
-- phase is one of 'Youth', 'Prime', 'Decline'. Within a phase, position
-- runs 0.0 to 1.0 through that phase's age anchors, so the same curve
-- fits an Orc who peaks at 20 and an Elf who peaks at 180.
--
--   realised_min/max -> how much of PA is already spent as CA when the
--                       character is generated at this stage
--   growth_rate      -> how fast the remaining gap closes per step
--   physical_decay   -> stat points lost per step from decaying skills
--   wage_multiplier  -> how this stage shifts pay demands. The young
--                       accept less; those at their peak know it.
--   potential_premium-> how hard they trade on unrealised potential. A
--                       prodigy demands to be paid for what they will
--                       become; a veteran has nothing left to sell.
-- ---------------------------------------------------------------------
CREATE TABLE age_development_curve (
    stage_id          INTEGER PRIMARY KEY,
    phase             TEXT    NOT NULL CHECK (phase IN ('Youth','Prime','Decline')),
    position_min      REAL    NOT NULL,
    position_max      REAL    NOT NULL,
    name              TEXT    NOT NULL UNIQUE,
    description       TEXT,
    realised_min      REAL    NOT NULL CHECK (realised_min BETWEEN 0 AND 1),
    realised_max      REAL    NOT NULL CHECK (realised_max BETWEEN 0 AND 1),
    growth_rate       REAL    NOT NULL DEFAULT 0 CHECK (growth_rate >= 0),
    physical_decay    REAL    NOT NULL DEFAULT 0 CHECK (physical_decay >= 0),
    wage_multiplier   REAL    NOT NULL DEFAULT 1.0 CHECK (wage_multiplier > 0),
    potential_premium REAL    NOT NULL DEFAULT 0 CHECK (potential_premium >= 0),
    spawn_weight      REAL    NOT NULL DEFAULT 1.0,
    CHECK (position_min <= position_max AND realised_min <= realised_max)
);

-- ---------------------------------------------------------------------
-- 1.8b WAGE SCALE
-- Base pay per period, banded by CA and interpolated inside each band so
-- the curve is smooth. Deliberately steep at the top: a Legendary hire
-- costs many times an Elite one, which is what stops the player simply
-- hoarding the best adventurers they can find.
-- ---------------------------------------------------------------------
CREATE TABLE wage_scale (
    band_id   INTEGER PRIMARY KEY,
    ca_min    INTEGER NOT NULL,
    ca_max    INTEGER NOT NULL,
    gold_min  REAL    NOT NULL,   -- pay at the bottom of the band
    gold_max  REAL    NOT NULL,   -- pay at the top of the band
    CHECK (ca_min <= ca_max AND gold_min <= gold_max)
);

-- ---------------------------------------------------------------------
-- 1.8c WAGE SATISFACTION
-- Compares what an adventurer is actually paid against what they now
-- demand. ratio = wage_agreed / wage_demand. As they improve, their
-- demand rises and a once-generous contract quietly becomes an insult.
-- ---------------------------------------------------------------------
CREATE TABLE wage_satisfaction_bands (
    band_id     INTEGER PRIMARY KEY,
    ratio_min   REAL    NOT NULL,
    ratio_max   REAL    NOT NULL,
    name        TEXT    NOT NULL UNIQUE,
    description TEXT,
    -- Chance per review that they walk out or demand renegotiation.
    leave_risk  REAL    NOT NULL DEFAULT 0 CHECK (leave_risk BETWEEN 0 AND 1),
    CHECK (ratio_min <= ratio_max)
);

-- ---------------------------------------------------------------------
-- 1.9 POTENTIAL GROWTH CHANCE
-- In real FM, PA is fixed at birth and never moves. Kept here because
-- you asked for it: a small chance per level that PA nudges upward.
-- Set every chance to 0 for strict FM behaviour.
-- ---------------------------------------------------------------------
CREATE TABLE potential_growth_chance (
    level      INTEGER PRIMARY KEY CHECK (level BETWEEN 2 AND 20),
    chance     REAL    NOT NULL CHECK (chance BETWEEN 0 AND 1),
    max_gain   INTEGER NOT NULL DEFAULT 5 CHECK (max_gain >= 0)
);

-- ---------------------------------------------------------------------
-- 1.10 GAME CONFIG
-- ---------------------------------------------------------------------
CREATE TABLE game_config (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    notes TEXT
);

-- =====================================================================
--  2. CONTENT TABLES  (items, abilities, spells)
-- =====================================================================

CREATE TABLE items (
    item_id     INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE,
    item_type   TEXT    NOT NULL CHECK (item_type IN
                    ('Weapon','Armour','Shield','Consumable','Tool',
                     'Focus','Ammunition','Misc')),
    slot        TEXT    CHECK (slot IN
                    ('MainHand','OffHand','Head','Body','Hands','Feet',
                     'Neck','Ring','Back','None')),
    weight      REAL    NOT NULL DEFAULT 0,
    value_gold  INTEGER NOT NULL DEFAULT 0,
    description TEXT
);

-- Abilities: structure only, populate later.
CREATE TABLE abilities (
    ability_id    INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL UNIQUE,
    description   TEXT,
    ability_type  TEXT,
    resource_cost INTEGER NOT NULL DEFAULT 0,
    cooldown      INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE class_abilities (
    class_id     INTEGER NOT NULL REFERENCES classes(class_id)     ON DELETE CASCADE,
    ability_id   INTEGER NOT NULL REFERENCES abilities(ability_id) ON DELETE CASCADE,
    level_gained INTEGER NOT NULL DEFAULT 1,
    is_starting  INTEGER NOT NULL DEFAULT 0 CHECK (is_starting IN (0,1)),
    PRIMARY KEY (class_id, ability_id)
);

-- Spells: structure only, populate later.
CREATE TABLE spells (
    spell_id    INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE,
    description TEXT,
    spell_level INTEGER NOT NULL DEFAULT 1,
    school      TEXT,
    mana_cost   INTEGER NOT NULL DEFAULT 0,
    cast_time   TEXT,
    spell_range TEXT,
    duration    TEXT
);

CREATE TABLE class_spells (
    class_id     INTEGER NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    spell_id     INTEGER NOT NULL REFERENCES spells(spell_id)  ON DELETE CASCADE,
    level_gained INTEGER NOT NULL DEFAULT 1,
    is_starting  INTEGER NOT NULL DEFAULT 0 CHECK (is_starting IN (0,1)),
    PRIMARY KEY (class_id, spell_id)
);

CREATE TABLE class_starting_items (
    class_id INTEGER NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    item_id  INTEGER NOT NULL REFERENCES items(item_id)    ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    equipped INTEGER NOT NULL DEFAULT 0 CHECK (equipped IN (0,1)),
    PRIMARY KEY (class_id, item_id)
);

-- =====================================================================
--  3. NAME GENERATION
-- =====================================================================
CREATE TABLE name_pool (
    name_id   INTEGER PRIMARY KEY,
    race_id   INTEGER NOT NULL REFERENCES races(race_id) ON DELETE CASCADE,
    sex       TEXT    NOT NULL CHECK (sex IN ('Male','Female','Any')),
    name_part TEXT    NOT NULL CHECK (name_part IN ('First','Surname')),
    value     TEXT    NOT NULL
);

CREATE INDEX idx_name_pool_lookup ON name_pool(race_id, name_part, sex);

-- =====================================================================
--  4. THE ADVENTURERS
-- =====================================================================
CREATE TABLE adventurers (
    adventurer_id     INTEGER PRIMARY KEY,
    first_name        TEXT    NOT NULL,
    surname           TEXT,
    race_id           INTEGER NOT NULL REFERENCES races(race_id),
    class_id          INTEGER NOT NULL REFERENCES classes(class_id),
    sex               TEXT    NOT NULL CHECK (sex IN ('Male','Female','Other')),
    age               INTEGER NOT NULL CHECK (age > 0),
    level             INTEGER NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 20),

    -- Football Manager ratings, 1-200. CA is cached here after being
    -- computed from the attributes; v_computed_ca recalculates it live
    -- so you can always verify the two agree.
    current_ability   INTEGER NOT NULL CHECK (current_ability BETWEEN 1 AND 200),
    potential_ability INTEGER NOT NULL CHECK (potential_ability BETWEEN 1 AND 200),

    -- Hidden potential: if 1, the recruitment screen shows a fuzzy star
    -- band rather than the true number, like an uncertain scout report.
    potential_hidden  INTEGER NOT NULL DEFAULT 1 CHECK (potential_hidden IN (0,1)),

    -- Hidden attribute, 1-20, in the spirit of FM's Professionalism.
    -- Drives how fast the CA gap actually closes. Never shown to the
    -- player; a lazy prodigy may never reach their ceiling.
    professionalism   INTEGER NOT NULL DEFAULT 10
                        CHECK (professionalism BETWEEN 1 AND 20),

    -- Hidden attribute, 1-20. How hard they push on pay. A greedy
    -- adventurer demands well above the going rate for their ability;
    -- a loyal one will take less to stay with a guild that suits them.
    greed             INTEGER NOT NULL DEFAULT 10
                        CHECK (greed BETWEEN 1 AND 20),

    -- Contract. wage_agreed is what the guild actually pays per period;
    -- it is compared against the live demand to work out satisfaction.
    -- NULL wage means unsigned - still sitting in the tavern.
    wage_agreed       REAL    CHECK (wage_agreed IS NULL OR wage_agreed >= 0),
    contract_periods  INTEGER CHECK (contract_periods IS NULL OR contract_periods >= 0),
    signed_at_ca      INTEGER,   -- CA when the contract was signed

    -- Recruitment state
    recruit_cost      INTEGER NOT NULL DEFAULT 0,
    is_recruited      INTEGER NOT NULL DEFAULT 0 CHECK (is_recruited IN (0,1)),
    generated_at      TEXT    NOT NULL DEFAULT (datetime('now')),

    CHECK (current_ability <= potential_ability)
);

CREATE INDEX idx_adventurers_pool ON adventurers(is_recruited, class_id, race_id);

CREATE TABLE adventurer_stats (
    adventurer_id INTEGER NOT NULL REFERENCES adventurers(adventurer_id) ON DELETE CASCADE,
    stat_id       INTEGER NOT NULL REFERENCES stats(stat_id),
    base_value    INTEGER NOT NULL,
    PRIMARY KEY (adventurer_id, stat_id)
);

CREATE TABLE adventurer_items (
    adventurer_id INTEGER NOT NULL REFERENCES adventurers(adventurer_id) ON DELETE CASCADE,
    item_id       INTEGER NOT NULL REFERENCES items(item_id),
    quantity      INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    equipped      INTEGER NOT NULL DEFAULT 0 CHECK (equipped IN (0,1)),
    PRIMARY KEY (adventurer_id, item_id)
);

CREATE TABLE adventurer_abilities (
    adventurer_id INTEGER NOT NULL REFERENCES adventurers(adventurer_id) ON DELETE CASCADE,
    ability_id    INTEGER NOT NULL REFERENCES abilities(ability_id),
    PRIMARY KEY (adventurer_id, ability_id)
);

CREATE TABLE adventurer_spells (
    adventurer_id INTEGER NOT NULL REFERENCES adventurers(adventurer_id) ON DELETE CASCADE,
    spell_id      INTEGER NOT NULL REFERENCES spells(spell_id),
    is_prepared   INTEGER NOT NULL DEFAULT 0 CHECK (is_prepared IN (0,1)),
    PRIMARY KEY (adventurer_id, spell_id)
);

-- Optional audit trail: one row per development step, so you can show
-- a progress graph on the character screen later.
CREATE TABLE development_log (
    log_id        INTEGER PRIMARY KEY,
    adventurer_id INTEGER NOT NULL REFERENCES adventurers(adventurer_id) ON DELETE CASCADE,
    logged_at     TEXT    NOT NULL DEFAULT (datetime('now')),
    age           INTEGER NOT NULL,
    level         INTEGER NOT NULL,
    stage         TEXT,
    ca_before     INTEGER NOT NULL,
    ca_after      INTEGER NOT NULL,
    pa_after      INTEGER NOT NULL,
    note          TEXT
);

-- ---------------------------------------------------------------------
-- 4.1 GUARD RAILS
-- CA must never exceed PA, and PA must never fall.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_ca_not_above_pa_upd
BEFORE UPDATE OF current_ability, potential_ability ON adventurers
FOR EACH ROW WHEN NEW.current_ability > NEW.potential_ability
BEGIN
    SELECT RAISE(ABORT, 'current_ability cannot exceed potential_ability');
END;

CREATE TRIGGER trg_pa_never_falls
BEFORE UPDATE OF potential_ability ON adventurers
FOR EACH ROW WHEN NEW.potential_ability < OLD.potential_ability
BEGIN
    SELECT RAISE(ABORT, 'potential_ability cannot decrease');
END;

-- =====================================================================
--  5. VIEWS
-- =====================================================================

-- 5.1 Final stats: base roll + racial modifier, clamped, then converted
-- into a roll modifier via the scale bands.
CREATE VIEW v_adventurer_stats AS
WITH resolved AS (
    SELECT
        a.adventurer_id,
        sc.category_id,
        sc.name AS category,
        sc.decays_with_age,
        s.stat_id, s.code, s.name AS stat_name,
        ast.base_value,
        COALESCE(rm.modifier, 0) AS racial_modifier,
        MAX(s.min_value,
            MIN(s.max_value, ast.base_value + COALESCE(rm.modifier, 0))
        ) AS final_value,
        sc.sort_order AS category_sort,
        s.sort_order
    FROM adventurers a
    JOIN adventurer_stats ast ON ast.adventurer_id = a.adventurer_id
    JOIN stats s              ON s.stat_id = ast.stat_id
    JOIN stat_categories sc   ON sc.category_id = s.category_id
    LEFT JOIN race_stat_modifiers rm
           ON rm.race_id = a.race_id AND rm.stat_id = s.stat_id
)
SELECT r.*, COALESCE(ms.modifier, 0) AS roll_modifier
FROM resolved r
LEFT JOIN stat_modifier_scale ms
       ON r.final_value BETWEEN ms.min_value AND ms.max_value;

-- 5.2 Live recalculation of CA from the attributes, using the class
-- price list. Compare with adventurers.current_ability to confirm the
-- cached value is honest.
CREATE VIEW v_computed_ca AS
SELECT
    v.adventurer_id,
    CAST(ROUND(
        200.0 * SUM(v.final_value * w.weight) / SUM(st.max_value * w.weight)
    ) AS INTEGER) AS computed_ca
FROM v_adventurer_stats v
JOIN adventurers a        ON a.adventurer_id = v.adventurer_id
JOIN stats st             ON st.stat_id = v.stat_id
JOIN class_stat_weights w ON w.class_id = a.class_id AND w.stat_id = v.stat_id
GROUP BY v.adventurer_id;

-- 5.3 Where this adventurer sits on the age curve, and what that means
-- for their future. This is the view the scouting screen wants.
CREATE VIEW v_adventurer_ability AS
SELECT
    a.adventurer_id,
    a.age,
    a.level,
    r.name AS race,
    -- Which phase of life, and how far through it (0.0 to 1.0).
    CASE WHEN a.age <  r.age_peak_start THEN 'Youth'
         WHEN a.age <= r.age_peak_end   THEN 'Prime'
         ELSE 'Decline' END AS phase,
    CASE WHEN a.age <  r.age_peak_start
              THEN (a.age - r.age_adult_min) * 1.0
                   / MAX(1, r.age_peak_start - r.age_adult_min)
         WHEN a.age <= r.age_peak_end
              THEN (a.age - r.age_peak_start) * 1.0
                   / MAX(1, r.age_peak_end - r.age_peak_start)
         ELSE (a.age - r.age_peak_end) * 1.0
                   / MAX(1, r.age_max - r.age_peak_end)
    END AS phase_position,
    a.current_ability,
    a.potential_ability,
    a.potential_ability - a.current_ability AS room_to_grow,
    -- How much of their ceiling is already realised, as a percentage.
    CAST(ROUND(100.0 * a.current_ability / a.potential_ability) AS INTEGER)
        AS realised_pct,
    ct.tier AS current_tier,
    ct.name AS current_tier_name,
    pt.tier AS potential_tier,
    pt.name AS potential_tier_name
FROM adventurers a
JOIN races r             ON r.race_id = a.race_id
JOIN reputation_tiers ct ON a.current_ability   BETWEEN ct.ca_min AND ct.ca_max
JOIN reputation_tiers pt ON a.potential_ability BETWEEN pt.ca_min AND pt.ca_max;

-- 5.4 The named life stage, joined through the age curve. Split out so
-- v_adventurer_ability stays readable.
CREATE VIEW v_adventurer_stage AS
SELECT
    ab.adventurer_id,
    ab.phase,
    ab.phase_position,
    dc.name AS stage_name,
    dc.description AS stage_description,
    dc.growth_rate,
    dc.physical_decay
FROM v_adventurer_ability ab
JOIN age_development_curve dc
  ON dc.phase = ab.phase
 AND ab.phase_position >= dc.position_min
 AND (ab.phase_position < dc.position_max OR dc.position_max >= 1.0);

-- 5.5 WAGE DEMAND
-- What this adventurer expects to be paid per period, right now.
--
--   base        = interpolated from the wage_scale band their CA sits in
--   stage       = the young accept less, those at their peak charge more
--   potential   = a premium for the gap between what they are and what
--                 they could be. This is why a prodigy is cheap to sign
--                 and surprisingly expensive to keep.
--   greed       = hidden personality, swinging demands roughly +/- 30%
--
-- Because demand is computed live from CA, an adventurer who improves
-- automatically starts wanting more than their old contract pays.
CREATE VIEW v_wage_demand AS
SELECT
    a.adventurer_id,
    ROUND(
        (ws.gold_min + (a.current_ability - ws.ca_min) * 1.0
                     / MAX(1, ws.ca_max - ws.ca_min)
                     * (ws.gold_max - ws.gold_min))
        * dc.wage_multiplier
        * (1.0 + dc.potential_premium
                 * (a.potential_ability - a.current_ability) * 1.0
                 / a.potential_ability)
        * (0.70 + 0.60 * a.greed / 20.0)
    , 2) AS wage_demand,
    ws.gold_min, ws.gold_max,
    dc.wage_multiplier,
    dc.potential_premium
FROM adventurers a
JOIN wage_scale ws ON a.current_ability BETWEEN ws.ca_min AND ws.ca_max
JOIN v_adventurer_stage st ON st.adventurer_id = a.adventurer_id
JOIN age_development_curve dc ON dc.name = st.stage_name;

-- 5.6 CONTRACT STATUS
-- How the adventurer feels about their pay, and the risk they walk.
CREATE VIEW v_contract_status AS
SELECT
    a.adventurer_id,
    TRIM(a.first_name || ' ' || COALESCE(a.surname,'')) AS full_name,
    a.current_ability,
    a.wage_agreed,
    wd.wage_demand,
    a.contract_periods,
    a.signed_at_ca,
    a.current_ability - COALESCE(a.signed_at_ca, a.current_ability)
        AS ca_gained_since_signing,
    ROUND(a.wage_agreed / NULLIF(wd.wage_demand, 0), 3) AS wage_ratio,
    sb.name        AS satisfaction,
    sb.description AS satisfaction_note,
    sb.leave_risk
FROM adventurers a
JOIN v_wage_demand wd ON wd.adventurer_id = a.adventurer_id
LEFT JOIN wage_satisfaction_bands sb
       ON a.wage_agreed / NULLIF(wd.wage_demand, 0) >= sb.ratio_min
      AND (a.wage_agreed / NULLIF(wd.wage_demand, 0) < sb.ratio_max
           OR sb.ratio_max >= 99)
WHERE a.wage_agreed IS NOT NULL;

-- 5.7 The wage bill: what the guild owes per period.
CREATE VIEW v_guild_wage_bill AS
SELECT
    COUNT(*)                AS members,
    ROUND(SUM(wage_agreed), 2) AS total_per_period,
    ROUND(AVG(wage_agreed), 2) AS average_wage,
    SUM(CASE WHEN leave_risk >= 0.10 THEN 1 ELSE 0 END) AS unhappy_members
FROM v_contract_status;

-- 5.8 The recruitment board. Potential is masked when hidden.
CREATE VIEW v_recruit_list AS
SELECT
    a.adventurer_id,
    TRIM(a.first_name || ' ' || COALESCE(a.surname, '')) AS full_name,
    r.name AS race,
    c.name AS class,
    a.sex,
    a.age,
    st.stage_name,
    a.level,
    a.current_ability,
    ab.current_tier_name,
    CASE WHEN a.potential_hidden = 1 THEN NULL
         ELSE a.potential_ability END AS potential_ability,
    CASE WHEN a.potential_hidden = 1 THEN NULL
         ELSE ab.potential_tier_name END AS potential_tier_name,
    a.recruit_cost,
    wd.wage_demand AS asking_wage
FROM adventurers a
JOIN races   r ON r.race_id  = a.race_id
JOIN classes c ON c.class_id = a.class_id
JOIN v_adventurer_ability ab ON ab.adventurer_id = a.adventurer_id
JOIN v_adventurer_stage   st ON st.adventurer_id = a.adventurer_id
JOIN v_wage_demand        wd ON wd.adventurer_id = a.adventurer_id
WHERE a.is_recruited = 0;

-- =====================================================================
--  6. SEED DATA
-- =====================================================================

-- 6.1 Races with their four age anchors.
INSERT INTO races (name, description, age_adult_min, age_peak_start, age_peak_end, age_max) VALUES
 ('Human',    'Adaptable and ambitious. A short, bright arc.',   18,  26,  33,  90),
 ('Elf',      'Long-lived and graceful. Improves for centuries.',100, 180, 320, 750),
 ('Halfling', 'Small, nimble and cheerful.',                      20,  30,  45, 150),
 ('Orc',      'Powerful and fierce. Peaks brutally early.',       14,  20,  28,  60),
 ('Dwarf',    'Hardy and stubborn. Slow to mature, slow to fade.',50,  80, 140, 350),
 ('Gnome',    'Inventive and endlessly curious.',                 40,  65, 110, 425);

INSERT INTO classes (name, description, is_spellcaster) VALUES
 ('Warrior', 'Front-line master of arms.',                  0),
 ('Wizard',  'Scholar of arcane magic.',                     1),
 ('Rogue',   'Stealth, precision and larceny.',              0),
 ('Paladin', 'Armoured holy warrior.',                       1),
 ('Druid',   'Wielder of nature magic and wild shapes.',     1),
 ('Bard',    'Performer whose music carries real power.',    1);

-- 6.2 Stat categories. Physicals decay with age; the rest do not.
INSERT INTO stat_categories (category_id, name, description, decays_with_age, sort_order) VALUES
 (1, 'Proficiencies', 'Trained competencies - what they can do.',        0, 1),
 (2, 'Mentals',       'Temperament and knowledge - how they think.',     0, 2),
 (3, 'Physicals',     'Raw bodily attributes - what the body can do.',   1, 3);

INSERT INTO stats (category_id, code, name, description, min_value, max_value, sort_order) VALUES
 (1, 'UNA', 'Unarmed',            'Fists, grapples and improvised blows.',                 1, 20,  1),
 (1, 'ONE', 'One-Handed Weapons', 'Swords, axes, maces and other single-hand arms.',       1, 20,  2),
 (1, 'TWO', 'Two-Handed Weapons', 'Greatswords, polearms and heavy two-hand arms.',        1, 20,  3),
 (1, 'RNG', 'Ranged Weapons',     'Bows, crossbows, slings and thrown weapons.',           1, 20,  4),
 (1, 'SHD', 'Shields',            'Blocking, shield bashes and holding the line.',         1, 20,  5),
 (1, 'SPC', 'Spell Casting',      'Technical execution of spells - accuracy and control.', 1, 20,  6),
 (1, 'ALC', 'Alchemy',            'Brewing potions, poisons and identifying reagents.',    1, 20,  7),
 (1, 'STL', 'Stealth',            'Moving unseen and unheard.',                            1, 20,  8),
 (1, 'THV', 'Thieving',           'Pickpocketing and lockpicking.',                        1, 20,  9),
 (1, 'CRT', 'Critical Thinking',  'Solving puzzles, riddles and mechanisms.',              1, 20, 10),
 (2, 'BRV', 'Bravery',            'Willingness to attempt the riskier act.',               1, 20,  1),
 (2, 'DEC', 'Decisions',          'Judging whether the risky act will actually work.',     1, 20,  2),
 (2, 'WIL', 'Willpower',          'Resisting fear, magic, temptation and pain.',           1, 20,  3),
 (2, 'LDR', 'Leadership',         'Effectiveness when instructing the party.',             1, 20,  4),
 (2, 'TMW', 'Teamwork',           'Willingness to follow instructions and support.',       1, 20,  5),
 (2, 'VIS', 'Vision',             'Spotting hidden events, traps and enemies.',            1, 20,  6),
 (2, 'ARC', 'Arcana',             'Knowledge of magic, magical places, people, enemies.',  1, 20,  7),
 (2, 'WAR', 'Warfare',            'Reading a fight, tactics and exploiting openings.',     1, 20,  8),
 (2, 'NAT', 'Nature',             'Wild enemies, beasts and non-magical healing.',         1, 20,  9),
 (2, 'GUI', 'Guile',              'Persuasion, deception and reading people.',             1, 20, 10),
 (3, 'STR', 'Strength',           'Force, lifting and melee damage.',                      1, 20,  1),
 (3, 'FIN', 'Finesse',            'Precision and sleight of hand.',                        1, 20,  2),
 (3, 'SPD', 'Speed',              'Reactions, initiative and dodging.',                    1, 20,  3),
 (3, 'END', 'Endurance',          'Stamina, resisting poison, cold and exhaustion.',       1, 20,  4),
 (3, 'ACR', 'Acrobatics',         'Balance and contortion.',                               1, 20,  5),
 (3, 'ATH', 'Athletics',          'Running, jumping and climbing.',                        1, 20,  6);

-- 6.3 Stat -> modifier curve. 10 is baseline.
INSERT INTO stat_modifier_scale (min_value, max_value, modifier) VALUES
 ( 1,  1, -5), ( 2,  3, -4), ( 4,  5, -3), ( 6,  7, -2), ( 8,  9, -1),
 (10, 10,  0),
 (11, 12,  1), (13, 14,  2), (15, 16,  3), (17, 18,  4), (19, 20,  5);

-- 6.4 CLASS STAT WEIGHTS
-- Step one: give every class a baseline weight for every skill, by
-- category. Mentals and physicals matter to everyone; a proficiency you
-- never use is close to free.
INSERT INTO class_stat_weights (class_id, stat_id, weight)
SELECT c.class_id, s.stat_id,
       CASE s.category_id WHEN 1 THEN 0.20   -- Proficiencies
                          WHEN 2 THEN 0.45   -- Mentals
                          ELSE        0.40   -- Physicals
       END
FROM classes c CROSS JOIN stats s;

-- Step two: raise the skills that define each class. These are the
-- expensive ones - the numbers here ARE the class identity.
UPDATE class_stat_weights
SET weight = (
    SELECT k.w FROM (
        SELECT 'Warrior' AS cls, 'ONE' AS code, 2.5 AS w UNION ALL
        SELECT 'Warrior','TWO',2.5 UNION ALL SELECT 'Warrior','SHD',2.0 UNION ALL
        SELECT 'Warrior','UNA',1.2 UNION ALL SELECT 'Warrior','WAR',1.6 UNION ALL
        SELECT 'Warrior','BRV',1.3 UNION ALL SELECT 'Warrior','STR',2.0 UNION ALL
        SELECT 'Warrior','END',1.8 UNION ALL SELECT 'Warrior','ATH',1.2 UNION ALL
        SELECT 'Warrior','SPD',1.1 UNION ALL

        SELECT 'Wizard','SPC',3.0 UNION ALL SELECT 'Wizard','ARC',2.5 UNION ALL
        SELECT 'Wizard','CRT',1.6 UNION ALL SELECT 'Wizard','ALC',1.3 UNION ALL
        SELECT 'Wizard','WIL',1.8 UNION ALL SELECT 'Wizard','DEC',1.3 UNION ALL
        SELECT 'Wizard','VIS',1.1 UNION ALL

        SELECT 'Rogue','STL',2.5 UNION ALL SELECT 'Rogue','THV',2.5 UNION ALL
        SELECT 'Rogue','ONE',1.5 UNION ALL SELECT 'Rogue','RNG',1.2 UNION ALL
        SELECT 'Rogue','CRT',1.3 UNION ALL SELECT 'Rogue','GUI',1.6 UNION ALL
        SELECT 'Rogue','VIS',1.3 UNION ALL SELECT 'Rogue','FIN',2.0 UNION ALL
        SELECT 'Rogue','SPD',1.5 UNION ALL SELECT 'Rogue','ACR',1.5 UNION ALL

        SELECT 'Paladin','ONE',2.0 UNION ALL SELECT 'Paladin','SHD',2.0 UNION ALL
        SELECT 'Paladin','SPC',1.5 UNION ALL SELECT 'Paladin','WIL',2.0 UNION ALL
        SELECT 'Paladin','LDR',2.0 UNION ALL SELECT 'Paladin','BRV',1.8 UNION ALL
        SELECT 'Paladin','TMW',1.3 UNION ALL SELECT 'Paladin','STR',1.5 UNION ALL
        SELECT 'Paladin','END',1.5 UNION ALL

        SELECT 'Druid','SPC',2.2 UNION ALL SELECT 'Druid','NAT',2.8 UNION ALL
        SELECT 'Druid','ALC',1.5 UNION ALL SELECT 'Druid','ARC',1.2 UNION ALL
        SELECT 'Druid','WIL',1.5 UNION ALL SELECT 'Druid','VIS',1.3 UNION ALL
        SELECT 'Druid','END',1.3 UNION ALL

        SELECT 'Bard','GUI',2.8 UNION ALL SELECT 'Bard','SPC',1.8 UNION ALL
        SELECT 'Bard','LDR',1.8 UNION ALL SELECT 'Bard','TMW',1.8 UNION ALL
        SELECT 'Bard','CRT',1.3 UNION ALL SELECT 'Bard','ARC',1.1 UNION ALL
        SELECT 'Bard','VIS',1.1 UNION ALL SELECT 'Bard','FIN',1.2
    ) k
    JOIN classes cl ON cl.name = k.cls
    JOIN stats  st  ON st.code = k.code
    WHERE cl.class_id = class_stat_weights.class_id
      AND st.stat_id  = class_stat_weights.stat_id
)
WHERE EXISTS (
    SELECT 1 FROM (
        SELECT 'Warrior' AS cls,'ONE' AS code UNION ALL SELECT 'Warrior','TWO' UNION ALL
        SELECT 'Warrior','SHD' UNION ALL SELECT 'Warrior','UNA' UNION ALL
        SELECT 'Warrior','WAR' UNION ALL SELECT 'Warrior','BRV' UNION ALL
        SELECT 'Warrior','STR' UNION ALL SELECT 'Warrior','END' UNION ALL
        SELECT 'Warrior','ATH' UNION ALL SELECT 'Warrior','SPD' UNION ALL
        SELECT 'Wizard','SPC' UNION ALL SELECT 'Wizard','ARC' UNION ALL
        SELECT 'Wizard','CRT' UNION ALL SELECT 'Wizard','ALC' UNION ALL
        SELECT 'Wizard','WIL' UNION ALL SELECT 'Wizard','DEC' UNION ALL
        SELECT 'Wizard','VIS' UNION ALL
        SELECT 'Rogue','STL' UNION ALL SELECT 'Rogue','THV' UNION ALL
        SELECT 'Rogue','ONE' UNION ALL SELECT 'Rogue','RNG' UNION ALL
        SELECT 'Rogue','CRT' UNION ALL SELECT 'Rogue','GUI' UNION ALL
        SELECT 'Rogue','VIS' UNION ALL SELECT 'Rogue','FIN' UNION ALL
        SELECT 'Rogue','SPD' UNION ALL SELECT 'Rogue','ACR' UNION ALL
        SELECT 'Paladin','ONE' UNION ALL SELECT 'Paladin','SHD' UNION ALL
        SELECT 'Paladin','SPC' UNION ALL SELECT 'Paladin','WIL' UNION ALL
        SELECT 'Paladin','LDR' UNION ALL SELECT 'Paladin','BRV' UNION ALL
        SELECT 'Paladin','TMW' UNION ALL SELECT 'Paladin','STR' UNION ALL
        SELECT 'Paladin','END' UNION ALL
        SELECT 'Druid','SPC' UNION ALL SELECT 'Druid','NAT' UNION ALL
        SELECT 'Druid','ALC' UNION ALL SELECT 'Druid','ARC' UNION ALL
        SELECT 'Druid','WIL' UNION ALL SELECT 'Druid','VIS' UNION ALL
        SELECT 'Druid','END' UNION ALL
        SELECT 'Bard','GUI' UNION ALL SELECT 'Bard','SPC' UNION ALL
        SELECT 'Bard','LDR' UNION ALL SELECT 'Bard','TMW' UNION ALL
        SELECT 'Bard','CRT' UNION ALL SELECT 'Bard','ARC' UNION ALL
        SELECT 'Bard','VIS' UNION ALL SELECT 'Bard','FIN'
    ) k
    JOIN classes cl ON cl.name = k.cls
    JOIN stats  st  ON st.code = k.code
    WHERE cl.class_id = class_stat_weights.class_id
      AND st.stat_id  = class_stat_weights.stat_id
);

-- 6.4b RACIAL STAT MODIFIERS
-- Deliberately NET ZERO per race: every bonus is paid for by a penalty.
-- That keeps CA comparable across races so no race is a free win, while
-- still giving each a clear identity the player can read off a screen.
-- Human is the baseline and gets nothing at all.
-- Replace these with your own numbers freely; only the net-zero rule
-- matters for balance.
INSERT INTO race_stat_modifiers (race_id, stat_id, modifier)
SELECT r.race_id, s.stat_id, m.mod
FROM (
    SELECT 'Elf' AS rc, 'FIN' AS code,  2 AS mod UNION ALL
    SELECT 'Elf','ARC', 1 UNION ALL SELECT 'Elf','VIS', 1 UNION ALL
    SELECT 'Elf','STR',-2 UNION ALL SELECT 'Elf','END',-2 UNION ALL

    SELECT 'Halfling','ACR', 2 UNION ALL SELECT 'Halfling','STL', 2 UNION ALL
    SELECT 'Halfling','SPD', 1 UNION ALL
    SELECT 'Halfling','STR',-3 UNION ALL SELECT 'Halfling','TWO',-2 UNION ALL

    SELECT 'Orc','STR', 3 UNION ALL SELECT 'Orc','END', 2 UNION ALL
    SELECT 'Orc','BRV', 1 UNION ALL
    SELECT 'Orc','GUI',-3 UNION ALL SELECT 'Orc','ARC',-2 UNION ALL
    SELECT 'Orc','FIN',-1 UNION ALL

    SELECT 'Dwarf','END', 2 UNION ALL SELECT 'Dwarf','WIL', 2 UNION ALL
    SELECT 'Dwarf','STR', 1 UNION ALL
    SELECT 'Dwarf','ACR',-3 UNION ALL SELECT 'Dwarf','SPD',-2 UNION ALL

    SELECT 'Gnome','CRT', 2 UNION ALL SELECT 'Gnome','ALC', 2 UNION ALL
    SELECT 'Gnome','ARC', 1 UNION ALL
    SELECT 'Gnome','STR',-3 UNION ALL SELECT 'Gnome','ATH',-2
) m
JOIN races r ON r.name = m.rc
JOIN stats s ON s.code = m.code;

-- 6.4c RACIAL LEANINGS
-- Bias on WHERE generated points land. Above 1.0 means the race tends to
-- accumulate that skill; below 1.0 means they tend to neglect it.
INSERT INTO race_stat_weights (race_id, stat_id, weight)
SELECT r.race_id, s.stat_id, w.wt
FROM (
    SELECT 'Elf' AS rc,'SPC' AS code, 1.5 AS wt UNION ALL
    SELECT 'Elf','ARC',1.5 UNION ALL SELECT 'Elf','RNG',1.3 UNION ALL
    SELECT 'Elf','NAT',1.2 UNION ALL SELECT 'Elf','STR',0.6 UNION ALL
    SELECT 'Elf','UNA',0.7 UNION ALL

    SELECT 'Halfling','STL',1.6 UNION ALL SELECT 'Halfling','THV',1.5 UNION ALL
    SELECT 'Halfling','ACR',1.4 UNION ALL SELECT 'Halfling','GUI',1.2 UNION ALL
    SELECT 'Halfling','TWO',0.5 UNION ALL SELECT 'Halfling','STR',0.6 UNION ALL

    SELECT 'Orc','STR',1.6 UNION ALL SELECT 'Orc','TWO',1.5 UNION ALL
    SELECT 'Orc','UNA',1.4 UNION ALL SELECT 'Orc','BRV',1.3 UNION ALL
    SELECT 'Orc','ARC',0.5 UNION ALL SELECT 'Orc','SPC',0.6 UNION ALL

    SELECT 'Dwarf','END',1.5 UNION ALL SELECT 'Dwarf','SHD',1.4 UNION ALL
    SELECT 'Dwarf','ONE',1.3 UNION ALL SELECT 'Dwarf','WIL',1.3 UNION ALL
    SELECT 'Dwarf','ACR',0.6 UNION ALL SELECT 'Dwarf','STL',0.7 UNION ALL

    SELECT 'Gnome','ALC',1.5 UNION ALL SELECT 'Gnome','CRT',1.5 UNION ALL
    SELECT 'Gnome','ARC',1.3 UNION ALL SELECT 'Gnome','SPC',1.2 UNION ALL
    SELECT 'Gnome','STR',0.5 UNION ALL SELECT 'Gnome','TWO',0.6
) w
JOIN races r ON r.name = w.rc
JOIN stats s ON s.code = w.code;

-- 6.4d RACE / CLASS AFFINITY
-- Rare pairings are RARE by design: an Orc Wizard sits near 0.6% of
-- recruits, roughly one in 170. Finding one should feel like a story.
INSERT INTO race_class_affinity (race_id, class_id, weight)
SELECT r.race_id, c.class_id, a.wt
FROM (
    SELECT 'Human' AS rc,'Warrior' AS cls, 1.0 AS wt UNION ALL
    SELECT 'Human','Wizard',1.0 UNION ALL SELECT 'Human','Rogue',1.0 UNION ALL
    SELECT 'Human','Paladin',1.0 UNION ALL SELECT 'Human','Druid',1.0 UNION ALL
    SELECT 'Human','Bard',1.0 UNION ALL

    SELECT 'Elf','Warrior',0.6 UNION ALL SELECT 'Elf','Wizard',2.2 UNION ALL
    SELECT 'Elf','Rogue',1.2 UNION ALL SELECT 'Elf','Paladin',0.7 UNION ALL
    SELECT 'Elf','Druid',1.6 UNION ALL SELECT 'Elf','Bard',1.3 UNION ALL

    SELECT 'Halfling','Warrior',0.5 UNION ALL SELECT 'Halfling','Wizard',0.8 UNION ALL
    SELECT 'Halfling','Rogue',2.4 UNION ALL SELECT 'Halfling','Paladin',0.4 UNION ALL
    SELECT 'Halfling','Druid',1.1 UNION ALL SELECT 'Halfling','Bard',1.6 UNION ALL

    SELECT 'Orc','Warrior',2.4 UNION ALL SELECT 'Orc','Wizard',0.2 UNION ALL
    SELECT 'Orc','Rogue',0.8 UNION ALL SELECT 'Orc','Paladin',0.4 UNION ALL
    SELECT 'Orc','Druid',0.9 UNION ALL SELECT 'Orc','Bard',0.3 UNION ALL

    SELECT 'Dwarf','Warrior',2.0 UNION ALL SELECT 'Dwarf','Wizard',0.5 UNION ALL
    SELECT 'Dwarf','Rogue',0.7 UNION ALL SELECT 'Dwarf','Paladin',1.4 UNION ALL
    SELECT 'Dwarf','Druid',0.6 UNION ALL SELECT 'Dwarf','Bard',0.5 UNION ALL

    SELECT 'Gnome','Warrior',0.4 UNION ALL SELECT 'Gnome','Wizard',1.8 UNION ALL
    SELECT 'Gnome','Rogue',1.3 UNION ALL SELECT 'Gnome','Paladin',0.5 UNION ALL
    SELECT 'Gnome','Druid',1.2 UNION ALL SELECT 'Gnome','Bard',1.4
) a
JOIN races   r ON r.name = a.rc
JOIN classes c ON c.name = a.cls;

-- 6.4e LOCATIONS
INSERT INTO locations (location_id, name, region_type, description,
                       population_size, prosperity, race_distribution) VALUES
 (1, 'Riverhold',        'Human market town',
     'A busy crossroads town. Everyone passes through eventually.',      8, 1.00, 'weighted'),
 (2, 'Silverbough Vale', 'Elven forest settlement',
     'Ancient woodland halls. Outsiders are tolerated, not welcomed.',   5, 1.15, 'weighted'),
 (3, 'Underbrook Hollow','Halfling village',
     'Burrow-homes and long lunches. Little trouble, and few warriors.', 5, 0.80, 'weighted'),
 (4, 'Karak Dunmar',     'Dwarven mountain hold',
     'Deep forges under stone. Grim, wealthy and heavily armed.',        7, 1.20, 'weighted'),
 (5, 'Grukmar Warcamp',  'Orcish war camp',
     'A sprawl of tents and pit-fights. Blades are cheap here.',         6, 0.70, 'weighted'),
 (6, 'Tinkerspire',      'Gnomish workshop city',
     'Clockwork spires and alchemical smog. Ideas outnumber people.',    6, 1.10, 'weighted'),
 (7, 'Saltmere Port',    'Free city',
     'Every race, every trade, every kind of trouble. Nobody is a local.',
                                                                        12, 1.05, 'equal'),
 (8, 'Aurum Vale',       'Free city',
     'A banking republic of a hundred flags. Talent goes to the highest bid.',
                                                                        14, 1.35, 'equal'),
 (9, 'The Thousand Gates','Free city',
     'A caravan hub the size of a kingdom. The world empties through it.',
                                                                        16, 1.00, 'equal');

-- Home race dominates; neighbours appear occasionally; the rest are rare.
INSERT INTO location_race_weights (location_id, race_id, weight)
SELECT l.location_id, r.race_id, w.wt
FROM (
    SELECT 'Riverhold' AS loc,'Human' AS rc, 6.0 AS wt UNION ALL
    SELECT 'Riverhold','Halfling',2.0 UNION ALL SELECT 'Riverhold','Dwarf',1.5 UNION ALL
    SELECT 'Riverhold','Elf',1.0 UNION ALL SELECT 'Riverhold','Gnome',1.2 UNION ALL
    SELECT 'Riverhold','Orc',0.6 UNION ALL

    SELECT 'Silverbough Vale','Elf',10.0 UNION ALL
    SELECT 'Silverbough Vale','Human',1.5 UNION ALL
    SELECT 'Silverbough Vale','Halfling',1.0 UNION ALL
    SELECT 'Silverbough Vale','Gnome',0.8 UNION ALL
    SELECT 'Silverbough Vale','Dwarf',0.3 UNION ALL
    SELECT 'Silverbough Vale','Orc',0.15 UNION ALL

    SELECT 'Underbrook Hollow','Halfling',10.0 UNION ALL
    SELECT 'Underbrook Hollow','Human',2.0 UNION ALL
    SELECT 'Underbrook Hollow','Gnome',1.5 UNION ALL
    SELECT 'Underbrook Hollow','Elf',0.6 UNION ALL
    SELECT 'Underbrook Hollow','Dwarf',0.5 UNION ALL
    SELECT 'Underbrook Hollow','Orc',0.1 UNION ALL

    SELECT 'Karak Dunmar','Dwarf',10.0 UNION ALL
    SELECT 'Karak Dunmar','Human',1.2 UNION ALL
    SELECT 'Karak Dunmar','Gnome',1.5 UNION ALL
    SELECT 'Karak Dunmar','Halfling',0.5 UNION ALL
    SELECT 'Karak Dunmar','Orc',0.3 UNION ALL
    SELECT 'Karak Dunmar','Elf',0.2 UNION ALL

    SELECT 'Grukmar Warcamp','Orc',10.0 UNION ALL
    SELECT 'Grukmar Warcamp','Human',1.5 UNION ALL
    SELECT 'Grukmar Warcamp','Dwarf',0.5 UNION ALL
    SELECT 'Grukmar Warcamp','Halfling',0.3 UNION ALL
    SELECT 'Grukmar Warcamp','Gnome',0.3 UNION ALL
    SELECT 'Grukmar Warcamp','Elf',0.1 UNION ALL

    SELECT 'Tinkerspire','Gnome',10.0 UNION ALL
    SELECT 'Tinkerspire','Human',2.0 UNION ALL
    SELECT 'Tinkerspire','Dwarf',1.5 UNION ALL
    SELECT 'Tinkerspire','Halfling',1.0 UNION ALL
    SELECT 'Tinkerspire','Elf',0.8 UNION ALL
    SELECT 'Tinkerspire','Orc',0.2
) w
JOIN locations l ON l.name = w.loc
JOIN races     r ON r.name = w.rc
WHERE l.race_distribution = 'weighted';   -- free cities ignore these entirely

-- Places that breed a profession regardless of who lives there.
INSERT INTO location_class_weights (location_id, class_id, weight)
SELECT l.location_id, c.class_id, w.wt
FROM (
    SELECT 'Grukmar Warcamp' AS loc,'Warrior' AS cls, 2.0 AS wt UNION ALL
    SELECT 'Grukmar Warcamp','Wizard',0.4 UNION ALL
    SELECT 'Tinkerspire','Wizard',1.8 UNION ALL
    SELECT 'Tinkerspire','Warrior',0.5 UNION ALL
    SELECT 'Silverbough Vale','Druid',1.8 UNION ALL
    SELECT 'Karak Dunmar','Warrior',1.5 UNION ALL
    SELECT 'Karak Dunmar','Paladin',1.4 UNION ALL
    SELECT 'Underbrook Hollow','Rogue',1.4 UNION ALL
    SELECT 'Saltmere Port','Rogue',1.5 UNION ALL
    SELECT 'Saltmere Port','Bard',1.4
) w
JOIN locations l ON l.name = w.loc
JOIN classes   c ON c.name = w.cls;

INSERT INTO guild (guild_id, name, location_id, gold)
VALUES (1, 'The Guild', 1, 500);

-- 6.5 Reputation tiers over CA. Bands are contiguous and cover 1-200.
INSERT INTO reputation_tiers (tier, name, description, ca_min, ca_max, spawn_weight) VALUES
 (1, 'Hapless',   'Barely competent. Cheap, and you get what you pay for.',   1,  59, 24.0),
 (2, 'Capable',   'A solid pair of hands. The bulk of any tavern.',          60, 104, 40.0),
 (3, 'Seasoned',  'Genuinely good. Worth paying for.',                      105, 144, 24.0),
 (4, 'Elite',     'Regionally famous. Rare on the open market.',            145, 174,  9.0),
 (5, 'Legendary', 'Songs are written about them.',                          175, 200,  3.0);

-- 6.6 THE AGE CURVE
-- realised_min/max is the share of PA already turned into CA. Note how
-- a Prodigy shows up with barely a quarter of their ceiling realised.
INSERT INTO age_development_curve
 (phase, position_min, position_max, name, description,
  realised_min, realised_max, growth_rate, physical_decay,
  wage_multiplier, potential_premium, spawn_weight) VALUES
 ('Youth',   0.00, 0.34, 'Prodigy',
  'Raw and unproven. Enormous room to grow.',
  0.22, 0.38, 0.30, 0.0, 0.85, 0.90, 12.0),
 ('Youth',   0.34, 0.67, 'Developing',
  'Coming along nicely. Still cheap to hire.',
  0.38, 0.58, 0.24, 0.0, 0.90, 0.75, 18.0),
 ('Youth',   0.67, 1.00, 'Rising',
  'Nearly the finished article. Price is climbing.',
  0.58, 0.78, 0.17, 0.0, 1.00, 0.55, 16.0),
 ('Prime',   0.00, 0.50, 'Peak',
  'At the height of their powers.',
  0.82, 0.95, 0.09, 0.0, 1.15, 0.30, 22.0),
 ('Prime',   0.50, 1.00, 'Established',
  'Fully realised. What you see is what you get.',
  0.90, 1.00, 0.04, 0.0, 1.10, 0.20, 16.0),
 ('Decline', 0.00, 0.25, 'Fading',
  'Still formidable, but the body is slowing.',
  0.88, 0.99, 0.02, 0.5, 0.95, 0.10, 9.0),
 ('Decline', 0.25, 0.60, 'Declining',
  'Experience is all that remains, and it is not enough.',
  0.74, 0.90, 0.00, 1.1, 0.80, 0.05, 5.0),
 ('Decline', 0.60, 1.01, 'Twilight',
  'A name and a story. Hire for the tale, not the fight.',
  0.58, 0.78, 0.00, 1.8, 0.65, 0.00, 2.0);

-- 6.6b WAGE SCALE
-- Gold per period. The curve is steep on purpose - two Seasoned hires
-- cost far less than one Legendary, so the player faces a real choice
-- between a deep roster and a headline name.
INSERT INTO wage_scale (ca_min, ca_max, gold_min, gold_max) VALUES
 (  1,  59,    5,   28),   -- Hapless
 ( 60, 104,   28,   90),   -- Capable
 (105, 144,   90,  240),   -- Seasoned
 (145, 174,  240,  650),   -- Elite
 (175, 200,  650, 2200);   -- Legendary

-- 6.6c WAGE SATISFACTION
-- ratio = what they are paid / what they now demand.
INSERT INTO wage_satisfaction_bands (ratio_min, ratio_max, name, description, leave_risk) VALUES
 (0.00, 0.60, 'Furious',   'Insulted by their pay. Actively looking to leave.', 0.55),
 (0.60, 0.80, 'Unhappy',   'Feels badly underpaid and says so.',                0.28),
 (0.80, 0.95, 'Unsettled', 'Grumbling. Would listen to a better offer.',        0.11),
 (0.95, 1.05, 'Content',   'Paid the going rate. No complaints.',               0.02),
 (1.05, 1.25, 'Happy',     'Paid above their worth and knows it.',              0.00),
 (1.25, 99.0, 'Delighted', 'Being paid a small fortune. Going nowhere.',        0.00);

-- 6.7 Optional PA drift. Set every chance to 0 for strict FM rules.
INSERT INTO potential_growth_chance (level, chance, max_gain) VALUES
 ( 2, 0.070, 6), ( 3, 0.070, 6), ( 4, 0.065, 6), ( 5, 0.065, 5),
 ( 6, 0.055, 5), ( 7, 0.050, 5), ( 8, 0.045, 4), ( 9, 0.045, 4), (10, 0.040, 4),
 (11, 0.030, 3), (12, 0.030, 3), (13, 0.025, 3), (14, 0.025, 3), (15, 0.020, 2),
 (16, 0.015, 2), (17, 0.012, 2), (18, 0.010, 2), (19, 0.008, 1), (20, 0.008, 1);

INSERT INTO game_config (key, value, notes) VALUES
 ('max_level',           '20',   'Hard cap on adventurer level.'),
 ('gen_jitter_min',      '0.45', 'Lower bound of per-stat random affinity at generation.'),
 ('gen_jitter_max',      '1.70', 'Upper bound of per-stat random affinity at generation.'),
 ('class_weight_pull',   '1.30', 'How strongly class weights steer where points land.'),
 ('growth_randomness',   '0.45', 'Random spread on each development step (0 = deterministic).'),
 ('pa_spread',           '18',   'Random spread applied to PA within its tier band.'),
 ('professionalism_pull','0.60', 'How much the hidden professionalism stat swings growth.'),
 ('signing_fee_ca',      '6.0',  'Signing fee gold per point of current ability.'),
 ('signing_fee_gap',     '2.5',  'Signing fee gold per point of unrealised potential.'),
 ('negotiation_floor',   '0.88', 'Lowest wage ratio an adventurer will ever accept.'),
 ('contract_periods',    '12',   'Default contract length offered, in periods.'),
 ('prosperity_pull',     '2.0',  'How strongly location prosperity tilts recruit quality. 0 disables it.');

-- 6.8 Items and starting kits.
INSERT INTO items (name, item_type, slot, weight, value_gold, description) VALUES
 ('Longsword',        'Weapon',     'MainHand', 3.0, 15, 'A reliable straight blade.'),
 ('Dagger',           'Weapon',     'MainHand', 1.0,  2, 'Light, concealable.'),
 ('Quarterstaff',     'Weapon',     'MainHand', 4.0,  1, 'A stout length of wood.'),
 ('Shortbow',         'Weapon',     'MainHand', 2.0, 25, 'Ranged weapon.'),
 ('Wooden Shield',    'Shield',     'OffHand',  6.0, 10, 'Banded oak.'),
 ('Leather Armour',   'Armour',     'Body',    10.0, 10, 'Supple hardened hide.'),
 ('Chainmail',        'Armour',     'Body',    55.0, 75, 'Interlocking steel rings.'),
 ('Travelling Robes', 'Armour',     'Body',     4.0,  1, 'Plain, comfortable robes.'),
 ('Spellbook',        'Focus',      'None',     3.0, 50, 'Blank vellum awaiting theory.'),
 ('Holy Symbol',      'Focus',      'Neck',     1.0,  5, 'A token of faith.'),
 ('Sprig of Mistletoe','Focus',     'None',     0.1,  1, 'A druidic focus.'),
 ('Lute',             'Focus',      'None',     2.0, 35, 'Well-worn and well-tuned.'),
 ('Thieves Tools',    'Tool',       'None',     1.0, 25, 'Picks, wires and wedges.'),
 ('Rations (1 day)',  'Consumable', 'None',     2.0,  1, 'Dried food.'),
 ('Torch',            'Consumable', 'None',     1.0,  1, 'Burns for one hour.');

INSERT INTO class_starting_items (class_id, item_id, quantity, equipped)
SELECT c.class_id, i.item_id, k.qty, k.eq
FROM (
    SELECT 'Warrior' AS cls, 'Longsword' AS itm, 1 AS qty, 1 AS eq UNION ALL
    SELECT 'Warrior','Wooden Shield',1,1 UNION ALL
    SELECT 'Warrior','Chainmail',1,1     UNION ALL SELECT 'Warrior','Rations (1 day)',3,0 UNION ALL
    SELECT 'Wizard','Quarterstaff',1,1   UNION ALL SELECT 'Wizard','Travelling Robes',1,1 UNION ALL
    SELECT 'Wizard','Spellbook',1,0      UNION ALL SELECT 'Wizard','Rations (1 day)',3,0 UNION ALL
    SELECT 'Rogue','Dagger',2,1          UNION ALL SELECT 'Rogue','Leather Armour',1,1 UNION ALL
    SELECT 'Rogue','Thieves Tools',1,0   UNION ALL SELECT 'Rogue','Rations (1 day)',3,0 UNION ALL
    SELECT 'Paladin','Longsword',1,1     UNION ALL SELECT 'Paladin','Chainmail',1,1 UNION ALL
    SELECT 'Paladin','Holy Symbol',1,1   UNION ALL SELECT 'Paladin','Rations (1 day)',3,0 UNION ALL
    SELECT 'Druid','Quarterstaff',1,1    UNION ALL SELECT 'Druid','Leather Armour',1,1 UNION ALL
    SELECT 'Druid','Sprig of Mistletoe',1,0 UNION ALL SELECT 'Druid','Rations (1 day)',3,0 UNION ALL
    SELECT 'Bard','Dagger',1,1           UNION ALL SELECT 'Bard','Leather Armour',1,1 UNION ALL
    SELECT 'Bard','Lute',1,0             UNION ALL SELECT 'Bard','Rations (1 day)',3,0
) AS k
JOIN classes c ON c.name = k.cls
JOIN items   i ON i.name = k.itm;

INSERT INTO name_pool (race_id, sex, name_part, value)
SELECT r.race_id, n.sex, n.part, n.val
FROM (
    SELECT 'Human' AS rc,'Male' AS sex,'First' AS part,'Aldric' AS val UNION ALL
    SELECT 'Human','Male','First','Bertram'    UNION ALL
    SELECT 'Human','Female','First','Maerwen'  UNION ALL
    SELECT 'Human','Female','First','Isolde'   UNION ALL
    SELECT 'Human','Any','Surname','Ashdown'   UNION ALL
    SELECT 'Human','Any','Surname','Thorne'    UNION ALL
    SELECT 'Elf','Male','First','Faelar'       UNION ALL
    SELECT 'Elf','Female','First','Ilyrana'    UNION ALL
    SELECT 'Elf','Any','Surname','Silverbough' UNION ALL
    SELECT 'Halfling','Male','First','Milo'    UNION ALL
    SELECT 'Halfling','Female','First','Poppy' UNION ALL
    SELECT 'Halfling','Any','Surname','Underbrook' UNION ALL
    SELECT 'Orc','Male','First','Grukk'        UNION ALL
    SELECT 'Orc','Female','First','Shara'      UNION ALL
    SELECT 'Orc','Any','Surname','Bonesplitter'UNION ALL
    SELECT 'Dwarf','Male','First','Thoric'     UNION ALL
    SELECT 'Dwarf','Female','First','Berta'    UNION ALL
    SELECT 'Dwarf','Any','Surname','Ironvein'  UNION ALL
    SELECT 'Gnome','Male','First','Fizwick'    UNION ALL
    SELECT 'Gnome','Female','First','Nyx'      UNION ALL
    SELECT 'Gnome','Any','Surname','Cogwhistle'
) AS n
JOIN races r ON r.name = n.rc;

-- =====================================================================
--  7. EXAMPLE QUERIES
-- =====================================================================
--
-- 7.1 The recruitment board, best first:
--   SELECT * FROM v_recruit_list ORDER BY current_ability DESC;
--
-- 7.2 Bargain hunting - the FM scout's favourite query. Young, cheap,
--     and a long way short of their ceiling:
--   SELECT full_name, race, class, age, stage_name,
--          current_ability, potential_ability, recruit_cost
--   FROM v_recruit_list rl
--   JOIN v_adventurer_ability ab USING (adventurer_id)
--   WHERE ab.room_to_grow > 40 AND ab.phase = 'Youth'
--   ORDER BY ab.room_to_grow DESC;
--
-- 7.3 Character sheet, grouped by category:
--   SELECT category, stat_name, final_value, roll_modifier
--   FROM v_adventurer_stats WHERE adventurer_id = 1
--   ORDER BY category_sort, sort_order;
--
-- 7.4 Confirm the cached CA matches a live recalculation:
--   SELECT a.adventurer_id, a.current_ability, c.computed_ca,
--          a.current_ability - c.computed_ca AS drift
--   FROM adventurers a JOIN v_computed_ca c USING (adventurer_id)
--   WHERE a.current_ability <> c.computed_ca;
--
-- 7.5 What a class actually values, most expensive first:
--   SELECT s.name, w.weight FROM class_stat_weights w
--   JOIN stats s USING (stat_id)
--   WHERE w.class_id = 2 ORDER BY w.weight DESC LIMIT 10;
--
-- 7.6 Verify the modifier curve covers every value 1-20:
--   WITH RECURSIVE n(v) AS (SELECT 1 UNION ALL SELECT v+1 FROM n WHERE v<20)
--   SELECT n.v, COUNT(ms.band_id) FROM n
--   LEFT JOIN stat_modifier_scale ms ON n.v BETWEEN ms.min_value AND ms.max_value
--   GROUP BY n.v HAVING COUNT(ms.band_id) <> 1;
--   -- Zero rows means the curve is valid.
--
-- =====================================================================
