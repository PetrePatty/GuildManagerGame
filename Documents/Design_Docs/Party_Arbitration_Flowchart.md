# Party Arbitration System Flowchart

## Overview
The Party Arbitration System resolves how parties choose approaches to encounters through a four-phase voting mechanism. This flowchart follows game development best practices with clear modular phases, state transitions, and scalability considerations.

**File Format:** Mermaid Source (renderable to SVG/PNG/PDF)

## Flowchart

```mermaid
flowchart TD
    %% Style Definitions
    classDef startEnd fill:#2a9d8f,stroke:#1d3557,color:#fff,stroke-width:2px
    classDef process fill:#264653,stroke:#1d3557,color:#fff,stroke-width:2px
    classDef decision fill:#e9c46a,stroke:#1d3557,color:#1d3557,stroke-width:2px
    classDef database fill:#e76f51,stroke:#1d3557,color:#fff,stroke-width:2px
    classDef dataInput fill:#f4a261,stroke:#1d3557,color:#1d3557,stroke-width:2px
    classDef subsystem fill:#8ab17e,stroke:#1d3557,color:#1d3557,stroke-width:2px
    classDef output fill:#2e7d32,stroke:#1d3557,color:#fff,stroke-width:2px
    
    %% Start/End Nodes
    A([Start: Encounter Initiation]):::startEnd
    ZZ([End: Approach Executed]):::startEnd
    
    %% Initialization
    B1[Determine Available Approaches]:::dataInput
    B2[List Approaches from Database]:::database
    B3[Check for Combat Encounter? (Yes/No)]:::decision
    
    %% Non-Combat Flow
    B3 -->|No| NF1[Run Appraisal Phase]:::process
    NF1 --> NF2[Each Party Member Rates Approaches]
    NF2 --> NF3[Aggregate Ratings by Leadership + Decision-Making]
    NF3 --> NF4{Find Highest Shared Score}
    NF4 --> NF5[Adoption Phase - Select Approach]
    
    %% Combat Flow
    B3 -->|Yes| CF1[Run Appraisal Phase]:::process
    CF1 --> CF2[Each Party Member Estimates Combat Victory Odds]
    CF2 --> CF3[Aggregate Ratings by Leadership + Decision-Making]
    CF3 --> CF4{Find Highest Shared Score}
    CF4 --> CF5[Adoption Phase - Select Approach]
    
    %% Adoption & Execution
    NF5 --> OA[Output Chosen Approach]:::output
    CF5 --> OA
    OA --> EX[Execute Approach]:::process
    EX --> EE[Calculate Rolls with Stats + Morale]:::process
    EE --> DE[Determine Outcome: Success/Failure/Retreat]:::decision
    
    %% Completion
    DE -->|Success| END_Success([End: Quest Progress]):::startEnd
    DE -->|Failure| END_Failure([End: Quest Failed]):::startEnd
    
    %% Data Flow Connections
    A --> B1 --> B2 --> B3
    B3 -->|No| NF1 --> NF2 --> NF3 --> NF4 --> NF5 --> OA --> EX --> EE --> DE --> END_Success
    B3 -->|Yes| CF1 --> CF2 --> CF3 --> CF4 --> CF5 --> OA --> EX --> EE --> DE --> END_Success
    
    class A,END_Success,END_Failure startEnd
    class B1,B2,B3 dataInput
    class NF1,NF2,NF3,NF4,NF5,OA,CF1,CF2,CF3,CF4,CF5,EX,EE process
    class DE decision
    class OA output
    class NF1,NF2,NF3,NF4,NF5 subsys1
    class CF1,CF2,CF3,CF4,CF5 subsys2
    class EX,E<=E decision
```

## Processing Flow Description

### 1. Initialization
- **AvailableApproaches**: Retrieved from encounter database
- **Combat Check**: Distinguishes combat vs. non-combat encounters

### 2. Phase 1 - Appraisal
- **Individual Evaluation**: Each party member independently assesses approaches:
  - Non-combat: Rates success probability based on personal stats
  - Combat: Estimates battle outcome odds
- **Influence Factors**: Personal decision-making and leadership stats weight self-opinions

### 3. Phase 2 - Proposal
- **Aggregation**: Ratings combined via weighted average:
  - Weighted by the voter's own leadership/decision-making stats
  - Forms **Shared Party Success Chance** per approach
- **Combat Specific**: Uses combat-specific appraisal module

### 4. Phase 3 - Adoption
- **Decision Rule**: Approach with highest shared party success chance is adopted
- **Ties**: Handled by secondary resolution (not shown in core flow)

### 5. Phase 4 - Execution
- **Roll Calculation**: Perform required rolls:
  - Base: RNG + modified by character stats
  - Modifiers: Current party morale and relationship synergies
- **Outcome Determination**:
  - Success: Progress toward quest completion
  - Failure: Potential injuries, morale impact, or retreat triggers
  - Retreat: Specific to certain approach types and traits

### 6. Completion
- **End States**: Successful completion, failure, or retreat each trigger different game state transitions

## Scalability Considerations

1. **Phase Modularity**: Each phase can be extended independently (e.g., adding new appraisal heuristics)
2. **Stat Integration**: Adding new personality traits or stats automatically enriches decision-making without changing core flow
3. **Approach Database**: New approaches can be added through data files, not engine changes
4. **Morale Effects**: Can be expanded with additional modifiers or trait interactions

---

*Source: Guild Manager Requirements Document v0.8*
*File Format: Mermaid Source (.mmd) - Renderable to SVG, PNG, or PDF*