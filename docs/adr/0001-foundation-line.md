# 0001. Foundation line: tenants, hosts, cases, and what is configuration

Status: accepted

## Context

The operator's direction is that the pilot scope is what the UI shows, while the platform underneath is built for the full concept: several customer organizations on one platform, with a second customer provisioned without a rebuild. The same direction says the foundation must not grow the MVP build. Airbnb is the first customer. The named next customers are another booking platform and a city-funded permitting program.

The two shapes differ. A booking platform sends hosts in and sees aggregates. A city sponsor does the same, but its hosts live in its own jurisdiction. Raken is the data controller, at arm's length from every customer. Customers see suppressed aggregates only. Anonymous use gives the full verdict, and registration only saves progress.

This ADR fixes the domain line: what a tenant is, who a host belongs to, how a request learns its tenant, and what varies per tenant. How tenants are isolated is [ADR 0002](0002-tenant-isolation.md). How rules reach every verdict is [ADR 0003](0003-rules-as-versioned-artifact.md).

## Decision

### Tenant

- **What a tenant is:** a customer organization that sends hosts to PermitPath and sees their aggregates.
- **Jurisdiction is never a tenant.** A city sponsor is a tenant whose hosts sit in its own jurisdiction. That jurisdiction's rules stay in the shared rules artifact: a tenant selects jurisdictions, it never owns a copy of their rules.
- **The term means the domain concept,** not Identity Platform's "tenant" feature. ADR 0002 uses that feature to implement tenants. The feature does not define the term.

### Host and case

- A host belongs to exactly one tenant. This holds in every isolation model.
- A case belongs to exactly one host, and so to exactly one tenant, fixed when the case is created.
- **The same person through a second tenant** is a second host with a second case, and nothing links them. No tenant learns that the person was seen through another tenant. No aggregate counts one person's case in two tenants.
- **CCPA access and deletion** are answered by Raken, as controller, across all tenants in one response. Only the cross-tenant compliance role described in ADR 0002 may search across tenants.

### Entry and request scope

- **One hostname per tenant,** mapped to the tenant on the server at the entry point.
- **The hostname selects the tenant when a case is created, and never authorizes.** After creation:
  - the case's stored tenant is authoritative;
  - nothing the client sends later changes it;
  - authorization comes from the credential bound to the case (ADR 0002).
- **No untenanted front door.** Every case has a tenant. If PermitPath opens a direct channel, Raken is itself a tenant, so the rule has no exception.
- **Tenant staff** (for example, the customer's program team on its dashboard) get their tenant from their sign-in only. A staff account belongs to exactly one tenant. Whether staff use the customer's SSO or local accounts is a separate decision.

### What is per-tenant configuration

The rule: anything that names the tenant is configuration from the first release. Anything structural may be hard-coded once, kept in one place, and becomes configuration by the fast-follow.

| Item | First release | By the fast-follow |
|---|---|---|
| Display name, logo, colors | config | |
| Entry hostname | config | |
| Recipient named in the aggregate-sharing consent text | config | |
| Expert-request destination | config | |
| Jurisdictions offered (a selection from the shared rules) | config | |
| Languages offered | config | |
| Feature flags: assistant, document checks, nights log, reminders | config, per tenant | |
| Whether the measurement holdout is exposed to the tenant | config, per tenant | |
| Any host-facing string that names the tenant | config | |
| Tenant dashboard metric set and layout | hard-coded, one design | config: metric list |
| Staff sign-in method | hard-coded, one provider | config |

Global, never per-tenant:
- the rules artifact
- jurisdictions
- the verdict engine
- support contact and schedule

Raken runs support for every tenant permanently.

Measurement is built in every case. Whether a tenant sees the holdout is a contract term, which is why it is a flag.

Consent works in two layers. The tenant consent covers sharing aggregates with the tenant. Raken's own use as controller is covered by the privacy notice.

### Provisioning bar

A new tenant needs no application code change. An infrastructure run is allowed. Onboarding is a written runbook executed by a Raken engineer, not self-serve. In order:

1. Contract and data processing agreement, with the sub-processor list.
2. Tenant configuration record (the table above).
3. Brand assets.
4. Consent copy in each offered language.
5. Hostname host rule and certificate.
6. Identity Platform tenant, its providers, and anonymous sign-in. Anonymous sign-in can be enabled per tenant in the Console, not through the Admin SDK, so this is a manual step ([source](https://docs.cloud.google.com/identity-platform/docs/multi-tenancy-managing-tenants)).
7. Staff accounts or SSO.
8. The tenant's dashboard access: a row policy or authorized view for its staff.
9. Cross-tenant tests run against the new tenant (ADR 0002).
10. Three-level QA pass: technical, business, real users.
11. A decision on whether pentest scope reopens.

Steps 5, 6, 8 and 9 are the technical part, about six runbook lines under the pool model.

## Options rejected

- **A tenant as "whoever pays."** It puts commercial terms into the domain model and into a public repository.
- **A separate entity type for city sponsors.** Two concepts would do one job. The only difference, that the hosts sit in the sponsor's jurisdiction, is already expressed by the jurisdictions the tenant offers.
- **A host belonging to PermitPath, shared across tenants.** It needs a cross-tenant identity layer inside the MVP build. Identity Platform keeps users inside a tenant, so that layer would be new work. It would also put one person in two competitors' aggregates, which the security review's multi-client risk (R12) asks to keep apart.
- **A path prefix per tenant.** The prefix leaks into every link and every asset.
- **A referral token in the link.** A token can be stripped or forwarded.
- **A configurable dashboard in the first release.** That is real build work for a customer who does not exist yet.
- **Small code changes allowed per new tenant.** That is the rebuild the operator direction rules out.

## Consequences

- The domain model is the same under pool, bridge and silo, so changing the isolation model later moves data rather than remodeling it.
- One person who uses two tenants counts twice: once in each tenant's aggregates and twice in Raken's totals.
- Every host-facing string that names the tenant goes through configuration from the first commit that renders it.
- A spoofed Host header at case creation can only file an empty case under another tenant. Dashboards therefore count cases that pass intake, not cases created.

## Open items

- Staff sign-in for the tenant dashboard: the customer's SSO or local accounts (security review A03).
- Whether the customer contract permits another customer on the same platform (the contract half of R12). This is a contract question, not a design one.

## If a customer asks

"Each customer organization is a separate tenant on PermitPath: your hosts, their cases and your dashboard belong to your tenant alone, and PermitPath is built so that no other customer sees them or learns that a host came through you."
