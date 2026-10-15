# Permit Path build spec (draft v0, 2026-09-26)

Internal, for Rod. Where we are going, not what exists. Builds on Stefan's Rules Engine Spec (source/, 9/17) and the draft's 18 capabilities grouped into 6 phases. Prices come from a Sonnet agent scan and need checking on primary pages before any quote. [UNVERIFIED] = not confirmed.

## Principle
The rules are data, and the agents read them. Hard eligibility calls come from deterministic code over a versioned rules table, never from the model. LLMs handle intake, documents, explanations, denial reading, and keeping rules current. Every verdict cites the rule and its source_url.

## Agents by phase

| Phase | Capabilities (draft #) | Agent job | Deterministic part | Data (cost) |
|---|---|---|---|---|
| 1. Screening | 1 address check, 2 pre-purchase, 3 hidden blockers, 4 true cost | Intake conversation: gathers host profile (primary residence? owner/renter? ADU?) | Geocode → APN → jurisdiction → run gates (hard / curable / unknown) | Census Geocoder (free); LA County parcel REST (free); ZIMAS zoning REST (free); LADBS code enforcement Socrata (free); RSO per unit: no API, only ZIMAS lookup/unofficial layer (gap) |
| 2. Documentation | 5 requirement plan, 6 doc readiness, 7 guided progress, 8 filing pack | Document agent: reads uploads, extracts name/address/dates, flags mismatches (the #1 denial cause, survey p6) | Name-consistency and residency-proof rules from the spec; checklist per PermitTier | Claude/Gemini vision (in LLM cost) first; Document AI OCR $1.50/1k pages as a fallback |
| 3. Tracking | 9 how you compare, 10 waiting period | Status explainer | Timeline thresholds per jurisdiction | Benchmarks need Airbnb/host data (not public) |
| 4. Denial mgmt | 11 denial triage, 13 expert handoff, 14 mid-term alternative | Denial agent: reads the denial letter, classifies it against the survey's reasons, drafts the fix or appeal, builds the handoff case file | Pivot to 30+ nights on a hard fail | Letters uploaded by hosts; the expert network is Airbnb's |
| 5. Renewal | 17 renewal calendar | Reminder agent | Expiry dates, night counts vs cap | Night counts from Airbnb booking data (not public) |
| 6. Reporting | 15 multi-property, 16 program dashboard, 18 evidence program | None needed at first | SQL / BI | Our own logs + Airbnb data |
| Cross-cutting | 12 guidance assistant | RAG over the rules table and ordinance text, with citations | none | — |
| Back office | (not in the draft; this is the real product) | Rules-watch agent: monitors ordinances and council agendas, drafts rule-table diffs for human approval | Versioned rules with effective_from/to and last_verified | Legistar Web API (free; LA client name [UNVERIFIED]); city pages/Municode by scraping (no API); state bill text on leginfo |
| Knowledge capture | experts (Stefan's acervo idea) | Interview agent: records experienced hosts' case-by-case know-how and turns it into candidate rules or tips for review | Human approval before anything goes live | Airbnb's co-host network |

## Jurisdiction scope (from the public-data scan)
Real permit paths: LA City, unincorporated County, Santa Monica, Pasadena, Long Beach, Glendale, Malibu, WeHo (temporary emergency rule). No path to guide: Beverly Hills (banned), Culver City and Burbank (no ordinance). Recommend R1 = LA City only, then add jurisdictions one at a time. "97" is not a real figure; the county has 88 cities plus unincorporated areas.

## Free vs paid

Free and good enough: Census Geocoder, LA County parcel REST, ZIMAS zoning, LADBS Socrata, Legistar, Inside Airbnb (CC BY, static CSV).

Paid, only if needed: Google Address Validation ($17/1k after 5k free), Regrid ($0.10–0.15/parcel over 2k/mo), ATTOM (~$500/mo, quote [UNVERIFIED]), AirDNA (enterprise, ~$50k/yr [UNVERIFIED]).

No API anywhere: per-unit RSO status, Ellis Act list, TOT registration (City Finance, County TTC), any permit registry. Workarounds: ask the host, use ZIMAS lookup, or have Airbnb push for SB 346 data.

## Run-cost estimate at 10k host sessions/month (agent math, rough)
- LLM: 5 turns × (3k in + 1k out) per session → ~150M in / 50M out tokens a month. Sonnet ≈ $800/mo; Flash-class much less; caching cuts 50–90%. Model prices come via an aggregator [UNVERIFIED].
- Document OCR fallback: 9k pages ≈ $15 (OCR) to $270 (form parser).
- Hosting (GCP): [not estimated].
- The real cost is people: keeping rules current across ~7 jurisdictions and reviewing rule diffs. Price it as an ongoing service.

## Open build questions
1. Does Airbnb give us booking and night data (renewal, benchmarks)? Is it in-app or standalone?
2. Model choice: Gemini (GCP-native, cheap Flash) or Claude (better reasoning on denial letters)? Both could sit behind one interface.
3. Who approves rule changes: us or an Airbnb policy person?
4. Liability: verdicts are "readiness," never "you will be approved" (per the spec's scoring model).
5. How do we get RSO status without an API?
