# Airbnb's ask (10/12): scope changes, team, week-by-week plan (commercial sections removed)

Source: correspondence/2026-10-12_email_airbnb-feedback-150k-nov20.md. 

## What changed vs our 10/8 MVP
- **Added for Nov 20:**
  - document checks (upload and reading)
  - the assistant
  - the filing packet
  - Spanish
- We had cut or deferred all four.
- **Added for Dec 11:** program dashboard and nights log. Renewal reminders were already in.
- **Timeline:** kickoff Oct 19 to Nov 20 is **5 weeks**. Nov 24 is the hard stop. Dec 11 is 3 more weeks, with Thanksgiving (Nov 26) inside them.

## Technical levers that cut hours without cutting what they asked for
- Reuse Stefan's demo front end. It's already in the estimate.
- Keep the assistant narrow: answers only from the LA rules table, with a citation, and hands off when it doesn't know.
- Make the filing packet a generated PDF. No City portal integration.
- Build the dashboard in Looker Studio on BigQuery, not custom.
- Spanish: machine translation plus one native review pass.
- RSO: ask the host when the lookup fails. No pipeline.
- Release order: on Nov 20, the address verdict, plan, document checks, readiness and filing packet in EN and ES. The assistant ships Nov 24 if needed, which is within their stated window.

## Capacity (their numbers)
- **Document checks:** 7,200 total = 1,400 hosts × about 5 documents. Read "document check" as one document, and confirm that.
- **Pooled capacity** is fine technically. The cost of a spike is model usage, not infrastructure.
- **Address checks:** 18,000. Geocoding and parcel lookups are cheap at that volume. RSO lookups are the unknown.

## Update 10/12: the build team is Rod and David, with Claude Code (Rod)
- The hours table above is a traditional estimate. With Claude Code, the coding compresses. The work that doesn't compress sets the pace.
- **Capacity:** 2 people × about 50 h × 5 weeks ≈ 500 hours by Nov 20, plus about 300 hours by Dec 11.

**What doesn't compress, and who owns it**
| Work | Owner |
|---|---|
| LA rules verified against City sources, with a person signing off | Rod, or Angel if he takes it |
| Spanish review by a native speaker | Antonio or Angel |
| Airbnb meetings, the 2-day feedback loop, bi-weekly checkpoints | Antonio runs them, Rod attends |
| Tester rounds and fixes | Rod and David |
| Security and privacy review before going public | Rod, plus a pen test if required (Ramón) |
| Real data: ZIMAS, parcel, RSO lookups | David |

**Week by week**
| Week | Build |
|---|---|
| Oct 19 | GCP setup, port Stefan's front end, LA rules table, address verdict |
| Oct 26 | Questions and plan, document checks |
| Nov 2 | Readiness score, filing packet, assistant |
| Nov 9 | Spanish, security pass, first tester round |
| Nov 16 | Fixes, **launch Fri, Nov 20** (backstop Tue, Nov 24) |
| Nov 23 – Dec 11 | Nights log, renewal reminders, dashboard (Thanksgiving Nov 26) |
| Dec 11 – Jun 2027 | Run |

**Biggest risks with two builders**
- Rules accuracy.
- RSO data with no API.
- Airbnb's review speed.
- One person out sick for a week.
