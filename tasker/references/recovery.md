# Recovery Protocol

Read this file after two failures of the same approach, when progress stalls, or before reporting `Blocked`.

## Strategy Reset

Before the next attempt:

1. Capture the exact failure signal and its artifact.
2. List prior attempts and identify their shared assumption or mechanism.
3. Re-check prerequisites using source code, raw responses, logs, official specifications, or direct environment inspection.
4. Form at least two competing explanations, including one that contradicts the leading assumption.
5. Choose a materially different next action and define its success and failure observations before running it.

Changing a timeout, renaming a variable, or rerunning with minor flags is not a distinct strategy unless it tests a different hypothesis. If no distinct in-scope strategy remains, stop consuming retries.

## Retreat Rules

- `execute` failure → `plan`: redesign from new evidence.
- incomplete `verify` → `execute`: fill the evidence gap.
- rejected `confirm` → `clarify`: normalize the corrected contract.
- no suitable tool → `clarify`: state the missing capability or authority.

Every retreat states why the previous stage is no longer valid. The main retry and retreat caps remain authoritative.

## Blocked Report

Use `Blocked` only when a dependency, authority, input, or environment prevents meaningful progress. Report:

- Exact blocker and current evidence.
- Attempts made and why each failed.
- Explanations ruled out and what remains plausible.
- Smallest external action or decision needed.
- First command or step to run after resumption.
- Current artifacts and scope state.

Do not replace this with a vague request for the user to “try manually.”

## Repeated Cause Safeguards

| Cause | Safeguard |
|---|---|
| `hallucination` | require tool evidence and immediate read-back |
| `omission` | list relevant files and dependencies before acting |
| `misread` | quote the exact evidence before interpreting it |
| `tool-failure` | check return codes and distinguish environment failure from task failure |
| `user-ambiguity` | state the assumption and obtain confirmation |
| `logic-flaw` | write competing hypotheses and test the causal chain |

