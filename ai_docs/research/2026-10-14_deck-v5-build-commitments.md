# Deck v5 (sent 10/14): what it commits the build to (internal, for Rod)

Source: `drafts/Propuesta_Airbnb_LA_Host_Permitting_Pilot_Deck_v5_2026-10-14.pdf`. The page numbers are the PDF pages. The printed footers skip a number from page 10 on.

## Team (p14)
- **Rod, product lead:** day-to-day lead with Airbnb. Owns the City of LA rules, the pilot specification and the checkpoints.
- **David Figueroa, UX and AI engineer:** flows, screens, the assistant and document checks.
- **Cloud architect:** unnamed. GCP production setup, security and releases.
- **Bilingual business analyst, half time:** Spanish QA, test scripts and tester sessions.

## Dates (p5, p11, p12)
| Date | Commitment |
|---|---|
| Oct 19 | Kickoff, triggered by the signed SOW. A signed spec comes before the build. |
| Nov 6 | Prototype |
| Nov 20 | MVP live (Nov 24 at the latest) |
| Dec 11 | Fast-follow |
| Dec 18 | Acceptance |
| Through May 20 | Service. Next-wave decision in April. |

- There's a holiday freeze on the timeline.

## Build commitments beyond Airbnb's 10/12 list
1. **"Connect to an expert on request"** (p4). Experts receive the full case file (p6). Airbnb didn't ask for this, and p15 lists expert routing for denials as out of scope. Clarify in the spec that it's a request form, not routing.
2. **Host sign-in** through Identity Platform (p6). This adds a login flow to the MVP.
3. **Infrastructure** (p6): Cloud Armor WAF, Cloud SQL, BigQuery with small-cell suppression, Cloud KMS, Secret Manager, and a separate staging environment.
4. **Privacy** (p7):
   - an explicit host consent step before any aggregate data is shared
   - a working process for CCPA access and deletion requests
   - a privacy review before go-live
   - automated security scanning before go-live and every month
5. **Run** (p3):
   - support Mon–Fri, 8–5 Pacific, with critical issues answered within 4 business hours
   - City of LA rule changes live within 5 business days
6. **Address verdict** (p4) includes a pre-purchase check, HOA and true cost.
7. **Change log** (p8): every change logged in plain language.

## Numbers to check before the SOW repeats them
- **Targets baseline (p10):** submission 60%, approval 50%, combined 30%, "from the May 2026 survey baseline". The City's own figures put first-time approval at about 56% (44% denied in FY2025). Confirm where 50% and 60% come from.
- **"~97 rule sets"** for Greater LA (p3). This was flagged earlier: the build spec found about 7 real jurisdictions.

## Who owns it
- **Commercial terms are Ramón's and Antonio's:** the Dec 31 payment, insurance and the MSA.
