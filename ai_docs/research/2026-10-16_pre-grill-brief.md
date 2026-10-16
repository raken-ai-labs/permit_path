# Pre-grill brief, Oct 16, 2026

Input to `/grill-with-docs`. Dated and done once the grill produces `GLOSSARY.md`, `docs/adr/`, `docs/spec/` and the tickets. Decisions recorded here become ADRs or glossary entries; nothing here is edited afterward. The Oct 15 kickoff prompt that started the project is retired.

## Dates committed to Airbnb (deck v5)

| Date | Commitment |
|---|---|
| Oct 19 | Kickoff, on the signed SOW. As of Oct 16 the SOW has not arrived. A signed spec comes before the build. |
| Nov 6 | Prototype |
| Nov 20 | MVP live. Nov 24 hard stop. The assistant may ship Nov 24. |
| Dec 11 | Fast-follow. Thanksgiving Nov 26 is inside the window. |
| Dec 18 | Acceptance |
| Through May 20 | Run. Next-wave decision in April. Holiday freeze applies. |

Pentest is before go-live, not after (see open decisions).

## Settled, do not reopen

From deck v5, the Oct 15 internal kickoff, and Rod on Oct 16.

- Rules are versioned data. Eligibility verdicts come from deterministic code over the rules table, never a model. Models handle intake, document reading, explanations and rules upkeep. Every verdict cites the rule and its source URL. Verdicts are readiness, never approval.
- Operator's direction: the pilot scope is what the UI shows; the platform underneath is built for the full concept (multi-tenant, a second customer provisioned without a rebuild). The Oct 15 kickoff also decided the foundation must not grow the five-week build. The grill settles where that line sits.
- Infrastructure (deck v5 p6): Raken's GCP, US region, Cloud Run, Cloud SQL, BigQuery with small-cell suppression, Cloud Armor, Cloud KMS, Secret Manager, Identity Platform for host sign-in, separate staging. Region within the US, data model and release process are open.
- Model provider: Gemini on Vertex AI, behind one model interface so the provider is swappable. Claude appeared in the demo and on deck p6 because Stefan chose it for the prototype; not a commitment. Do not spend the five weeks on a second provider. Cost is immaterial at pilot volume. Two consequences: the deck p6 privacy line ("Claude on Vertex, no training on host data") must be restated for Gemini before anything client-facing repeats it; Gemini's abuse-monitoring prompt logging (up to 30 days) needs the zero-data-retention exception requested from Google before go-live. Until confirmed in writing, host-facing copy says "not stored by PermitPath," not "stored nowhere."
- Privacy (deck v5 p7): explicit host consent before any aggregate data is shared, a working CCPA access and deletion process, a privacy review and automated security scanning before go-live and monthly. Documents are read in memory and discarded. Raken is the data controller, at arm's length from Airbnb.
- Run commitments (deck v5 p3, p8): support Mon–Fri 8–5 Pacific, critical issues answered within 4 business hours, City rule changes live within 5 business days, a plain-language change log, 3-level QA (technical, business, real users).
- Raken does not file the application. The tool prepares the host; the host files with the City.
- No multi-property in v1. Scope is deck v5 plus the MVP demo, nothing else before Dec 11.
- Free to hosts. Registration is optional and only saves progress. Premium features are a later conversation.
- Hosted on Raken's GCP, multi-tenant, holding PII. Raken keeps the IP; no source code goes to Airbnb.
- Antonio is quoting two law firms for terms and disclaimers; their output is input to the CCPA design, not a replacement for the decision.
- Second builder is David Figueroa. Spanish reviewer is David Mizrahi.
- Existing-host features (nights log, permit-expiry alerts) are host-entered with the host opting in. Keep an ingestion path for Airbnb booking data in the design; nobody has confirmed Airbnb will share it.
- Measurement and observability are built regardless of the holdout: Raken needs them for its own ROI reporting. Whether a holdout is exposed to Airbnb is a UI and contract decision.
- Intake home: sales and contract documents live in the SharePoint Ramón created. This repo's `ai_docs/intake/` is Rod's local working copy, never committed.
- Stefan's prototype is plain HTML generated with Claude. No front-end stack carries forward; UX reference only (`ai_docs/demo/archive/`).

## Open decisions for the grill

- Foundation line: what "built for scale, shown for the pilot" means in the data model and config (tenant ID, per-tenant rules and branding, feature flags per tenant) without growing the build.
- Address verdict data path: Census Geocoder, County parcel REST, City zoning layer. Query zoning by parcel centroid. ZIMAS has no API. RSO per address has no lookup: confirm "ask the host" per data item.
- Document checks: what the model extracts, how mismatches are flagged (name-consistency and two-category residency rules from Stefan's spec), how "not stored by PermitPath" is enforced and proven.
- Assistant: grounded only in the rules table and ordinance text, cited, hands off when it does not know. What the test set is. Nov 20 or Nov 24.
- Filing packet: generated PDF with cover sheet and checklist, no City portal integration. Confirm.
- Bilingual: machine translation plus one native review pass, or authored twice.
- Sign-in: anonymous use gives the full verdict and packet; registration via Identity Platform only saves progress. Decide what the anonymous path stores, given CCPA access and deletion rights for no-account users.
- Data model: what a case stores, retention per category, how BigQuery suppression works, CCPA identifier. Rules table fields the jurisdiction corpus implies: hosted-required, unhosted-allowed, per-class night caps, citywide or per-building caps, residency-days threshold, entity eligibility, ADU and rent-controlled handling per jurisdiction, coastal-zone flag, pending-change status with a date. Jurisdictions outside the City of LA get a "not covered yet" verdict in MVP.
- Measurement: which baseline the spec names. Three are in circulation (survey 25% first try, City 56% approved, deck 60/50/30 unsourced).
- Rules upkeep: who approves a rule change, how the five-business-day commitment is met, whether the rules-watch agent is MVP or later.
- "Connect to an expert on request" (deck v5 p4): in the demo this is a punch-out to book a co-host or an Airbnb contact. Decide whether MVP ships a request form, an outbound link, or nothing, and what of the host's case the punch-out carries (PSEC R05: consent, scope, expiry, logging).
- Readiness score: what it is computed from, how it avoids reading as a promise.
- Expert-host knowledge capture and workshops: Stefan raised it, nobody answered. Default is out of MVP.
- Product name: "PermitPath" is the working name.
- Releases: staging and production separation, how a release goes out, who can deploy.
- Pentest before go-live: the security sheet (R06, A24) dates it Dec 14 against deck v2, but MVP is Nov 20. Settle the window (on the Nov 6 prototype, remediation and retest before Nov 20), vendor, scope (web, API, hosts, assistant), and a retest before Dec 18 acceptance since Dec 11 adds modules.
- Security review (`ai_docs/intake/PSEC - RKN - REVISION SEGURIDAD PROPUESTA AIRBNB - V3 - 20261014.xlsx`, local only): 13 risks, 24 controls, 10 SDLC rules, each with a question and due date. Written against deck v2, so holdout, co-host handoff and multi-property items are stale. The rest are grill inputs: retention inventory, CMEK, logging rule, per-case assistant isolation, tenant isolation, pentest scope and dates, DPA sub-processor list, SSO for the Airbnb dashboard. Answers go back into the sheet.

## Correct before anything client-facing repeats them

- The City denied 44% of new regular registrations in FY2025; first-time approval is 56%. `ai_docs/research/2026-10-08_sourced-facts-super-bowl-mvp.md`.
- "97 jurisdictions" is not a real figure. Five to seven real permit paths exist in LA County. MVP is City of LA only.
- The registration fee is $441 (Ordinance 188796, Feb 23 2026). $89, $192 and $454 in older files are not current. Proposed changes ($404 application, $454 renewal) are not adopted.
- "41 days to approval" is colloquial survey feedback with no source. The City publishes no processing time. Do not use it.
- Deck baselines 60/50/30 and targets 85/65/55 are unsourced. Do not repeat them without a named source.

## Research, read before grilling

All in `ai_docs/research/`, dated 2026-10-16.

- `api-liveness`: Census, County parcel and City zoning layers answer live without keys. ZIMAS has no API. No home-sharing registration dataset exists. RSO per address has no lookup.
- `ccpa-obligations`: whether the Act applies turns on Raken's company-wide revenue (about $26.6M) or 100,000+ consumers. The readiness score is not regulated automated decision-making on its face; whether an STR permit is a "housing" decision is for counsel. Anonymous users keep access and deletion rights.
- `model-cost-comparison`: immaterial at pilot volume across every provider.
- `model-data-retention`: Google's abuse monitoring can keep prompts up to 30 days unless exempted; Cloud Logging's required bucket keeps 400 days.
- `2028-str-program-status`: not law, not drafted. Council file 25-0029-S1 pending in committee, no hearing scheduled, about six months to update the draft. A separate permit type if adopted. Watch item.
- `la-county-str-jurisdiction-survey`: one row for all 89 LA County jurisdictions, about ten confirmed, the rest `[UNVERIFIED]` because city and Municode sites block agents. Needs a browser pass later.
- `jurisdictions/`: twelve sourced city deep dives with identical headings; ordinance PDFs in `ai_docs/refs/jurisdictions/`. Provisional count five or six permit paths.
- Earlier: `2026-10-15_intake-review.md`, `2026-10-14_deck-v5-build-commitments.md`, `2026-10-08_sourced-facts-super-bowl-mvp.md`.
