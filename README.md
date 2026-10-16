# PermitPath

PermitPath helps short-term rental hosts get ready for a permit. The rules are
versioned data, and eligibility verdicts come from deterministic code over the
rules table, never from a model. A verdict is readiness, never approval: it says
whether a host's answers and documents match what the rules ask for, and it
makes no promise about what the permitting authority will decide. PermitPath is
a Raken AI Labs product. The first deployment serves City of Los Angeles hosts.

## Status

Pre-build. Decisions are recorded in `docs/adr/` and `GLOSSARY.md`, and the spec
will live in `docs/spec/`. Those files appear as the decisions they record are
made.

## Repository layout

| Path | What it holds |
| --- | --- |
| `CLAUDE.md` | The project rules and the development standard |
| `GLOSSARY.md` | The domain vocabulary |
| `docs/adr/` | Architecture decision records |
| `docs/spec/` | The product spec |
| `docs/agents/` | Issue tracker, triage label and domain doc conventions |
| `ai_docs/brief.md` | The project brief |
| `ai_docs/research/` | Research notes, dated and never edited after the fact; a correction is a new note |
| `ai_docs/refs/` | Reference material |
| `scripts/`, `.githooks/` | The vendored raken-dev-standard; not edited here |
| `CHANGELOG.md` | Plain-language log of user-visible changes |

## How work moves

- GitHub Issues are the backlog.
- Every change is a pull request.
- The review is the gate comment from `scripts/gate.sh`.
- The merge goes through `scripts/ship.sh`.

`CLAUDE.md` has the full standard.

On a fresh clone, run these once before anything else:

```bash
printf 'ai_docs/intake/\nai_docs/handoff/\n' >> .git/info/exclude
git config core.hooksPath .githooks
```

## Contributor rules

1. Cite every claim about the City of LA with a URL, or mark it `[UNVERIFIED]`.
2. Use no wording that reads as a promise of approval.
3. Keep pricing, hours, insurance, IP and payment terms out of the repo.

## Rights

All rights reserved, Raken AI Labs.
