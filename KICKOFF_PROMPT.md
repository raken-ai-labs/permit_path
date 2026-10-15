
You are the orchestrator for PermitPath. Rod Morrison is product lead and player-coach: he builds as well as leads, and is your primary operator. PermitPath is a tool that helps Los Angeles Airbnb hosts get and keep short-term-rental permits. Raken AI Labs is building it for Airbnb. This repo is where the architecture, spec and code live. Read `ai_docs/brief.md` first, then the rest of `ai_docs/`; it holds every decision and fact so far. `docs/` is product documentation and is empty until the spec exists.

**Dates, committed to Airbnb (deck v5, `ai_docs/research/2026-10-14_deck-v5-build-commitments.md`):**

| Date | Commitment |
|---|---|
| Oct 19 | Kickoff. A signed spec comes before the build. |
| Nov 6 | Prototype |
| Nov 20 | MVP live. Nov 24 is the hard stop. |
| Dec 11 | Fast-follow |
| Dec 18 | Acceptance |
| Through May 20 | Run. Next-wave decision in April. |

The signed spec is the first deliverable, and it is due at kickoff. That makes the next four days about decisions, not code.

**The architecture principle, already decided (build-spec draft):** rules are versioned data. Eligibility verdicts come from deterministic code over the rules table, never from a model. Models handle intake, document reading, explanations and keeping rules current. Every verdict cites the rule and its source URL. Verdicts are "readiness," never "you will be approved."

**Infrastructure, already committed (deck v5 p6):** GCP. Cloud SQL, BigQuery with small-cell suppression, Cloud Armor, Cloud KMS, Secret Manager, Identity Platform for host sign-in, a separate staging environment. These are constraints. The compute layer, region and data model are open.

**Privacy, already committed (deck v5 p7):** explicit host consent before any aggregate data is shared, a working CCPA access and deletion process, a privacy review before go-live, automated security scanning before go-live and monthly. Document checks store nothing.

**What to do, in order, in one unbroken context:**

1. `/setup-matt-pocock-skills`. GitHub issue tracker, this repo. Default labels. Single-context docs.
2. `/grill-with-docs` on the open decisions below. Write `CONTEXT.md` as the glossary (PermitTier, verdict, readiness, rules table, jurisdiction, holdout) and one ADR per hard-to-reverse choice.
3. `/to-spec`. The output is the spec Airbnb signs. Internal and external sections: the external part is what they sign, the internal part is how we build it.
4. `/to-tickets`, blockers first, sized for a two-builder team working with Claude Code.
5. Stop. Rod reviews the spec and tickets before any `/implement`.

**Open decisions for the grilling:**

- Address verdict data path: Census Geocoder, LA County parcel REST, ZIMAS zoning. RSO status has no API. Confirm "ask the host when the lookup fails" is the MVP answer.
- Document checks: which vision model reads uploads, what is extracted, how mismatches are flagged, and how "nothing stored" is enforced and proven.
- Model choice: Gemini (GCP-native, cheap) or Claude (stronger on reasoning), behind one interface. Can be both.
- Assistant: grounded only in the rules table and ordinance text, cited, hands off when it does not know. What is the test set.
- Bilingual: machine translation plus one native review pass, or authored twice. David Mizrahi (native speaker) is the reviewer.
- Compute: Cloud Run or alternative, region, how staging and production are separated, how releases go out.
- Data model: what a host session stores, what the holdout measurement needs, how BigQuery suppression works.
- Rules upkeep: who approves a rule change, how the five-business-day commitment is met, whether the rules-watch agent is MVP or later.
- "Connect to an expert on request" (deck v5 p4): a request form only, not routing. Confirm.
- Readiness score: what it is computed from, and how it avoids reading as a promise.

**From the 10/15 internal kickoff (`ai_docs/intake/2026-10-15_meeting_internal-kickoff.md`, by speaker and timestamp):**

Decided, treat as settled:
- Raken does not file the application for the host. The tool prepares them; the host files with the City.
- No multi-property in v1. Scope is deck v5 plus the MVP demo, nothing else before Dec 11.
- Free to hosts. Registration is optional and only saves progress. Premium features are a later conversation, not a spec item.
- Hosted on Raken's GCP, multi-tenant, holding PII. Raken keeps the IP; no source code goes to Airbnb.

Open, resolve in the grilling and record as ADRs:
- CCPA design: what identifier a host gets, what is retained and for how long, how access and deletion requests are served. Antonio is getting two law firms quoted for terms and disclaimers; their output is input to this, not a replacement for the decision.
- Existing-host features (nights tracking, permit-expiry alerts): in the pilot or not. Multi-property is out; single-property tracking was not answered.
- Expert-host knowledge capture and workshops: Stefan raised it, nobody answered. The 10/8 MVP cut deferred it. Default is out of MVP unless the spec says otherwise.
- Data Raken cannot access (RSO status, permit registries): the fallback is "ask the host." Confirm per data item.
- Multi-tenant and white-label foundation: Rod wants a base that can be provisioned for a second customer later. Decide what "foundation" means for the MVP in concrete terms (tenant ID in the data model, config per tenant, nothing more) so it does not grow the five-week build.
- Product name. "PermitPath" is the working name; open to alternatives.

Correct before anything client-facing repeats them:
- The City of LA denies about 44% of first-time applications, so first-time success is about 56%. In the meeting it was stated as "40 something percent success." Use the sourced figure in `ai_docs/research/2026-10-08_sourced-facts-super-bowl-mvp.md`.
- "97 jurisdictions" is not a real figure. The public-data scan found about seven real permit paths in LA County. The MVP is City of LA only.

Not mentioned in the meeting and still committed: Spanish for Nov 20, the Nov 6 prototype, Nov 20 MVP, Nov 24 hard stop, Dec 11 fast-follow, Dec 18 acceptance. Treat the deck dates as binding.

**Research to dispatch to Sonnet agents while grilling runs, output to `ai_docs/research/`:**

- Verify the free APIs respond today: County parcel REST, ZIMAS, LADBS Socrata, Census Geocoder. Log status codes and sample responses.
- CCPA obligations for a host-facing web app operated by a vendor: access, deletion, notice, consent. Primary sources only.
- Cloud Run versus GKE versus App Engine for this shape and traffic (18,000 address checks, 7,200 document checks over six months). Cost and cold-start trade-offs.
- Gemini and Claude vision on document extraction: pricing per page today, from the provider pages.

**Rules for this repo:**

- Every factual claim about the City of LA cites a URL. Mark anything unverified `[UNVERIFIED]`.
- Branch protection on `main` from the first push: no direct commits, one approving review to merge. Set it up in step 1 with `gh`; Angel is an org Owner if the token lacks scope.
- QA is a required review or a PR label, never a note in prose. A PR that writes to production data needs a QA approval before merge. Put this in `CLAUDE.md` and in the PR template.
- A plain-language change log for Airbnb, `CHANGELOG.md` at the root, one line per user-visible change, written when the PR merges. Deck v5 p8 promised it.
- `ai_docs/intake/` holds the full commercial trail (quotes, emails) as context. Pricing, hours-to-dollars, insurance, IP and payment terms stay there: they do not appear in the spec, the tickets, `CONTEXT.md`, ADRs or `docs/`.
- US English throughout.
- Read `CLAUDE.md` at the start of every session and after any compaction.

