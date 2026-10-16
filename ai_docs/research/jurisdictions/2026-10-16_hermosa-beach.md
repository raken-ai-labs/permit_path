# Hermosa Beach: short-term rental rules (research as of 2026-10-16)

Method: the city's STR page, TOT page, and the Notice and Summary and Notice of Adoption for Ordinance ORD-26-1502 were read directly in a browser session; the CEQA notice of exemption was downloaded and read. **The full text of ORD-26-1502 and of the new HBMC Chapter 5.84 could not be retrieved** (the "View full text" link was not exposed; the agenda packet is on the city's video and agenda system). So registration fees, caps, penalty amounts and facilitator duties are `[UNVERIFIED]`. Court history comes from secondary reports. Not a legal opinion.

## 1. Status
- **Split by geography.** Coastal Zone: STRs are **allowed with City registration** (new). Outside the Coastal Zone: **prohibited**, except the commercial-zone pilot areas listed on the city's page. City page: "In response to a recent legal decision, short-term rentals are now allowed in the coastal zone and in commercial zones previously established by the pilot program." Allowed areas: "coastal zone and ... properties zoned C-2, C-3, SPA 7, or SPA 8 outside of the coastal zone." https://www.hermosabeach.gov/doing-business/short-term-rentals
- **ORD-26-1502**, adopted **2026-09-08** (3-2: Keegan, Francois, Saemann yes; Detoy, Jackson no), effective 30 days after adoption (about 2026-10-08, my computation): "recognizes that short-term rentals may operate within the Coastal Zone consistent with a Los Angeles County Superior Court judgment, while continuing to prohibit short-term rentals outside the Coastal Zone." https://www.hermosabeach.gov/Home/Components/News/News/5788 . Introduced 2026-08-25 (https://www.hermosabeach.gov/Home/Components/News/News/5778).
- Council activity after adoption: at a later meeting (recap page, 2026-10-13 posting) members asked for a pause on implementing the ordinance pending review of its environmental analysis (no additional support). https://www.hermosabeach.gov/our-government/city-council/city-council-meeting-recap `[UNVERIFIED: exact meeting date]`

## 2. Legal basis
- Hermosa Beach Municipal Code (HBMC): **new Chapter 5.84** (short-term rental registration and operating requirements); **repeals HBMC 17.08.025 and 17.42.180** (the earlier prohibition and the commercial-zone pilot); **amends Chapter 3.32** (TOT). Ordinance **ORD-26-1502**. CEQA notice (state record, SCH 2026090732, posted 2026-09-17): https://ceqanet.lci.ca.gov/2026090732 (saved: `ai_docs/refs/jurisdictions/hermosa-beach/ceqa-noe-ordinance-26-1502.pdf`).
- Definition (city page, citing HBMC 17.04): rental of a residential dwelling, dwelling unit or room for compensation for less than 30 consecutive days.
- Prior ordinances noted in city notices: ORD-23-1468 (pilot extension), ORD-24-1473 (advertising definition; added HBMC 17.39.050; the shorter stated stay controls when an ad conflicts), ORD-25-1489 (extended pilot to 2027-10-25; its Section 17.42.180 is now repealed). Source index: https://www.hermosabeach.gov/Home/Components/News/News/3911 , .../4410 (titles only read in search results). `[UNVERIFIED]`
- The original ban (2016) was held unenforceable in the Coastal Zone because the City lacked Coastal Commission approval (secondary: https://www.hermosareview.com/court-rules-hermosa-beach-short-term-rental-ban-unenforceable/ ; https://www.angellaw.com/news/2024/08/hermosa-beach-stvr-ban-unenforceable/). Case, judgment date and terms: `[UNVERIFIED]`.

## 3. Permit or registration process and portal
- **Registration with the City** (Chapter 5.84), plus a City **business license** and TOT account. Required content per the notice: property owner and local emergency contact information, safety compliance. Registration portal and form: `[UNVERIFIED]`. Business license: apply through the city's business license page (link on the STR page). TOT portal: Deckard (city TOT page: https://www.hermosabeach.gov/our-government/finance-department/finance-administration/transient-occupancy-tax).
- 24/7 contact for maintenance and management must be provided (city page).

## 4. Fees (application / renewal)
- `[UNVERIFIED]` (not stated on city pages read).

## 5. Primary-residence requirement and proof
- None stated. `[UNVERIFIED: Chapter 5.84 text not read]`

## 6. Eligible and ineligible unit types
- Eligible by location: any property in the Coastal Zone; outside it, only C-2, C-3, SPA 7 and SPA 8 (city page). An older application form (via search snippet) limited the pilot to nonconforming units in commercial zones legally established before 2025-10-24. `[UNVERIFIED]`
- ADU, rent-control, deed-restriction and multifamily treatment: `[UNVERIFIED]`.

## 7. Night caps
- None stated. `[UNVERIFIED]`

## 8. Occupancy limits
- None stated. `[UNVERIFIED]` Guest guidance: quiet after 10:00 p.m.; park on site; trash rules (Good Neighbor Guidelines on city page; guidance, not shown to be law).

## 9. TOT (rate and registration)
- **14%** of rent for hotels, motels, hostels, hospitals or short-term rentals (HBMC 3.32.030). City now collects short-term rental TOT through the Deckard portal. A business license is required. ORD-26-1502 amends Chapter 3.32; the changes are `[UNVERIFIED]`. https://www.hermosabeach.gov/our-government/finance-department/finance-administration/transient-occupancy-tax

## 10. Insurance
- `[UNVERIFIED]`

## 11. Platform obligations
- ORD-26-1502 "establishes ... reporting, auditing, and listing requirements for short-term rental facilitators" (city notice). Specifics `[UNVERIFIED]`. Earlier ordinance 24-1473 expanded the advertisement definition (secondary summary).

## 12. Penalties
- Ordinance "establishes nuisance enforcement provisions" (notice). Amounts `[UNVERIFIED]`. A news report of the earlier regime cited fines up to $15,000 for advertising/operating; not verified and tied to repealed text.

## 13. Processing time
- Not stated.

## 14. Date the rule last changed
- **2026-09-08** adoption of ORD-26-1502; effective about **2026-10-08** `[UNVERIFIED: city confirmation]`. Possible implementation pause requested after adoption.

## 15. Fields PermitPath's rules table needs
- `program_type` = `registration_coastal_zone_only` (outside coastal zone: `banned`, with `commercial_zone_exception` = [C-2, C-3, SPA 7, SPA 8]); `coastal_zone_flag` drives the rule
- `ordinance_no` (ORD-26-1502; earlier 24-1473, 25-1489), `code_cite` (HBMC 5.84; 3.32; 17.04; repealed 17.08.025, 17.42.180), `adopted` (2026-09-08), `effective` (~2026-10-08, [UNVERIFIED])
- `registration_required` = true; `business_license_required` = true; `owner_contact_required` = true; `local_emergency_contact_24_7` = true
- `fee_registration`, `fee_business_license`, `fee_renewal` = [UNVERIFIED]
- `tot_rate` (14%), `tot_code` (3.32.030), `tot_portal` (Deckard)
- `platform_duties` (reporting, auditing, listing requirements; detail [UNVERIFIED])
- `night_cap`, `occupancy`, `primary_residence`, `insurance`, `penalty_amounts`, `processing_time` = [UNVERIFIED]
- `litigation_flag` (Coastal Zone judgment; pending council pause request); `watch_url` (council recap page)
