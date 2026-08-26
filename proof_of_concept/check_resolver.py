### Guild Manager
#### Dice Roll Resolution Engine

import random
# Calculate basic 3d6 dice roll function
def roll_dice_3d6():
    """Roll three d6 dice and return as tuple"""
    roll_dice_result = (random.randint(1, 6), random.randint(1, 6), random.randint(1, 6))
    return roll_dice_result

# Calculate check outcome
def resolve_check(dice_result: tuple[int, int,int], modifier: int, dc: int, crit_diff=8) -> dict:
    """
    Resolve a check with a certain modifier against a difficulty class
    
    Args:
        dice_result: Pre-rolled dice only result
        modifier: Roll modifier
        dc: Difficulty class threshold
    
    Returns:
        Dictionary with outcome details
    """
    roll_total = sum(dice_result) + modifier
    delta_roll_dc = roll_total - dc
    success = roll_total >= dc
    if delta_roll_dc >= crit_diff:
        crit = "success"
    elif delta_roll_dc <= -crit_diff:
        crit = "failure"
    else:
        crit = None

    return {
        "dice_result": dice_result,
        "roll_total": roll_total,
        "delta_roll_dc": delta_roll_dc,
        "success": success,
        "crit": crit
    }

# Example usage
result = roll_dice_3d6()
print(f"Rolled a total of {sum(result)}")
check_modifier = 2
check_DC = 12
outcome = resolve_check(result, check_modifier, check_DC)
# Print the outcome in details
# print(f"Outcome: {outcome}")
print(f"Dice result: {outcome['dice_result']}")
print(f"Roll total: {outcome['roll_total']}")
print(f"Check DC: {check_DC}")
print(f"Success: {outcome['success']}")
print(f"Crit: {outcome['crit']}")

