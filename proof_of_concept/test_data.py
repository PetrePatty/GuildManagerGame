#!/usr/bin/env python3
"""Encounter Test Data Generation for Guild Manager Proof of Concept.

This module provides a complete set of test data for a single non-combat encounter
(opening a door) with three approaches and three randomly generated adventurers
(Nique, Swollrich, and Petrus) with complete stat profiles as defined in Databases/adventurers.json.
"""

# Module Metadata & Future Imports
__author__ = "Petré van der Merwe"
__version__ = "1.0.0"

import json
import random

# All 26 stats from Databases/adventurers.json
ALL_STATS = [
    {"stat_id": 1, "category_id": 1, "code": "UNA", "name": "Unarmed"},
    {"stat_id": 2, "category_id": 1, "code": "ONE", "name": "One-Handed Weapons"},
    {"stat_id": 3, "category_id": 1, "code": "TWO", "name": "Two-Handed Weapons"},
    {"stat_id": 4, "category_id": 1, "code": "RNG", "name": "Ranged Weapons"},
    {"stat_id": 5, "category_id": 1, "code": "SHD", "name": "Shields"},
    {"stat_id": 6, "category_id": 1, "code": "SPC", "name": "Spell Casting"},
    {"stat_id": 7, "category_id": 1, "code": "ALC", "name": "Alchemy"},
    {"stat_id": 8, "category_id": 1, "code": "STL", "name": "Stealth"},
    {"stat_id": 9, "category_id": 1, "code": "THV", "name": "Thieving"},
    {"stat_id": 10, "category_id": 1, "code": "CRT", "name": "Critical Thinking"},
    {"stat_id": 11, "category_id": 2, "code": "BRV", "name": "Bravery"},
    {"stat_id": 12, "category_id": 2, "code": "DEC", "name": "Decisions"},
    {"stat_id": 13, "category_id": 2, "code": "WIL", "name": "Willpower"},
    {"stat_id": 14, "category_id": 2, "code": "LDR", "name": "Leadership"},
    {"stat_id": 15, "category_id": 2, "code": "TMW", "name": "Teamwork"},
    {"stat_id": 16, "category_id": 2, "code": "VIS", "name": "Vision"},
    {"stat_id": 17, "category_id": 2, "code": "ARC", "name": "Arcana"},
    {"stat_id": 18, "category_id": 2, "code": "WAR", "name": "Warfare"},
    {"stat_id": 19, "category_id": 2, "code": "NAT", "name": "Nature"},
    {"stat_id": 20, "category_id": 2, "code": "GUI", "name": "Guile"},
    {"stat_id": 21, "category_id": 3, "code": "STR", "name": "Strength"},
    {"stat_id": 22, "category_id": 3, "code": "FIN", "name": "Finesse"},
    {"stat_id": 23, "category_id": 3, "code": "SPD", "name": "Speed"},
    {"stat_id": 24, "category_id": 3, "code": "END", "name": "Endurance"},
    {"stat_id": 25, "category_id": 3, "code": "ACR", "name": "Acrobatics"},
    {"stat_id": 26, "category_id": 3, "code": "ATH", "name": "Athletics"},
]


def generate_random_stats(seed: int | None = None) -> dict[str, int]:
    """Generate complete stats (1-20 scale) for all 26 stats in adventurers.json."""
    rng = random.Random(seed) if seed is not None else random.Random()
    return {stat["code"]: rng.randint(1, 20) for stat in ALL_STATS}


# Generate stats with deterministic seeds for consistency in tests
NIQUE_STATS = generate_random_stats(seed=101)
NIQUE_STATS["THV"] = max(NIQUE_STATS["THV"], 15)
NIQUE_STATS["FIN"] = max(NIQUE_STATS["FIN"], 14)

SWOLLRICH_STATS = generate_random_stats(seed=202)
SWOLLRICH_STATS["STR"] = max(SWOLLRICH_STATS["STR"], 16)
SWOLLRICH_STATS["ATH"] = max(SWOLLRICH_STATS["ATH"], 15)

PETRUS_STATS = generate_random_stats(seed=303)
PETRUS_STATS["GUI"] = max(PETRUS_STATS["GUI"], 15)
PETRUS_STATS["LDR"] = max(PETRUS_STATS["LDR"], 14)

ADVENTURERS: list[dict] = [
    {
        "adventurer_id": 1,
        "first_name": "Nique",
        "surname": "Vane",
        "race_id": 2,
        "race_name": "Elf",
        "class_id": 3,
        "class_name": "Rogue",
        "sex": "Female",
        "age": 115,
        "level": 1,
        "stats": NIQUE_STATS,
        "stat_details": [
            {
                "stat_id": s["stat_id"],
                "code": s["code"],
                "name": s["name"],
                "base_value": NIQUE_STATS[s["code"]],
            }
            for s in ALL_STATS
        ],
    },
    {
        "adventurer_id": 2,
        "first_name": "Swollrich",
        "surname": "Ironbreaker",
        "race_id": 4,
        "race_name": "Orc",
        "class_id": 1,
        "class_name": "Warrior",
        "sex": "Male",
        "age": 22,
        "level": 1,
        "stats": SWOLLRICH_STATS,
        "stat_details": [
            {
                "stat_id": s["stat_id"],
                "code": s["code"],
                "name": s["name"],
                "base_value": SWOLLRICH_STATS[s["code"]],
            }
            for s in ALL_STATS
        ],
    },
    {
        "adventurer_id": 3,
        "first_name": "Petrus",
        "surname": "Lightbringer",
        "race_id": 1,
        "race_name": "Human",
        "class_id": 4,
        "class_name": "Paladin",
        "sex": "Male",
        "age": 29,
        "level": 1,
        "stats": PETRUS_STATS,
        "stat_details": [
            {
                "stat_id": s["stat_id"],
                "code": s["code"],
                "name": s["name"],
                "base_value": PETRUS_STATS[s["code"]],
            }
            for s in ALL_STATS
        ],
    },
]

ENCOUNTER: dict = {
    "encounter_id": "enc_noncombat_01",
    "name": "Open the Dungeon Door",
    "category": "non-combat",
    "description": "A heavy reinforced wooden door blocks access to the dungeon. A guard stands nearby, and the lock mechanisms are visible.",
    "difficulty_class": 12,  # DC between 1 and 20
    "approaches": [
        {
            "approach_id": "app_lockpicking",
            "name": "Lockpicking",
            "description": "Pick the mechanical lock on the door using thieving tools and analytical precision.",
            "difficulty_class": 12,
            "relevant_stats": ["THV", "FIN", "CRT"],
            "relevant_stat_names": ["Thieving", "Finesse", "Critical Thinking"],
            "relevant_stat_ids": [9, 22, 10],
        },
        {
            "approach_id": "app_bashing",
            "name": "Bashing Down the Door",
            "description": "Use raw strength and momentum to kick or bash through the reinforced wood.",
            "difficulty_class": 14,
            "relevant_stats": ["STR", "ATH", "END"],
            "relevant_stat_names": ["Strength", "Athletics", "Endurance"],
            "relevant_stat_ids": [21, 26, 24],
        },
        {
            "approach_id": "app_convincing",
            "name": "Convincing a Guard",
            "description": "Talk to the guard guarding the door and persuade them to unlock it.",
            "difficulty_class": 10,
            "relevant_stats": ["GUI", "LDR", "DEC"],
            "relevant_stat_names": ["Guile", "Leadership", "Decisions"],
            "relevant_stat_ids": [20, 14, 12],
        },
    ],
}

ENCOUNTER_TEST_DATA: dict = {
    "encounter": ENCOUNTER,
    "adventurers": ADVENTURERS,
}


def main() -> None:
    """Print the test data in readable JSON format for verification."""
    print("=== Guild Manager Encounter Test Data ===")
    print(json.dumps(ENCOUNTER_TEST_DATA, indent=2))


if __name__ == "__main__":
    main()
