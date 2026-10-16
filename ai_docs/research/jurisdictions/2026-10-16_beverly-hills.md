# Beverly Hills: short-term rental rules (research as of 2026-10-16)

Method: the adopting ordinance (city PDF) was downloaded and read in full text (pdftotext); the city's STR page and FAQ were read in a browser session; the state CEQA record was read for confirmation. The codified current text of the Beverly Hills Municipal Code (hosted by American Legal Publishing) was not opened; the ordinance text is the amending text. Anything not stated is marked `[UNVERIFIED]`. Not a legal opinion.

## 1. Status
- **Banned.** Short-term rentals are prohibited in all single-family and multi-family units citywide. A **12-consecutive-month minimum initial lease** is required (including guest houses and ADUs); month-to-month is allowed only after the initial 12 months. City page: https://www.beverlyhills.org/278/Short-Term-Rentals ; FAQ: https://www.beverlyhills.org/FAQ.aspx?QID=91
- No registration or permit program exists.
- Pending litigation (secondary, not read): a Bloomberg Law report dated 2026-08-31 says the Beverly Hills Vacation Rental Alliance sued in the Central District of California. https://news.bloomberglaw.com/litigation/property-owners-challenge-beverly-hills-short-term-rental-ban `[UNVERIFIED: status]`

## 2. Legal basis
- **Ordinance No. 25-O-2918**, "amending short term rental regulations (transient uses) for single family and multifamily residential zones". Introduced 2025-07-01 (Planning Commission Resolution No. 2076 on 2024-11-14); **adopted 2025-08-05; effective 2025-09-05** (31st day after passage). PDF: https://www.beverlyhills.org/DocumentCenter/View/12414 (saved: `ai_docs/refs/jurisdictions/beverly-hills/ordinance-25-O-2918.pdf`). State CEQA notice of exemption confirming the ordinance number: https://ceqanet.lci.ca.gov/2025100567 (saved: `ceqa-noe-ordinance-25-O-2918.pdf`). The city page cites "BHMC 10-3-508", which is the R-1.X zone article; the ordinance makes parallel edits across every residential zone article.
- Code locations: **Beverly Hills Municipal Code (BHMC) Title 10, Chapter 3 (Zoning)**: definitions "Single-Family Transient Use" and "Multi-Family Transient Use" in 10-3-100; per-zone "Businesses Prohibited; Minimum Initial Rental Periods" sections (10-3-406 for R-1, 10-3-508 for R-1.X, 10-3-607 for R-1.5, and so on through the multifamily zones, including R-4); enforcement 10-3-205, 10-3-206; administrative fines BHMC 1-3-311; new "Responsible Person" definition BHMC 1-2-1.
- Before the ordinance (secondary): single-family rentals under six months were limited and multifamily rentals of 30 days or more were allowed. `[UNVERIFIED: prior text not read]`

## 3. Permit or registration process and portal
- None. Complaint portal for reporting suspected STRs: https://complaints-str.deckard.com/beverlyhills-ca-str-complaints ; Code Enforcement 310-285-1000, bhcp@beverlyhills.org (city FAQ).

## 4. Fees (application / renewal)
- None (no program).

## 5. Primary-residence requirement and proof
- Not applicable. No primary-residence test; the rule is a minimum lease term.

## 6. Eligible and ineligible unit types
- No unit is eligible for transient use. "Single-Family Transient Use" covers a single-family residence, ADUs of a single-family residence, accessory structures, and features such as pools, game courts and yards, rented for less than 12 consecutive months. "Multi-Family Transient Use" is the same for multi-family units and their ADUs and features.
- Exclusions from the definitions: in-home caretakers; for single-family also Home Occupation uses (10-3-4302) and permitted filming and photography (4-3-101 et seq.).
- Historic-landmark exemption: reported by news during drafting; none appears in the adopted text I read. `[UNVERIFIED]`
- Rent-controlled and deed-restricted units: not addressed.

## 7. Night caps
- Not applicable; any stay under 12 consecutive months is prohibited.

## 8. Occupancy limits
- Not applicable.

## 9. TOT (rate and registration)
- No lawful STR TOT regime. The ordinance (10-3-205) requires responsible persons to remit to the City all Transient Occupancy Taxes that would have been due and to refund transient tenants all amounts paid. TOT rate for hotels `[UNVERIFIED]`.

## 10. Insurance
- Not applicable.

## 11. Platform obligations
- No platform-specific section. Reach is through the new "Responsible Person" definition (anyone who facilitates, aids or abets, including an agent or broker) and the rule that advertising or listing a transient use is itself a separate violation, "whether or not the actual location or address of the property is included" (BHMC 1-3-311(A)(2)). Whether the City treats platforms as Responsible Persons `[UNVERIFIED]`. Any person who collects and remits TOT may sue for an injunction and damages (10-3-206).

## 12. Penalties
- Administrative fine **at the maximum allowed under state law** for the first, second and each additional violation; each day of operation within a rolling 12 months is a separate violation; each day an ad or listing is visible is a separate violation (BHMC 1-3-311(A), ordinance Section 35). City FAQ: up to **$5,000 per day**. Also: public nuisance, refund of all amounts to transient tenants, remittance of TOT, civil or criminal action by City Attorney and City Prosecutor (10-3-205).

## 13. Processing time
- Not applicable.

## 14. Date the rule last changed
- Adopted **2025-08-05**, effective **2025-09-05** (ordinance footer). Earlier steps: Planning Commission 2024-11-14; Council introduction 2025-07-01.

## 15. Fields PermitPath's rules table needs
- `program_type` = `banned` (`min_lease_months` = 12 for SFR, MFR, ADU, accessory features); `registration_available` = false
- `ordinance_no` (25-O-2918), `adopted` (2025-08-05), `effective` (2025-09-05), `code_cite` (BHMC 10-3-100, per-zone 10-3-406/508/607... and 1-3-311)
- `month_to_month_after_initial_term` = true; `exclusions` (in-home caregivers, home occupation, filming)
- `ad_is_separate_violation` = true; `penalty_per_day_max` ($5,000 per city FAQ; "state max" in the ordinance); `refund_to_guest_required` = true; `tot_remittance_on_illegal_stays` = true
- `private_right_of_action` (TOT collectors, 10-3-206)
- `litigation_flag` = true (2026 federal suit, status [UNVERIFIED])
- `complaint_url`, `enforcement_contact`
