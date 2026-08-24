import random

def roll_3d6() -> tuple[int, int, int]:
    """Roll three six-sided dice and return as tuple"""
    return (
        random.randint(1, 6),
        random.randint(1, 6),
        random.randint(1, 6)
    )

def resolve_check(modifier: int, dc: int, dice: tuple[int, int, int] | None = None) -> dict:
    """
    Resolve a skill check using 3d6 dice mechanics
    
    Args:
        modifier: Stat/skill modifier
        dc: Difficulty class threshold
        dice: Optional pre-rolled dice (for testing)
    
    Returns:
        Dictionary with resolution details
    """
    dice = dice or roll_3d6()
    raw_total = sum(dice)
    total = raw_total + modifier
    margin = total - dc
    
    success = total >= dc
    crit = None
    
    if margin >= 8:
        crit = "CRIT_SUCCESS"
    elif margin <= -8:
        crit = "CRIT_FAILURE"
    
    return {
        "dice": dice,
        "raw_total": raw_total,
        "modifier": modifier,
        "total": total,
        "dc": dc,
        "success": success,
        "crit": crit,
    }

def run_tests() -> None:
    """Run automated unit tests for resolve_check"""
    tests = [
        ("Standard success", 2, 10, (3, 3, 4), True, None),
        ("Critical success", 2, 10, (6, 6, 4), True, "CRIT_SUCCESS"),
        ("Standard failure", 0, 12, (2, 3, 4), False, None),
        ("Critical failure", 0, 15, (1, 2, 2), False, "CRIT_FAILURE"),
    ]
    
    print("Running test cases:")
    for name, mod, dc, dice, expected_success, expected_crit in tests:
        result = resolve_check(mod, dc, dice)
        
        print(f"\nTest: {name}")
        print(f"Dice: {dice} | Mod: {mod} | Total: {result['total']} | DC: {dc}")
        print(f"Success: {result['success']} (Expected: {expected_success})")
        print(f"Crit: {result['crit']} (Expected: {expected_crit})")
        
        assert result["success"] == expected_success
        assert result["crit"] == expected_crit
    
    print("\nAll tests passed!\n")

def main() -> None:
    """Interactive CLI mode"""
    print("Interactive Dice Roller")
    print("-----------------------")
    try:
        while True:
            try:
                mod = int(input("Enter modifier: "))
                dc = int(input("Enter DC: "))
                result = resolve_check(mod, dc)
                
                print(f"\nDice: {result['dice']}")
                print(f"Raw total: {result['raw_total']}")
                print(f"Total (with mod): {result['total']}")
                print(f"DC: {dc}")
                print(f"Outcome: {'SUCCESS' if result['success'] else 'FAILURE'}")
                print(f"Crit: {result['crit'] or 'None'}")
                print("-" * 20)
            except ValueError:
                print("Invalid input. Please enter integers.\n")
    except KeyboardInterrupt:
        print("\nExiting interactive mode.")

if __name__ == "__main__":
    run_tests()
    main()