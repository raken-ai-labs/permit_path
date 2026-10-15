# PermitPath MVP definition (from the 2026-10-08 meeting prep; commercial sections removed)

Internal, for Rod. Sources: Antonio WhatsApp 10/7 (correspondence/), deck v2 p4, p6, p7, p11, p14, build spec v0, and research/2026-10-08_sourced-facts-super-bowl-mvp.md (URLs there). "Checked" = verified against the source text.

## The problem in one line
Almost half of first-time applications get denied: the City of LA denied 44% of new Home-Sharing registrations in FY2025 (2,045 of 4,619), and 43–46% every year since 2022 (City fee study, May 2026, checked).

## The deadline: Super Bowl LXI
- SoFi Stadium, Inglewood. Date Feb 14, 2027 per Wikipedia; not confirmed by the NFL.
- Last time at SoFi (Feb 2022): AirDNA counted 8,200+ LA-area rentals booked at ~$316/night, only 371 in Inglewood. Most demand lands in the City of LA, so a City-of-LA-first MVP fits.
- City processing time is not published; Airbnb's help page says "several weeks". Hosts need to file by about mid-December, so the tool needs to be live by about mid-November.
- Deck v2's Dec 14 go-live is too late to help a host list for the game.

| Release | Date | Contents |
|---|---|---|
| Super Bowl release | ~Nov 16 | Address check, five questions, plan with true cost, readiness self-check |
| Follow-up | ~Dec 14 | Renewal reminders, 30-day follow-up email, monthly report |
| Run | to ~June 2027 | Six months of operation |

## Proposed MVP: City of LA, "can I, what do I need, am I ready"
Keep (aimed at paperwork denials: 32% of surveyed hosts cite incorrect documentation, survey p6):
1. Address check → zoning, RSO and other hidden blockers, with a plain verdict (you can apply / you can't, here's why / check this first) and the rule cited. Deterministic, no model. RSO units are ineligible.
2. Five questions: primary residence, own or rent, landlord permission (renters need a notarized landlord affidavit), ADU, nights per year.
3. Personal plan and true cost: $441 registration (current since Feb 23, 2026, checked) plus $3.30 per night; 120 nights/year cap unless Extended ($883).
4. Readiness self-check without uploads: the host types the name and address exactly as printed on each document; we flag mismatches and missing proofs (photo ID plus one proof of residence if addresses match, two if not). No document storage, matching the 9/21 scope email.
5. Renewal reminders: host enters their registration date; email at 11 months with the renewal checklist. Cheap, recurring, protects listings that already earn.
6. Measurement: 30-day "did you get your permit?" email plus a monthly report against a holdout group.

Cut or defer (each one is a phase-2 conversation):
- Filing pack (the City portal is where hosts file; low value)
- Document upload and reading (liability, pen-test scope, model cost)
- AI assistant (or a narrow cited FAQ only if Airbnb ranks it top)
- Denial triage, co-host handoff, mid-term alternative
- Wait tracker, how-you-compare
- Renewal calendar and nights-vs-cap (needs Airbnb booking data)
- Multi-property view
- Airbnb dashboard (replaced by monthly report)
- Inglewood, Greater LA, other jurisdictions; "~97 rule sets"
- Expert-host knowledge capture

## What to ask in the room
1. Who uses it in phase 1: hosts directly, Airbnb support, or co-hosts?
2. Whose brand and terms does it run under?
3. What result after 6 months makes phase 2 a yes? Who provides the baseline and holdout?
4. Of the demo screens, which three would they keep if they could keep only three?
5. How long does the City take to approve a registration today? Does Airbnb know?
6. Will Airbnb email LA hosts to drive them to the tool, and when?
7. Inglewood: do they want the stadium area covered? (Separate rules: 365-day primary residence, 90 unhosted nights, up to 60 days processing.)
8. The City's temporary STR program through 2028 that Airbnb lobbied for: status, and will it land before February? It changes the rules we encode.
9. Did they see a permit bottleneck during the World Cup?

## Before the demo
- The true-cost screen shows "$454 a year, verified 18 Sep 2026". Current fee is $441; $454 is the proposed renewal fee in the City's May 2026 fee study. Fine to show, but don't call it verified.
- Don't show deck v2's p3 "54%" figure (32% + 22% from a multi-select question). Use the City's 44% denial rate instead.
