---
wave: <N>
depends_on: [<plan-ids this plan requires, e.g. "01-01", or [] >]
---

# Plan <NN-YY>: <title>

**Objective:** <What this plan accomplishes and why it matters for the phase goal.>

## Tasks

<task>
<name>Task 1: <action-oriented name></name>
<files><files to create/modify, comma-separated></files>
<action>
<What to do, how to do it, and what to avoid — with concrete values: exact
identifiers, parameters, paths, commands. Never "align X with Y" without the
exact target state.>
</action>
<verify><command or check that proves it worked></verify>
<acceptance_criteria>
- <Grep-verifiable condition: "file.ext contains 'exact string'">
- <Measurable condition: "output uses 'expected-value', NOT 'wrong-value'">
</acceptance_criteria>
</task>

<task>
<name>Task 2: <action-oriented name></name>
<files><files></files>
<action><Specific implementation with concrete values.></action>
<verify><Command or check></verify>
<acceptance_criteria>
- <Grep-verifiable condition>
</acceptance_criteria>
</task>

## Verification

Before declaring this plan complete:

- [ ] <Test/build command passes>
- [ ] <Behavior verification check>

<!--
Waves run in parallel within a number, sequentially across numbers; depends_on
lists the plan IDs that must finish first. Both are precomputed at plan time —
/skill:implement reads them from this frontmatter, no runtime analysis.
On completion the executor writes NN-YY-SUMMARY.md next to this file.
-->
