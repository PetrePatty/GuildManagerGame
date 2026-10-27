# Instructions : Guild Manager - Encounter Test Data Generation

## Author

Petré van der Merwe

## Overview

This document provides the high-level context and instructions for an AI coding agent working on this project or feature. It is intended to be a concise but complete reference for implementation goals, constraints, scope, and expectations.

## Purpose

- Goal:
Have a complete set of test data, stored in a sensible variable type, to be able to simulate a single encounter, as stipulated in the Guild_Manager_Requirements.md file.
- Desired outcome:
Use this variable filled with test data to simulate a single encounter using additional user-generated functions.

## High-Level Description

- Problem being solved:
I don't have a way of testing the 'check_resolver.py' and 'modifiers_calc.py' files for a proof of concept, using test data for a single encounter.
- Current state:
The 'check_resolver.py' and 'modifiers_calc.py' files are complete and functional, but I don't have a way of testing them for a proof of concept, using test data for a single encounter. There is only a large json file with a lot of data, but it is not structured in a way that is easy to use for testing.
- Target state:
Have a complete set of test data, stored in a sensible variable type, to be able to simulate a single encounter as stipulated in the Guild_Manager_Requirements.md file. The test data should have one non-combat encounter to open a door, with three sensible approaches/skills (such as lockpicking, bashing down the door, convincing a guard to open the door). For each skill, three relevant stats of your choice from the existing adventurers.json file should be used to calculate the modifier. Part of the encounter should be the difficulty, which should be a Difficulty Class between 1 and 20. There should be 3 mostly randomly generated adventurers in the test data, with complete stats (randomly generated) as per the adventurers.json file. Their names should be Nique, Swollrich and Petrus.
- Key assumptions:
The test data should be stored in a variable type that is easy to use for testing, such as a dictionary or a list of dictionaries.
The Guild_Manager_Requirements.md file will be followed to know how encounters should look.

## Scope

### In Scope

- Test data for a single non-combat encounter.
- Test data for 3 adventurers.
- Test data for 3 skills.

### Out of Scope

- Any additional functions for running the encounter, resolving checks or calculating modifiers.
- Extra stats from what already exists in the adventurers.json file.
- Any additional encounters.

## Requirements

### Functional Requirements

- Test data for a single non-combat encounter.
- Test data for 3 adventurers.
- Test data for 3 skills.

### Non-Functional Requirements

- The test data should be stored in a variable type that is easy to use for testing, such as a dictionary or a list of dictionaries.

## Constraints

Document any important technical, business, or product constraints.

- Platform / stack:
Python and json.
- Existing architecture or patterns:
N/A
- Performance expectations:
N/A
- Security / compliance requirements:
N/A
- Accessibility requirements:
N/A
- Dependencies or external systems:
N/A

## User Stories / Tasks

- As a [user type], I want [goal] so that [value].
- As a developer, I want to be able to test the check_resolver.py and modifiers_calc.py files, so that I can ensure they are working correctly.

## Acceptance Criteria

Describe how success will be measured.

- The test data should be stored in a variable type that is easy to use for testing, such as a dictionary or a list of dictionaries.
- The test data will be used to test the check_resolver.py and modifiers_calc.py files.

## Implementation Guidance

Give the AI agent practical guidance for coding.

- Follow existing project conventions and architecture.
- Prefer minimal, maintainable changes.
- Keep changes focused on the requested scope.
- Preserve backward compatibility unless explicitly changed.
- Write clear, readable code with appropriate comments only when necessary.
- Validate with the smallest relevant tests or checks.

## File / Module Notes

- Relevant directories and files:
C:\Projects\Games\GuildManagerGame\Databases\adventurers.json
C:\Projects\Games\GuildManagerGame\Documents\Requirements\Guild_Manager_Requirements.md
C:\Projects\Games\GuildManagerGame\proof_of_concept\tests
- Important patterns to reuse:
N/A

## Risks / Open Questions

Document uncertainties or items that need clarification.

- None.

## Final Deliverable Expectations

Describe the expected outcome of the work.

- Code should be complete and functional.
- Changes should be limited to the requested scope.
- Final result should be easy to review and understand.
- Any assumptions or follow-up items should be noted clearly.

## Sign-off / Status

Optional status for tracking.

- Status: Draft / In Progress / Ready for Review
- Last updated:
- Review by:
