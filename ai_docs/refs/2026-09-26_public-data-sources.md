# Public data sources for LA STR permitting (2026-09-26)

Sonnet agent, single-attempt fetches. Low confidence where only search snippets were available (planning.lacity.gov PDFs returned 403 to bots).

## Confirmed pullable
- LA County parcels (APN, address, city): https://public.gis.lacounty.gov/public/rest/services/LACounty_Cache/LACounty_Parcel/MapServer/0 — 200, ArcGIS REST, no key, weekly. Full roll monthly at egis3.lacounty.gov.

## Public, but web or PDF only
- LA City ordinance/FAQ (120-night cap, primary residence, Extended tier): PDF, 403 to bots.
- LA City fees: official schedule PDF not fetched. $89 vs $199 registration; Extended $850/$5,660.
- RSO status: ZIMAS per-parcel; undocumented ArcGIS layer (unofficial).
- Ellis Act: per-property lookup only, no bulk list.
- Unincorporated County: TTC registration, 90-night cap, 12% TOT; no registry download.
- SB 346 (eff. 2026-01-01): cities with a conforming ordinance can compel platforms to report address/APN/listing URL, at least quarterly; up to $10k/day fines.

## Not found
- LA City home-sharing registrant dataset (the ID tried was the wrong dataset).
- A bulk STR registry for any city.
- "97 jurisdictions" in any source. LA County = 88 cities + unincorporated.

## City rules
| City | Status |
|---|---|
| Santa Monica | Hosted home-share only; registry possibly on data.smgov.net [UNVERIFIED] |
| West Hollywood | Owner-occupied; temporary wildfire emergency ordinance |
| Malibu | Permit per unit, $495, septic required |
| Beverly Hills | Banned (12-month minimum) |
| Pasadena | Hosted + unhosted (90 nights); Deckard portal |
| Culver City | Under 30 days prohibited; ordinance in proposal |
| Long Beach | Registration; non-primary cap 800 (350 coastal) |
| Burbank | No ordinance; not a permitted use |
| Glendale | Hosted-only license; ADUs and RSO excluded |

## Added 2026-10-16

- **LA County Short-Term Rentals Registration Ordinance** (unincorporated County only, not City of LA). County Code Title 7, Division 3, Chapter 7.96. Annual host registration, fee $914, primary residence only, ADUs and rent-restricted units and vacation rentals ineligible, platform obligations, enforcement and appeals. County Counsel analysis revised 2024-03-11. Source: https://ttc.lacounty.gov/wp-content/uploads/2024/05/Short-Term-Rental-Ordinance.pdf. Local copy: `2024-03-11_la-county-str-registration-ordinance.pdf`. One of the roughly seven real permit paths in LA County; out of MVP scope (City of LA only) but a second jurisdiction row for the rules table. Effective date and current fee `[UNVERIFIED]` against the live County Code.
