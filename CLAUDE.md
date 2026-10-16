# PermitPath

Permit readiness for short-term rental hosts. Rules are versioned data; eligibility verdicts come from deterministic code over the rules table, never from a model. A Raken AI Labs product; Airbnb is the first customer, for City of Los Angeles hosts.

## Read first, every session and after any compaction

1. This file.
2. The newest file in `ai_docs/handoff/` (local only): where the last session left things.
3. `GLOSSARY.md`, `docs/adr/` and `docs/spec/` once they exist: the decisions.
4. `ai_docs/brief.md`, then `ai_docs/research/` newest first. Research notes are dated and never edited after the fact; a correction is a new dated note.

Dated start documents (the Oct 15 kickoff prompt, the Oct 16 pre-grill brief) are inputs to the phase they started and are not updated afterward.

## Rules

- **Cite every claim about the City of LA** with a URL. Mark anything unverified `[UNVERIFIED]`. The current registration fee is $441 (Ordinance 188796); $89, $192 and $454 in older files are not current.
- **Verdicts are readiness, never approval.** No wording that reads as a promise.
- **`ai_docs/intake/` is never committed.** It holds the commercial trail (quotes, emails, decks, transcripts). The repo is public. It is excluded in `.git/info/exclude`, which does not travel with clones: on a fresh clone, add `ai_docs/intake/` and `ai_docs/handoff/` to `.git/info/exclude` before anything else. Pricing, hours-to-dollars, insurance, IP and payment terms stay in intake and never appear in the spec, tickets, `GLOSSARY.md`, ADRs or `docs/`.
- **Branch protection on `main`:** no direct commits, one approving review to merge. Setup is tracked in issue 2; until it is on, behave as if it were.
- **QA is a required review or a PR label, never a note in prose.** A PR that writes to production data needs QA approval before merge. Deck v5 commits to three QA levels: technical, business, real users. The exact rule is tracked in issue 1.
- **`CHANGELOG.md`** at the root is the plain-language change log for Airbnb: one line per user-visible change, written when the PR merges.
- **US English** throughout. Documents from Mexico-based teammates may arrive in Spanish; the repo is English.
- **Handoff docs** go in `ai_docs/handoff/`, local only.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `raken-ai-labs/permit_path`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` at the root and ADRs in `docs/adr/`. See `docs/agents/domain.md`.
