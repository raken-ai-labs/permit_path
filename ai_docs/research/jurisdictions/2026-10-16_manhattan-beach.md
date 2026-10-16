# Manhattan Beach: short-term rental rules (research as of 2026-10-16)

Method: the city's STR page, the ordinance PDF (scanned, read as images), the city's TOT page and the 2026-01-20 Council meeting transcript (Granicus) were read directly in a browser session. The vote tally for 2026-01-20 comes from a news report (secondary). MBMC text was not opened; ordinance 19-0007 is the amending text. Anything not stated is marked `[UNVERIFIED]`. Not a legal opinion.

## 1. Status
- **Banned in residential zones outside the Coastal Zone; effectively not banned inside the Coastal Zone.** City page: "On April 4, 2022, the Court of Appeal issued an opinion that the City's ban of short-term rentals does not apply to properties within the Coastal Zone. Short-term rentals are still banned outside of the Coastal Zone." https://www.manhattanbeach.gov/departments/community-development/planning-zoning/short-term-vacation-rentals
- Coastal-Zone STRs are therefore tolerated but **must obtain a City business license and levy, collect and remit TOT** (same page). No dedicated permit program or caps exist. Eligibility questions go to Planning, (310) 802-5520.
- **2026 World Cup pilot rejected.** The Council considered a temporary allowance outside the Coastal Zone (staff proposal reported as June 5 to July 17, 2026, 450-license cap). At the 2026-01-20 meeting the Council declined it: news report says the motion failed 3-2. Meeting transcript: https://manhattanbeach.granicus.com/TranscriptViewer.php?view_id=4&clip_id=5148 ; report: https://www.thembnews.com/2026/01/20/560984/manhattan-beach-puts-kibosh-on-short-term-rental-proposal `[UNVERIFIED: vote count and later action; the transcript shows discussion, not the tally I extracted]`. Note: the city STR page itself still carried the pre-hearing notice when read.

## 2. Legal basis
- **Ordinance No. 19-0007** (adopted **2019-04-16**), adding **Manhattan Beach Municipal Code (MBMC) Chapter 4.88 "Transient Uses Including Short-Term Rentals"** (Title 4). PDF: https://www.manhattanbeach.gov/home/showpublisheddocument/39761/636934295093700000 (saved: `ai_docs/refs/jurisdictions/manhattan-beach/ordinance-19-0007.pdf`, scanned). Effective date `[UNVERIFIED]`.
- **Resolution No. 19-0011** (administrative remedies / fine schedule): https://www.manhattanbeach.gov/home/showpublisheddocument/39759/636934267541200000 (not downloaded; amounts not read).
- Zoning basis: the zoning code does not allow transient uses in residential zones (city page). Earlier Ordinances 15-0009 and 15-0010 (2015-06-16) kept the prohibition. TOT: **MBMC Chapter 8.20**.
- Court: Court of Appeal opinion of 2022-04-04 (city page; case name per news secondary sources, not verified here). The ban cannot be enforced in the Coastal Zone without a Local Coastal Program amendment certified by the Coastal Commission.

## 3. Permit or registration process and portal
- No STR permit. Business license from Revenue Services Division (Coastal Zone operators). Portal for the license: `[UNVERIFIED]`.

## 4. Fees (application / renewal)
- Business license fee: `[UNVERIFIED]`. No STR-specific fee.

## 5. Primary-residence requirement and proof
- None.

## 6. Eligible and ineligible unit types
- Outside the Coastal Zone: no unit eligible ("transient use" = rental of a single-family or multi-family unit for less than 30 days). Inside: no unit-type rule in the sources read. Council members at the 2026-01-20 hearing referred to ADU or guest-house restrictions in the proposed pilot; not law. `[UNVERIFIED]`

## 7. Night caps
- None stated.

## 8. Occupancy limits
- None stated.

## 9. TOT (rate and registration)
- **14%** (MBMC 8.20); operators of lodging establishments, including short-term rental operators, levy, collect and remit it; administered by Revenue Services. https://www.manhattanbeach.gov/departments/finance/revenue-services/transient-occupancy-tax-5063 . Registration steps and filing frequency `[UNVERIFIED]`.

## 10. Insurance
- None stated.

## 11. Platform obligations
- MBMC 4.88.030 (Ord. 19-0007): platforms must disclose to the City on a regular basis each listing, responsible persons, address, length of stay and price (subject to law); must not complete a booking transaction for any residential property while receiving a fee (i.e., for listings the ordinance bans); must not take ancillary fees (insurance, concierge, cleaning, tours and similar); safe harbor for compliant internet platforms except for subpoenas; interpreted subject to federal and state law. The City may issue administrative subpoenas (4.88.040(b)), with 30 days to respond.
- Enforcement practice: the staff answers at the 2026-01-20 hearing describe use of listing-monitoring software; most citations are for the listing itself (transcript).

## 12. Penalties
- Violation is a public nuisance and a misdemeanor under MBMC 1.04.010, prosecutable as an infraction or misdemeanor at the City Prosecutor's discretion; administrative citations under Chapter 1.06 per a fine schedule set by the Council; prevailing party attorney fees in civil actions (4.88.040(a)). Maintaining an advertisement is itself unlawful (4.88.020). A secondary source reports $1,000 per day; amount `[UNVERIFIED]` (Resolution 19-0011 not read).

## 13. Processing time
- Not applicable.

## 14. Date the rule last changed
- Ordinance 19-0007 on **2019-04-16**; judicial limit on the ban's reach (Coastal Zone) **2022-04-04**; World Cup proposal declined **2026-01-20** (per news; transcript shows discussion).

## 15. Fields PermitPath's rules table needs
- `program_type` = `banned_outside_coastal_zone` / `unregulated_inside_coastal_zone` (split by `coastal_zone_flag`); `registration_available` = false (business license + TOT only)
- `ordinance_no` (19-0007; 15-0009/15-0010), `code_cite` (MBMC 4.88; 8.20; zoning), `adopted` (2019-04-16)
- `coastal_zone_ruling_date` (2022-04-04), `coastal_lookup_url` (city zoning map / GIS)
- `business_license_required` = true (coastal), `tot_rate` (14%), `tot_code` (8.20)
- `platform_duties` (disclosure; no booking for banned listings; no ancillary fees; safe harbor; subpoenas)
- `penalty` (misdemeanor/infraction; admin citation schedule [UNVERIFIED]); `advertising_is_violation` = true
- `pending_changes` (2026 World Cup pilot rejected 2026-01-20; watch for LCP amendment)
- `night_cap`, `occupancy`, `insurance` = none stated
