# Intake review: what the trail says as of Oct 15 (commercial figures removed)

Internal, for Rod. Written 2026-10-15 after reading every file in `ai_docs/intake/` (kept and archived), `ai_docs/research/` and `ai_docs/refs/`. Sources are named by filename. Pricing, milestones in dollars, insurance and payment terms stay in `ai_docs/intake/` and are not repeated here. `[UNVERIFIED]` = stated somewhere, not checked against a primary source.

## Timeline

| Date | Event | Source |
|---|---|---|
| Sep 17 | Stefan's Rules Engine Spec: ten City of LA gates, two tiers, document specs, five-entity data model. No URLs, titles only. | `LA STR Permitting - Rules Engine Spec.docx` |
| Sep 21 | Scope confirmation to Airbnb: 18 capabilities (text says 17), six decisions: no document custody, readiness rubric with cohort comparison, coverage limited to what can be verified, buyers included, renters evaluated but not guided, stops at a validated filing pack. | `Airbnb_Scope_Confirmation_2026-09-21_preview.pdf` |
| Sep 25–27 | Internal review of the scope email. An unsent draft asserts the $192 fee (since corrected). | `2026-09-25_...`, `archive/2026-09-27_...` |
| Oct 7 | Deck v2: Greater LA, "~97 rule sets," go-live Dec 14, Spanish out of scope. Same day Antonio learns Airbnb's budget. | `archive/Propuesta_..._Deck_v2_...`, `2026-10-07_whatsapp_...` |
| Oct 8 | Decision to demo Stefan's original. Rod's unsent phase-1 cut: City of LA only, typed readiness check, no uploads, no assistant. | `2026-10-08_whatsapp_antonio-rod-demo-choice.md`, `archive/2026-10-08_whatsapp_rod-to-antonio_...` |
| Oct 12 | Airbnb confirms a fixed budget and asks for the full feature list by Nov 20: address verdict, plan, document checks (upload and reading), readiness score, filing packet, assistant, English and Spanish. Kickoff Oct 19 on signed SOW. | `2026-10-12_email_airbnb-feedback-*.md` |
| Oct 14 | Deck v5 sent: City of LA only, Nov 20 MVP (Nov 24 latest), Dec 11 fast-follow, Dec 18 acceptance, run to May 20. Architecture on p6, privacy on p7, 3-level QA on p8. SOW not yet received. | `Propuesta_..._Deck_v5_2026-10-14.pdf`, `2026-10-14_email_revised-proposal-sent.md` |
| Oct 15 | Internal kickoff call, 38 min. Decisions and quotes below. | `AirBnB Project Kick off.docx` (transcript), `2026-10-15_meeting_internal-kickoff.md` (notes) |

## What the Oct 15 call settled that the notes soften

- The platform is Raken's. Ramón (7:01): "not an Airbnb platform, is going to be a Raken platform." Antonio (7:43): no NDA restriction, "it could work for Vrbo." Stefan (8:09): the concept is expert knowledge into a process, same shape as his refinery proposal. Ramón (30:29): city-funded permitting for builders is the larger market.
- Free and complete without registration. Antonio (28:10): registration only saves progress. Premium features later; AI chat named as a candidate.
- Rod (22:23): Raken's GCP, multi-tenant, PII, "start with a good foundation," provisionable for Expedia or Vrbo.
- Rod (26:12): Raken's IP, no source code to Airbnb. David Figueroa named as the data scientist on the build.
- Antonio (25:45): two law firms being quoted for terms and disclaimers.
- Ramón (21:53) will create a repository and chat "same as the other projects." Antonio (20:51) asked for a SharePoint or OneDrive. Rod is standing up GitHub. Three homes were named; nobody reconciled them.

## Statements on the call with no source

- "About 41 days to get an approval" (Rod, 10:25). Every research file says the City publishes no processing time. The Airbnb help page says "several weeks." `[UNVERIFIED]`
- "Tracking at 70, 80% first-time success" (Rod, 10:25). A target, not a figure. Deck v5 p11 says targets are not a guarantee.
- "97 jurisdictions" (Stefan, 0:50). Known inflated: the public-data scan found about seven real permit paths. LA County is 88 cities plus unincorporated areas.
- "40 something percent" first-time success (Rod, 10:25). The City figure is 56% approved, 44% denied, FY2025. See `2026-10-08_sourced-facts-super-bowl-mvp.md`.

## Three baselines in circulation

| Figure | What it is | Source |
|---|---|---|
| 25% approved first try, 75% needed two or more attempts | Host self-report, 657 responses, May 2026 | `LA Host Permitting Survey Final.pdf` p3 |
| 56% approved, 44% denied, new regular registrations FY2025 | City fee study, checked | `2026-10-08_sourced-facts-super-bowl-mvp.md` |
| 60% submission, 50% approval, 30% combined | Deck baseline, unsourced; "46%" in the Sept 18 session is not in the survey either | Deck v5 p11; scope confirmation Part D |

The spec Airbnb signs has to pick one and say what it measures. The survey and City numbers measure different things (hosts vs. applications).

## Fee drift

$89 (2019 FAQ), $192 (Article 15 v2025.1.0, read Sept 27), $441 (Ordinance 188796, adopted Feb 23 2026, checked Oct 8), $454 (proposed renewal, May 2026 fee study). The current fee is $441. Files that still carry stale figures: the primer's "Verified 2026-09-27" section ($192), the Rules Engine Spec ($89 and $192), the demo HTML ($454 "verified"). The primer now carries a correction note.

## Document-level contradictions

- The MVP demo guide (archived) puts renewal reminders and a monthly report in phase 1 and no uploads until phase 2. Deck v5 is the reverse. The guide is stale.
- Deck v5 drops the 20% holdout and formal baseline (p16). `KICKOFF_PROMPT.md` still listed holdout measurement. Resolved in the prompt: no holdout unless the grilling reinstates it.
- Deck v2 promised an independent pen test; v5 has automated scanning before go-live and monthly. The Oct 12 plan still says "pen test if required."
- Deck v5 p6 names Cloud Run and Claude on Vertex AI. The kickoff prompt listed both as open. Now treated as decided, with Gemini as a fallback behind the same interface.
- "Connect to an expert" (v5 p4) vs. "expert routing out of scope" (v5 p16). The prompt says request form only.
- The rules engine spec flags a Vacation Rental Ordinance that would let second homes register through 2028, at PLUM in March 2026, outcome unconfirmed. If it lands before February the primary-residence gate changes. Status unknown. `[UNVERIFIED]`
- "Eric" on the call is probably Erich Cisneros Hegewisch from the Oct 14 email. Not confirmed.

## What is settled, by document

- Deck v5 p4: Nov 20 scope is address verdict (RSO, zoning, HOA, true cost), requirements plan, document checks, readiness score, guidance and filing packet, assistant with sources and expert request, English and Spanish. Dec 11: program dashboard, nights log, renewal reminders.
- Deck v5 p16 out of scope: other jurisdictions, denial triage, mid-term alternative, multi-property, formal holdout, City-wide baseline, TAM, wait tracking, filing for hosts, appeals, legal advice, storing host documents, Airbnb integration beyond links and aggregates.
- Deck v5 p6–7: GCP, US region, Cloud Run, Claude on Vertex AI, Cloud SQL, BigQuery with small-cell suppression, Cloud Armor, Identity Platform, KMS, Secret Manager, staging, documents in memory only, Raken as data controller at arm's length.
- Deck v5 p3, p8: support Mon–Fri 8–5 Pacific, critical issues within 4 business hours, rule changes live within 5 business days, plain-language change log, 3-level QA (technical, business, real users).
- Scope confirmation Sept 21, six decisions above. Deck v5 does not contradict any of them.

## Open, for Rod

1. Holdout: gone per v5. Is measurement the monthly report alone?
2. Airbnb booking data for the Dec 11 nights log and renewals: nobody has said yes. Is "host enters it" the answer?
3. The second builder: David Figueroa (v5 p15 "UX and AI engineer," call "data scientist")? Is Angel the cloud architect?
4. Stefan's front end: the Oct 12 plan says porting it is in the estimate. Only static demo HTML is in intake. Is there a codebase, and in what stack?
5. The 2028 ordinance: has anyone checked status since June?
6. Spanish reviewer: David Mizrahi (kickoff prompt), Antonio or Angel (Oct 12 plan), or the half-time bilingual analyst (v5 p15)?
7. Intake home: Ramón's repository, Antonio's SharePoint, or this repo's local-only folder?
