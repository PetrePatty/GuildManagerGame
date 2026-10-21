#!/usr/bin/env python3
"""Simulation test for encounter test data using check_resolver."""

# Module Metadata
__author__ = "Petré van der Merwe"
__version__ = "1.0.0"

import sys
from pathlib import Path

# Add proof_of_concept directory to path
poc_dir = Path(__file__).parent.parent
sys.path.insert(0, str(poc_dir))

from check_resolver import resolve_check, roll_dice_3d6
from test_data import ENCOUNTER_TEST_DATA


def calculate_stat_modifier(stat_value: int) -> int:
    """Band lookup for 1-20 stat scale according to adventurers.json stat_modifier_scale."""
    if stat_value <= 1:
        return -5
    elif stat_value <= 3:
        return -4
    elif stat_value <= 5:
        return -3
    elif stat_value <= 7:
        return -2
    elif stat_value <= 9:
        return -1
    elif stat_value == 10:
        return 0
    elif stat_value <= 12:
        return 1
    elif stat_value <= 14:
        return 2
    elif stat_value <= 16:
        return 3
    elif stat_value <= 18:
        return 4
    else:
        return 5


def test_encounter_simulation() -> None:
    encounter = ENCOUNTER_TEST_DATA["encounter"]
    adventurers = ENCOUNTER_TEST_DATA["adventurers"]

    print(f"--- Simulating Encounter: {encounter['name']} ---")
    print(f"Description: {encounter['description']}")
    print(f"Overall Encounter DC: {encounter['difficulty_class']}")

    assert len(encounter["approaches"]) == 3
    assert len(adventurers) == 3

    for approach in encounter["approaches"]:
        print(f"\nApproach: {approach['name']} (DC: {approach['difficulty_class']})")
        print(f"Relevant Stats: {', '.join(approach['relevant_stat_names'])}")

        for adv in adventurers:
            # Calculate total modifier from 3 relevant stats
            total_mod = sum(
                calculate_stat_modifier(adv["stats"][code])
                for code in approach["relevant_stats"]
            )
            dice = roll_dice_3d6()
            outcome = resolve_check(dice, total_mod, approach["difficulty_class"])

            print(
                f"  Adventurer: {adv['first_name']} | "
                f"Stat Mod Total: {total_mod:+d} | "
                f"3d6 Roll: {sum(dice)} {dice} | "
                f"Total: {outcome['roll_total']} | "
                f"Result: {'SUCCESS' if outcome['success'] else 'FAILURE'} "
                f"({'Crit ' + outcome['crit'] if outcome['crit'] else ''})"
            )

    print("\nEncounter simulation completed successfully!")


if __name__ == "__main__":
    test_encounter_simulation()
