# 0003. The rules table is a published, versioned artifact that every verdict cites

Status: accepted

## Context

Rules are versioned data, and verdicts come from deterministic code over the rules table, never from a model. Every verdict cites the rule and its source URL. Raken commits to having a City rule change live within five business days.

[ADR 0002](0002-tenant-isolation.md) puts every tenant on one pooled instance today and keeps the option to silo a customer later. A silo would need the same rules, at the same version, without a second copy maintained by hand. The isolation note covers the distribution options in section 4 of [`ai_docs/research/2026-10-16_saas-tenant-isolation-models.md`](../../ai_docs/research/2026-10-16_saas-tenant-isolation-models.md).

## Decision

- **One artifact.** The rules table is authored and reviewed in one place and published as an immutable artifact with a rule version. Every instance loads that artifact. No instance edits rules in place.
- **Verdict citations.** Every verdict records the rule version it was computed under, alongside each rule it cites and that rule's source URL. A verdict can be reproduced from its rule version.
- **Releases.** A rules release is a pull request that writes production data, so it carries the QA approval that CLAUDE.md requires. The approval attaches once, to the artifact.
- **Verified version.** Each instance reports the rule version it has loaded. Raken reads every instance's version in one place (section 4.5).
- **When the five-business-day clock stops:** when every instance's reported version is the new version. Not at merge, and not at publish. An instance that is behind is remediated inside the window.

Under pool there is one production instance, so a release is one load and one verification. A future silo adds instances that are covered by the same check, not a new process.

## Options rejected

- **Editing rules in place in the production database.** Verdicts could not cite a reproducible version. A silo would need a hand-maintained copy.
- **A central rules service queried at verdict time (4.4).** Version skew becomes impossible, but every instance depends on that service on every request. In a future silo, customer data flow would cross a Raken-run boundary, which a security review asks about.
- **Each instance polling for new versions on a schedule (4.4).** Instances disagree on the version during each polling interval and whenever a poll fails. Between them, two hosts at the same address could get different verdicts.
- **A central pipeline writing rules into each customer database (4.4).** It needs write access from Raken's side into every customer project, which narrows the silo boundary.

## Consequences

- A verdict's citation includes a rule version as well as the rule and its URL. Showing a host an older verdict means showing the version it was computed under.
- "Live within five business days" is evidenced by the version report, not by a merge date.
- Whether a jurisdiction is offered to a tenant is configuration ([ADR 0001](0001-foundation-line.md)). It is a selection from the artifact, never a fork of it.

## Open items

- How the artifact reaches an instance: loaded by the release pipeline, or pinned in the deploy and loaded at start. This is decided in the spec. Either way, the instance reports the loaded version.
- How Artifact Registry enforces immutability for generic artifacts (open item 4 in the note).

## If a customer asks

"Every PermitPath readiness result names the exact version of the rules it was checked against and the source of each rule, and a City rule change is counted as live only once every deployment reports the new version."
