# 0002. Tenant isolation: pool, with the seams to silo one customer later

Status: accepted

## Context

[ADR 0001](0001-foundation-line.md) makes every host, case and aggregate belong to exactly one tenant. This ADR decides how that is enforced. The infrastructure is already settled: Raken's Google Cloud, Cloud Run, Cloud SQL, BigQuery with small-cell suppression, Identity Platform, and separate staging. The foundation must not grow the MVP build.

The security review sets two requirements. Its multi-client risk (R12) asks that two competing customers on the same platform have separate data and metrics. Its authorization rule (S03) asks for automated tests proving that nobody reads cases that are not theirs.

The evidence is [`ai_docs/research/2026-10-16_saas-tenant-isolation-models.md`](../../ai_docs/research/2026-10-16_saas-tenant-isolation-models.md). Section numbers below refer to that note. Its step counts are synthesis, not vendor figures.

## Decision

**Pool.** One project, one Cloud SQL instance with row-level security, one Identity Platform project with one Identity Platform tenant per tenant, and one BigQuery dataset with row policies.

### Seams to silo, as acceptance criteria from the first release

Each seam becomes a ticket:

1. **Tenant ID on every tenant-owned row,** so that one tenant can be lifted into its own project with a filtered export.
2. **The rules table published as a versioned artifact** that every verdict cites ([ADR 0003](0003-rules-as-versioned-artifact.md)). This is what a silo would pull.
3. **Terraform written as a module from the first apply,** so that a second instance is one more invocation of the same module.

### Controls

These ship with pool. The spec lists them as tests that run on every pull request touching data access.

- **Roles.** The application's database role is NOBYPASSRLS and owns no tenant table. Migrations run under a separate owner role.
- **Forced RLS.** FORCE ROW LEVEL SECURITY is on every tenant table, so the owner exemption does not apply (3.1).
- **Tenant context.** The tenant is set only with transaction-local `set_config`, and policies read it with `missing_ok`. An unset context matches no rows, so it fails closed (3.5). This also stops tenant context from carrying over to the next request on a pooled connection.
- **One data access layer** runs every query. It takes the tenant from the verified token, never from the hostname (3.6). Row-level security is the backstop if the layer is bypassed.
- **CI assertion from `pg_roles` and the catalog.** No runtime role has BYPASSRLS or superuser, or owns a tenant table. Every table with a tenant column has RLS enabled and forced, and has at least one policy. The one allowed exception is the cross-tenant compliance role.
- **Cross-tenant data tests (3.11):**
  - read tenant B's row as tenant A, expecting zero rows;
  - write a row carrying B's ID as A, expecting a check error;
  - query with no tenant context, expecting zero rows;
  - run request A then request B on the same connection; B must not see A's context;
  - for BigQuery, query as A's principal for B's rows, expecting zero rows, and confirm the aggregation threshold suppresses a known small group.
- **pgaudit** records every CREATE ROLE and ALTER ROLE.
- **Cross-tenant compliance role.** It exists only to answer CCPA access and deletion requests across tenants (ADR 0001). It is never used at runtime, and every use is audited.
- **Request authorization.** The hostname never authorizes (2.10, 6.4).
  - An anonymous host is authorized by the Identity Platform anonymous credential bound to its case, together with the case's stored tenant.
  - A request is accepted only when the verified token's tenant claim (`firebase.tenant`), the tenant the hostname maps to, and the case's stored tenant all match.
  - Tenant-scoped token verification rejects a token from another tenant ([source](https://docs.cloud.google.com/identity-platform/docs/multi-tenancy-managing-tenants)).
- **Tenant dashboards** read only a per-tenant BigQuery view. Small-cell suppression is applied inside the view by an aggregation-threshold analysis rule (3.10, 5.2). Raken's cross-tenant reporting is a query over the same suppressed data (5.5).

### Silo trigger

A specific customer moves to its own project when a contract requires a dedicated project or a key the customer holds. Cloud SQL encryption keys are per instance, so a pooled database cannot give one tenant its own key (2.9, 6.2). That silo is built when that contract pays for it. It is a new instance of the same Terraform module, pulling the same rules artifact, with the tenant's rows moved into it.

## Options rejected

Step counts are from the note's scorecard (7.2 to 7.5), with one customer for the build.

| | Pool | Bridge | Silo |
|---|---|---|---|
| MVP build steps beyond the common set | 5 | 12 to 13 | 11 |
| Steps to provision each new customer | 4 | 9 | 9 |
| Steps per rules release | 3 to 4, whatever N is | 3 + N, or 4 with an automated fan-out | 3 + N, or 4 with an automated fan-out |
| Steps per pentest or security review | 5 | 5 to 6 | 4 |

- **Silo: a project per customer, built from one Terraform module, for the MVP.** This was the operator's working position, tested and rejected:
  - It adds about six build steps for a second customer who does not exist yet.
  - Every rules release fans out N times, so instances can drift onto different rule versions. Two hosts at the same address could then get different verdicts on the same day (ADR 0003).
  - It does not remove the per-case access layer and tests that S03 requires. It removes only the tenant predicate from them.
  - Its real advantage, the shortest security review, stays available through the silo trigger.
- **Bridge.** It is worst or tied-worst on every table, because it carries both a shared tier and per-customer templates and has to evidence both.
- **Schema per tenant.** Migrations multiply per tenant, and it isolates little more than forced row-level security does.

## Consequences

- Isolation is enforced in the data access layer and in the database, not by IAM boundaries. A missing tenant predicate is the main failure mode (1.8). The controls above exist to catch it.
- Audit logs, Access Transparency and encryption keys describe Raken's environment, not a per-customer environment (6.2). A customer that needs "your own environment" is the silo trigger.
- Pentest scope is the shared stack with every tenant in scope. Cross-tenant data tests are central to every pentest.
- An outage or a noisy tenant affects every tenant.
- Moving one tenant to a silo later is a data move into a new module instance, not a remodel, because the seams are in place from the first release.

## Open items

- Whether a member of Cloud SQL's `cloudsqlsuperuser` holds or can grant BYPASSRLS (3.4, open item 1). To settle it, run a staging test: as that role, attempt `CREATE ROLE ... BYPASSRLS`. If it succeeds, the CI role assertion is the control that catches any such role.
- Whether session cookies are supported for Identity Platform tenant users. The Admin SDK feature table shows no support in a tenant context. Until confirmed, authorization relies on the ID token or a server-issued case-bound credential, not on session cookies.
- Whether a Cloud Run backend can be referenced cross-project from one load balancer without a Shared VPC (2.10, open item 3). This does not matter under pool. It matters for the first silo.

## If a customer asks

"PermitPath separates customers by tenant at the database level as well as in the application, and every change that touches data access is tested to show one tenant cannot read another's data; a customer whose contract requires a dedicated environment can be given one from the same build."
