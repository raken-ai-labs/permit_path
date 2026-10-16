# Free public data sources: liveness check (2026-10-16)

Test address: 200 N Spring St, Los Angeles, CA 90012 (City Hall). All requests were unauthenticated `curl` calls from a developer laptop on 2026-10-16. Times are single-request wall clock, not benchmarks. Starting point: `ai_docs/refs/2026-09-26_public-data-sources.md`.

Bottom line: Census Geocoder, County parcel REST, City Planning zoning, and LADBS Socrata all respond today with no key. Two things in the kickoff prompt need correcting: (a) RSO has no per-address dataset, but there is a public ArcGIS layer of RSO service areas, which is not a status lookup; (b) no home-sharing registration dataset exists on data.lacity.org.

## 1. US Census Geocoder: LIVE, no key
- Endpoint: `https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress?address=200+N+Spring+St%2C+Los+Angeles%2C+CA+90012&benchmark=Public_AR_Current&vintage=Current_Current&format=json`
- HTTP 200, 0.78 s.
- Result: matched `200 S SPRING ST, LOS ANGELES, CA, 90012`, coordinates x=-118.2456, y=34.0516. **The matcher returned "S Spring", not "N Spring": it normalized the street to the wrong direction.** Geographies returned: Incorporated Places = "Los Angeles city", Counties = "Los Angeles County", Census Tract 2073.06.
- Implication: the Census geocoder is address-range interpolation, not rooftop. Do not treat its match as proof of the address. It does answer "is this in the City of Los Angeles incorporated place" (the city-limit gate), but verify directional mismatches against the County parcel situs.
- Auth: none. Rate limits: not stated in the docs I fetched `[UNVERIFIED]` (no rate-limit headers seen; the terms reserve the right to block excessive use).
- Terms: https://www.census.gov/data/developers/about/terms-of-service.html (the Census Bureau may limit or block use that exceeds its limits). API docs: https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.pdf (HTTP 200).
- Currency: benchmark/vintage "Current" (Public_AR_Current); the response did not state a release date `[UNVERIFIED]`.

## 2. LA County parcels (Assessor): LIVE, no key
- Endpoint: `https://public.gis.lacounty.gov/public/rest/services/LACounty_Cache/LACounty_Parcel/MapServer/0/query?where=SitusAddress LIKE '200 N SPRING ST%'&outFields=AIN,APN,SitusAddress,SitusCity,UseType&returnGeometry=false&f=json`
- HTTP 200, 0.46 s (layer metadata 0.23 s). Server: ArcGIS 10.91 behind Imperva CDN.
- Sample (trimmed): `{"AIN":"5161005906","APN":"5161-005-906","SitusAddress":"200 N SPRING ST","SitusCity":"LOS ANGELES CA","UseType":"Government"}`
- Layer capabilities: Map, Query, Data; maxRecordCount 1000. Layer metadata names the service "Los Angeles County Assessor Parcel Data", copyright "Los Angeles County Office of the Assessor". Source: https://public.gis.lacounty.gov/public/rest/services/LACounty_Cache/LACounty_Parcel/MapServer/0?f=json
- Auth: none. Rate limits: none published `[UNVERIFIED]`; it sits behind a CDN that can block bursts.
- Terms of use: no terms URL on the service itself. County hub: https://egis-lacounty.hub.arcgis.com/ (HTTP 200). The hub's dataset license text was not read `[UNVERIFIED]`.
- Currency: the service metadata has no last-updated field. The earlier ref says weekly cache refresh; I could not confirm it `[UNVERIFIED]`. The layer is a *cache*; the search also surfaced Assessor roll tables at https://services.arcgis.com/RmCCgQtiZLDCtblq/arcgis/rest/services/Parcel_Data_2021_Table/FeatureServer (rolls 2021 to 2025).
- The `SitusCity` value carries a trailing state ("LOS ANGELES CA") and non-city addresses are common in situs strings; normalize before comparing.

## 3. City of LA zoning, ZIMAS, GeoHub
### ZIMAS front end
- `https://zimas.lacity.org/` HTTP 200, **8.4 s** (slow, Angular single-page app; robots.txt took 10.1 s). It is a browser app. I found no documented public API for ZIMAS. Its JS bundle references an obfuscated host (`https://68wzimas4...`) that I did not resolve `[UNVERIFIED]`. Scraping ZIMAS is not a supported path. Do not depend on it.

### Zoning layer (supported path): LIVE
- Item: https://geohub.lacity.org search item `f2b84d74972a4084aac79fbe504d9b11` "Zoning", owner GIS@LADCP (City Planning). Service: `https://services5.arcgis.com/7nsPwEMP38bSkCjy/arcgis/rest/services/Zoning/FeatureServer/15` (layer id is **15**, not 0).
- 58,859 polygons. Fields: `Zoning`, `CATEGORY`. maxRecordCount 2000.
- Point query with `distance=30&units=esriSRUnit_Meter` at the geocoded coordinates: HTTP 200, 0.2 s, returned e.g. `{"Zoning":"[HB4-SH1-5][CX3-FA][CPIO-SN]","CATEGORY":"Commercial-Mixed"}` (multiple adjacent polygons). A zero-distance point query at the Census coordinate returned no features (the interpolated point fell in a gap), so **query with the parcel centroid/polygon, not the geocoder point.**
- Auth: none (public hosted feature service). Rate limits: ArcGIS Online hosted-service throttling, no figure published for this item `[UNVERIFIED]`.
- Currency: data last edit 2026-10-10 (`dataLastEditDate` 1792055754263 ms epoch). Item created 2024-08-20.
- Terms: the item's license text (https://www.arcgis.com/sharing/rest/content/items/f2b84d74972a4084aac79fbe504d9b11?f=json) is a City Planning web-site agreement: public service, "as is", no accuracy guarantee. That matches our "readiness, never approval" rule.
- Also on the City's own server: Planning layers at https://maps.lacity.org/lahub/rest/services/City_Planning_Department/MapServer (HTTP 200, 0.3 s): Generalized Zoning (8), General Plan Land Use (7), Specific Plan Areas (19), Historic Preservation Overlay Zone (10), Interim Control Ordinances (11), Miscellaneous Districts (12). Landbase_Information/MapServer has City parcels (layers 5 and 7, LA County APN): https://maps.lacity.org/lahub/rest/services/Landbase_Information/MapServer. The ArcGIS root listing is https://maps.lacity.org/arcgis/rest/services (HTTP 200, 0.30 s).
- Socrata also lists "Zoning" datasets (e.g. `rryw-49uv`, `fu5x-kbuu`, `8625-f7mv`), last updated 2024; the ArcGIS layer is fresher.

### Home-Sharing layers: NONE FOUND
- No GeoHub or maps.lacity.org layer named for home-sharing or short-term rental turned up in searches of https://geohub.lacity.org/api/search/v1/collections/all/items?q=home%20sharing and `q=short-term`. Home-Sharing Ordinance is not in the City Planning layer list above. The registry is held by City Planning's Home-Sharing portal, not published as open data `[UNVERIFIED]` (I did not fetch the portal; planning.lacity.gov pages returned 403 to bots per the earlier ref).

## 4. LADBS Socrata (data.lacity.org): LIVE
- Metadata: `https://data.lacity.org/api/views/metadata/v1/pi9x-tg5x.json` HTTP 200, 0.37 s. Dataset "Building and Safety - Building Permits Issued from 2020 to Present (N)", `dataUpdatedAt` 2026-10-12, row refresh_time 2026-10-11, provenance OFFICIAL, license field null.
- Query: `https://data.lacity.org/resource/pi9x-tg5x.json?$limit=1&$where=primary_address like '%SPRING ST%'` HTTP 200, **6.0 s** (unindexed LIKE; the 0.25 to 0.4 s metadata calls are fast). Sample columns: `permit_nbr, primary_address, zip_code, apn, zone, permit_type, use_desc, issue_date, status_desc, lat, lon, work_desc`. The `apn` column makes a join to County parcels possible.
- Auth: none required. Rate limits: Socrata throttles by source IP without an app token; a free app token gives a higher limit (https://dev.socrata.com/docs/app-tokens.html). Exact numbers not published there `[UNVERIFIED]`.
- Terms: the dataset has no license value; the data.lacity.org terms page I tried (`/stories/s/Terms-of-Use/`) returned 404. `[UNVERIFIED]`: find the current City open-data terms.
- **Home-sharing registrations dataset: does not exist on data.lacity.org.** Catalog searches (https://api.us.socrata.com/api/catalog/v1?domains=data.lacity.org&q=...) for "home-sharing", "short term rental" and "hso" returned 0 results. (This confirms the earlier ref's "Not found".)

## 5. RSO status by address: confirmed, with one nuance
- Socrata catalog `q=rent stabilization` returns only "Housing & Community Investment Service Locations" (`29cn-rph9`, office locations). No per-address or per-parcel RSO dataset.
- There is a City ArcGIS layer "Rent Stabilization Ordinance Service Areas": `https://maps.lacity.org/lahub/rest/services/Housing_and_Community_Investment_Department/MapServer/5`. HTTP 200, 0.3 s. A point query at City Hall returned `{"RSO_SERVIC":"DOWNTOWN","TOOLTIP":"DOWNTOWN RSO Area"}`. Fields are only `RSO_SERVIC` and `TOOLTIP`. This layer is **HCIDLA service/office areas (e.g. "Downtown Rent Investigation Area"), not whether a parcel is rent-stabilized.** GeoHub shows it last modified 2018-04-09 (item `cf8a7be2eabf4110bf020757392e961f`). Do not use it as an RSO verdict.
- Verdict: the kickoff prompt is right that there is no API for RSO status. Keep "ask the host" for this item. ZIMAS shows RSO per parcel in its UI only `[UNVERIFIED]` (not verified through ZIMAS today).

## Summary table
| Source | Status | Time | Key | Current |
|---|---|---|---|---|
| Census Geocoder | 200 | 0.78 s | none | current benchmark; directional error seen |
| LA County parcel REST | 200 | 0.46 s | none | no date field |
| City Zoning FeatureServer/15 | 200 | 0.2 s | none | edited 2026-10-10 |
| ZIMAS UI | 200 | 8.4 s | none | no API |
| LADBS Socrata permits | 200 | 0.4 s meta, 6.0 s LIKE query | none (token optional) | 2026-10-12 |
| Home-sharing dataset | not found | | | |
| RSO per address | not found (service-area layer only) | | | |
