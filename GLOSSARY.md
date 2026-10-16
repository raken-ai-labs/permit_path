# PermitPath

PermitPath gets short-term rental hosts ready to apply for a permit. It serves several customer organizations on one platform. This glossary is the domain vocabulary. Decisions live in `docs/adr/`.

Later grills add terms. This first set comes from the foundation-line grill ([ADR 0001](docs/adr/0001-foundation-line.md) to [0003](docs/adr/0003-rules-as-versioned-artifact.md)).

## Language

### Who

**Tenant**:
A customer organization that sends hosts to PermitPath and sees their aggregates. A booking platform and a city sponsor are both tenants. The term means this domain concept, not the identity provider's feature of the same name.
_Avoid_: Client, partner, account, customer (in code and specs)

**Raken**:
The company that runs PermitPath and is the data controller for every host, at arm's length from every tenant. When PermitPath serves hosts directly, Raken is itself a tenant.
_Avoid_: Platform owner, vendor

**Host**:
A person preparing a short-term rental permit application through exactly one tenant. The same person arriving through a second tenant is a second host.
_Avoid_: User, applicant, customer

**Tenant staff**:
A person who signs in on behalf of one tenant to see that tenant's aggregates. A tenant staff member belongs to exactly one tenant.
_Avoid_: Admin, partner user

### What

**Case**:
One host's permit-readiness work for one property. A case belongs to one host and so to one tenant, fixed when the case is created.
_Avoid_: Application (the host files that with the permitting authority), session, file

**Verdict**:
The readiness result for a case, computed by deterministic code from the rules and citing each rule, its source and the rule version. A verdict is readiness, never approval.
_Avoid_: Decision, approval, eligibility ruling

**Aggregate**:
A suppressed, count-level summary of many cases that a tenant or Raken may see. A single host's case is never an aggregate.
_Avoid_: Report row, metrics (for host-level data)

### Where

**Jurisdiction**:
A government whose permit rules apply to a property, such as the City of Los Angeles. A jurisdiction is never a tenant. A tenant offers a selection of jurisdictions.
_Avoid_: City (when the government entity is meant), region, market

**Instance**:
One running deployment of PermitPath serving one or more tenants. Staging and production are separate instances. A tenant with a dedicated environment would have its own instance.
_Avoid_: Environment (when a deployment is meant), stack, silo

### Rules

**Rules artifact**:
The single published copy of the rules for every jurisdiction, shared by every tenant and every instance. No tenant owns or edits its own copy.
_Avoid_: Rules database, rule set (per tenant)

**Rule version**:
The identifier of one published rules artifact. Every verdict names the rule version it was computed under.
_Avoid_: Rules date, revision

### Configuration

**Tenant configuration**:
The values that vary between tenants without code: name and branding, entry hostname, consent recipient, expert-request destination, jurisdictions and languages offered, and feature flags. Anything that names the tenant is tenant configuration.
_Avoid_: Settings, customization, theme

**Entry hostname**:
The web address through which a tenant's hosts arrive. It selects the tenant when a case is created and never grants access.
_Avoid_: Domain, subdomain, white label
