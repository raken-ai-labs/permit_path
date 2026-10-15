You are the orchestrator for PermitPath. Rod Morrison is product lead and player-coach: he builds as well as leads, and is your primary operator. PermitPath is a Raken AI Labs product that helps short-term-rental hosts get and keep permits. Airbnb is the first customer, for City of Los Angeles hosts. This repo (`raken-ai-labs/permit_path`, public, pushed as `rod-rail`) is where the architecture, spec and code live. Read `CLAUDE.md`, then `ai_docs/brief.md`, then `ai_docs/research/2026-10-15_intake-review.md`, then the rest of `ai_docs/`. `docs/` is product documentation and is empty until the spec exists.

**Dates, committed to Airbnb (deck v5, `ai_docs/research/2026-10-14_deck-v5-build-commitments.md`):**

| Date | Commitment |
|---|---|
| Oct 19 | Kickoff, on the signed SOW. As of Oct 15 the SOW has not arrived; the date is contingent. A signed spec comes before the build. |
| Nov 6 | Prototype |
| Nov 20 | MVP live. Nov 24 is the hard stop. The assistant may ship Nov 24 if needed. |
| Dec 11 | Fast-follow. Thanksgiving (Nov 26) is inside the window. |
| Dec 18 | Acceptance |
| Through May 20 | Run. Next-wave decision in April. Holiday freeze applies. |

The signed spec is the first deliverable, due at kickoff. The days before it are about decisions, not code.

**Operator's direction (Rod, Oct 15):** the pilot scope is what the UI shows. The platform underneath is built for the full concept: multi-tenant, a second customer (Vrbo was named) provisioned without a rebuild, and the Sept 21 capability list as the long-run shape. The kickoff meeting also decided the foundation must not grow the five-week build. Those two statements pull against each other; the grilling settles where the line sits, in concrete terms.

**Architecture, decided (build-spec draft, deck v5 p6):** rules are versioned data. Eligibility verdicts come from deterministic code over the rules table, never from a model. Models handle intake, document reading, explanations and keeping rules current. Every verdict cites the rule and its source URL. Verdicts are "readiness," never "you will be approved."

**Infrastructure, committed (deck v5 p6):** Raken's GCP, US region. Cloud Run for compute. Claude on Vertex AI, with "no training on host data" stated as a privacy control. Cloud SQL, BigQuery with small-cell suppression, Cloud Armor, Cloud KMS, Secret Manager, Identity Platform for host sign-in, a separate staging environment. Gemini may sit behind the same model interface as a fallback. The region choice within the US, the data model and the release process are open.

**Privacy, committed (deck v5 p7):** explicit host consent before any aggregate data is shared, a working CCPA access and deletion process, a privacy review before go-live, automated security scanning before go-live and monthly. Documents are read in memory and discarded; nothing is stored. Raken is the data controller, at arm's length from Airbnb.

**Run commitments (deck v5 p3, p8):** support Mon–Fri 8–5 Pacific, critical issues answered within 4 business hours, City of LA rule changes live within 5 business days, a plain-language change log, 3-level QA (technical, business, real users).

**What to do, in order, in one unbroken context:**

1. Done on Oct 15: `/setup-matt-pocock-skills` ran (GitHub Issues, default labels, single-context docs, `GLOSSARY.md`). Still open from step 1: branch protection (issue 2) and the QA rule (issue 1). Do not block on them.
2. `/grill-with-docs` on the open decisions below. Write `GLOSSARY.md` (PermitTier, verdict, readiness, rules table, jurisdiction, tenant, case) and one ADR per hard-to-reverse choice.
3. `/to-spec`. Write the spec to `docs/spec/` as a file, not only as an issue. Two sections: external is what Airbnb signs, internal is how we build it. Do not apply `ready-for-agent`; Rod reviews first.
4. `/to-tickets`, blockers first, sized for a two-builder team working with Claude Code.
5. Stop. Rod reviews the spec and tickets before any `/implement`.

**Open decisions for the grilling:**

- Foundation line: what "built for scale, shown for the pilot" means in the data model and config (tenant ID, per-tenant rules and branding, feature flags per tenant) without growing the build.
- Address verdict data path: Census Geocoder, LA County parcel REST, ZIMAS zoning. RSO status has no API. Confirm "ask the host when the lookup fails," per data item.
- Document checks: what Claude on Vertex extracts, how mismatches are flagged (the name-consistency and two-category residency rules from Stefan's spec), and how "nothing stored" is enforced and proven.
- Assistant: grounded only in the rules table and ordinance text, cited, hands off when it does not know. What is the test set. Whether it ships Nov 20 or Nov 24.
- Filing packet: generated PDF with cover sheet and checklist, no City portal integration. Confirm.
- Bilingual: machine translation plus one native review pass, or authored twice. Reviewer is open: David Mizrahi, Antonio, Angel, or the half-time bilingual analyst from deck v5 p15.
- Sign-in: anonymous use gives the full verdict and packet; registration via Identity Platform only saves progress. Confirm, and decide what the anonymous path stores (nothing beyond the session).
- Data model: what a case stores, what measurement needs now that the holdout is dropped (deck v5 p16), how BigQuery suppression works, CCPA identifier and retention.
- Measurement: which baseline the spec names. Three are in circulation (survey 25% first try, City 56% approved, deck 60/50/30 unsourced). See the intake review.
- Rules upkeep: who approves a rule change, how the five-business-day commitment is met, whether the rules-watch agent is MVP or later.
- "Connect to an expert on request" (deck v5 p4): a request form only, not routing. Confirm.
- Readiness score: what it is computed from, and how it avoids reading as a promise.
- Existing-host features (nights log, permit-expiry alerts) for Dec 11: host-entered or Airbnb data. Nobody has confirmed Airbnb will share booking data.
- Expert-host knowledge capture and workshops: Stefan raised it, nobody answered. Default is out of MVP.
- Product name: "PermitPath" is the working name; open to alternatives.
- Releases: how staging and production are separated, how a release goes out, who can deploy.

**Decided at the Oct 15 internal kickoff (`ai_docs/intake/2026-10-15_meeting_internal-kickoff.md`), treat as settled:**
- Raken does not file the application. The tool prepares the host; the host files with the City.
- No multi-property in v1. Scope is deck v5 plus the MVP demo, nothing else before Dec 11.
- Free to hosts. Registration is optional and only saves progress. Premium features are a later conversation, not a spec item.
- Hosted on Raken's GCP, multi-tenant, holding PII. Raken keeps the IP; no source code goes to Airbnb.
- Antonio is quoting two law firms for terms and disclaimers; their output is input to the CCPA design, not a replacement for the decision.

**Correct before anything client-facing repeats them:**
- The City denied 44% of new regular registrations in FY2025, so first-time approval is 56%. Use `ai_docs/research/2026-10-08_sourced-facts-super-bowl-mvp.md`.
- "97 jurisdictions" is not a real figure. About seven real permit paths exist in LA County. The MVP is City of LA only.
- The registration fee is $441 (Ordinance 188796, Feb 23 2026). $89, $192 and $454 appear in older files and are not current.
- "41 days to approval" was said on the Oct 15 call and has no source. The City publishes no processing time.
- Deck baselines 60/50/30 and targets 85/65/55 are unsourced. Do not repeat them in the spec without a named source.

**Research to dispatch to Sonnet agents while grilling runs, output to `ai_docs/research/`:**
- Verify the free APIs respond today: County parcel REST, ZIMAS, LADBS Socrata, Census Geocoder. Log status codes and sample responses.
- CCPA obligations for a host-facing web app operated by a vendor: access, deletion, notice, consent. Primary sources only.
- Claude on Vertex AI: pricing per page for document reading and per conversation for the assistant, from the provider pages, sized to 7,200 document checks and 12,000 conversations over six months. Gemini as the comparison.
- Status of the City's time-limited STR program for second homes through 2028 (Council vote June 2026). If it is law before February, the primary-residence gate changes.
- Source for an average City processing time, if any exists.

**Rules for this repo:** in `CLAUDE.md`. Read it at the start of every session and after any compaction.
