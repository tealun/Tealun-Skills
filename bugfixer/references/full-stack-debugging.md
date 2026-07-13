# Full-Stack Debugging Router

Use this reference when the responsible layer is unclear or the symptom crosses boundaries. It routes the investigation; specialized checks live in the directly linked references from `SKILL.md`.

## Symptom Routing

| Symptom | Start with | Then load |
|---|---|---|
| UI looks wrong or interaction fails | screenshot, rendered text, event/state, overlays | `frontend.md` |
| Save appears successful but reload loses data | payload, contract, write, response mapper, reload | `frontend.md` + `backend-data.md` |
| API `400/401/403/500` | exact request/response and server log | `backend-data.md` |
| API `404` only in production | route registration, running version, proxy target | `backend-data.md` + `runtime-deploy.md` |
| Config ignored or sample becomes active | identify which process reads which config plane | `runtime-deploy.md` |
| Migration or database shape is wrong | schema authority, applied state, runtime DB target | `backend-data.md` + `runtime-deploy.md` when production differs |
| Count or analytics is wrong | metric definition, event write, dedupe, identity, display mapping | `backend-data.md` |
| CI/deploy/process failure | first non-zero exit, artifact path, runtime owner | `runtime-deploy.md` |
| User says “still wrong” | newest correction and exact rejected behavior | applicable domain reference after intent reset |

## Layer Walk

Use the shortest path that explains the symptom:

```text
visible failure
→ rendering or trigger
→ client state/handler
→ request and response mapping
→ route/service/repository
→ database or storage
→ reload/read path
→ visible result
```

Stop when the causal chain is proven. Expand only when verification fails or evidence crosses another boundary.

For persistence defects, explicitly observe:

```text
display → action → payload → contract → service → repository
→ database/storage → response mapping → reload/display
```

A value may render locally but never enter the payload, save correctly but disappear in mapping, upload successfully but never persist, or record an event that the read query filters incorrectly. Mark every unobserved link as a verification gap.

## Intent Reset

When feedback changes the target:

1. Classify the prior mismatch: product, role/view, visual, data flow, runtime, or repository boundary.
2. State the new observable target and protected accepted behavior.
3. Stop the rejected implementation direction.
4. Re-run the layer walk from the corrected symptom.
5. Search for stale variants after repair.

## Internal Bug Ledger

For multi-issue threads track:

- `Symptom`
- `Expected`
- `Layer`
- `Fix`
- `Verification`
- `Status`: pending, fixed locally, verified, blocked, or needs deploy

Keep this internal unless a status summary helps the user.
