# Redondo Beach: short-term rental rules (research as of 2026-10-16)

Method: the city's business-license "Short Term Rentals Not Permitted" form (PDF), Code Enforcement page and rental-property page were read directly; the Redondo Beach Municipal Code on ecode360 was searched in a browser session (no STR article exists there); TOT text read on ecode360. A search engine surfaced a Coastal Commission report about "short-term rentals" under Ordinance 3861 that I opened and found concerns the **City of Torrance**, not Redondo Beach; it is not used here. Anything not stated is marked `[UNVERIFIED]`. Not a legal opinion.

## 1. Status
- **Banned in residential zones; no permit program.** City Code Enforcement page: "Short term/vacation rentals are not allowed. (Airbnb rentals, less than 30 days)". https://redondo.org/departments/police/services/code_enforcement.php
- Basis (city form): the zoning code "does not allow transient uses, including short-term rentals (less than 30 days), in residential zones", because stays of 30 consecutive days or less fall within the use classification "hotel or motel" (RBMC 10-2.402(a)(94)), which is not a permitted use in R-1, R-1A, R-2, R-3, R-3A, RMD, RH-1, RH-2 or RH-3 (RBMC 10-2.501, 10-2.511). https://redondo.org/Financial%20Services/RB%20SHORT%20TERM%20RENTAL%20NOT%20PERMITTED%20Fillable.pdf?t=202606181245150 (saved: `ai_docs/refs/jurisdictions/redondo-beach/str-not-permitted-notice.pdf`).
- Business license: every rental-property license applicant must sign the "Short Term Rentals Not Permitted" acknowledgment; a violation "shall be justification for the cancellation of my business license" and the owner bears legal fees (city form; rental-property page https://redondo.org/departments/financial_services/rental_property.php).
- Commercial zones: not examined; the form addresses only residential zones. `[UNVERIFIED: any zone where a hotel-type use is allowed would permit STR-like lodging as a hotel]`

## 2. Legal basis
- **Redondo Beach Municipal Code (RBMC) Title 10, Chapter 2 (zoning)**: 10-2.402 definitions, 10-2.501 (R-1, R-1A land use table), 10-2.511 (multi-family tables); the tables state that a use "not listed ... is not permitted". Code host: https://ecode360.com/42654131 (customer RE4995). In-browser searches of the code for "short-term rental", "vacation rental", "Airbnb" and "home sharing" returned no STR provision.
- No STR ordinance number exists. ADU rule (secondary summary of city ADU page): ADUs cannot be rented for fewer than 30 days. `[UNVERIFIED: not read on the city page]`

## 3. Permit or registration process and portal
- None.

## 4. Fees (application / renewal)
- None for STR. Rental-property business license (long-term rentals): $20 tax + $4 SB 1186 fee for the first unit ($24 total), $8 per additional unit, $18 per employee (city rental-property page).

## 5. Primary-residence requirement and proof
- Not applicable.

## 6. Eligible and ineligible unit types
- None eligible in residential zones. ADU: see above.

## 7. Night caps
- Not applicable.

## 8. Occupancy limits
- Not applicable.

## 9. TOT (rate and registration)
- RBMC Chapter 8-2 (Uniform Transient Occupancy Tax): tax "of up to 12%" of rent for occupancy in any hotel (8-2.03); registration under 8-2.06; original Ord. 1852 c.s. (1964). https://ecode360.com/42663310 . Current set rate within "up to 12%" `[UNVERIFIED]`. No STR-specific TOT mechanics.

## 10. Insurance
- Not applicable.

## 11. Platform obligations
- None found.

## 12. Penalties
- No STR-specific schedule found. City enforcement ladder (Code Enforcement page): education, correction notices, citations, then criminal prosecution or civil injunction through the City Prosecutor; license cancellation for license holders. Amounts `[UNVERIFIED]`. Code Enforcement 310-697-3665.

## 13. Processing time
- Not applicable.

## 14. Date the rule last changed
- No STR-specific adoption date found. The city's PDF URL carries a 2026-06-18 timestamp parameter (suggests the form was refreshed then; `[UNVERIFIED]`). Underlying zoning classification predates 2026.

## 15. Fields PermitPath's rules table needs
- `program_type` = `banned` (`ban_basis` = hotel/motel classification not permitted in residential zones); `registration_available` = false
- `code_cite` (RBMC 10-2.402(a)(94), 10-2.501, 10-2.511; 8-2 TOT), `ordinance_no` = none (no STR ordinance)
- `license_condition` = signed acknowledgment; `license_cancellation_on_violation` = true
- `adu_str_banned` = true [UNVERIFIED source: summary]
- `tot_rate_max` (12%), `tot_code` (8-2.03)
- `enforcement_contact` (310-697-3665); `penalty_amounts` [UNVERIFIED]; `last_changed` [UNVERIFIED]
- `coastal_zone_note` = unlike Manhattan Beach and Hermosa Beach, no Redondo court or Coastal Commission ruling found `[UNVERIFIED: search limited]`
