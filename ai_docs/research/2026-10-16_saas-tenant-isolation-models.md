# SaaS tenant isolation models on Google Cloud (silo, pool, bridge)

Fetched 2026-10-16 (all URLs below). Primary sources only: Google Cloud documentation, AWS SaaS Lens and AWS SaaS whitepapers (for vocabulary only), Terraform provider and module source on GitHub, PostgreSQL documentation. Google docs redirect from cloud.google.com to docs.cloud.google.com; the URL actually fetched is cited. Terraform facts were retrieved through context7 from the provider's GitHub docs sources, and those GitHub paths are cited. The AWS SaaS whitepapers (SaaS Tenant Isolation Strategies, SaaS Architecture Fundamentals) now carry an AWS banner saying they are for historical reference only; one page of the latter is cited (1.5), and the SaaS Lens pages (no banner) are used otherwise. `[PARTIAL]` = the fetch was truncated. `[UNVERIFIED]` = not confirmed from a primary source. `[INFERRED]` = synthesis by the author of this note, not a statement from a source. This note states facts and trade-offs; it makes no recommendation and records no decision.

## Bottom line (facts, not a recommendation)

1. A hostname is not an access control. Google's URL map documentation says the load balancer does not validate the Host header, since clients can set arbitrary values, and it should not be used for access control (2.10, 6.4). The settled per-tenant hostname can select tenant context (which Identity Platform tenant, which backend); authorization has to bind to the authenticated identity in every model. `[INFERRED]` for the second sentence.
2. In PostgreSQL, row-level security does not apply to superusers, to roles with BYPASSRLS, or (by default) to the table owner (3.1 to 3.3). Cloud SQL does not let customers create superusers, but its documentation is silent on BYPASSRLS; whether `cloudsqlsuperuser` members can create a BYPASSRLS role on Cloud SQL is `[UNVERIFIED]` (3.4).
3. A rules release is one action in pool and N actions in silo. AWS's full-stack silo guidance says every silo runs the same configuration and software version, and a release is deployed to the pool and to each silo (1.5). How the rules table reaches N silos is the main operational difference for the five-business-day rule commitment (section 4).
4. Google's own Cloud Run guidance for multi-tenant platforms running tenant-supplied code (a stricter case than PermitPath's) recommends one project per tenant as a strict resource boundary, with folder-level organization policies and project deletion as the offboarding path (2.1).
5. Central operations across N projects are supported natively: aggregated log sinks at folder level (up to 200 sinks per folder or organization) and a monitoring metrics scope of up to 3,500 projects, with performant queries guaranteed for 375 (2.5, 2.6).
6. Identity Platform multi-tenancy gives each tenant its own users, providers, and configuration inside one project; tenants are unlimited on a billed project. Tenant-specific blocking functions are not supported (2.8).
7. Cross-customer reporting with small-cell suppression has a native mechanism: BigQuery analysis rules (aggregation threshold) on views, used directly or inside data clean rooms on BigQuery sharing (formerly Analytics Hub). Google's own page warns analysis rules may not stop every sophisticated extraction query (5.3 to 5.5).

## 1. Silo, pool and bridge: definitions and trade-offs

1.1 Silo. Tenants get dedicated resources, from a separate database up to a "fully independent infrastructure stack." A silo is still SaaS only if it shares identity, onboarding, and operations across tenants; otherwise it is a managed-service model. https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/silo-pool-and-bridge-models.html

1.2 Pool. Tenants share resources (compute, storage, messaging) for economies of scale, manageability, and agility. Same page.

1.3 Bridge. A mixed mode: some parts of the system are siloed and others pooled, for example per microservice, driven by the data's regulatory profile and noisy-neighbor behavior. Same page.

1.4 Silo isolation guarantees and costs. AWS calls silo isolation "much simpler to enforce" because well-defined constructs wrap the stack. Listed pros: compliance fit, no noisy neighbor, simple per-tenant cost tracking, reduced scope of impact. Listed cons: account (here, project) scaling limits, cost (idle resources per tenant), agility, heavier onboarding automation, and decentralized management and monitoring that must be aggregated. https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/silo-isolation.html

1.5 Silo version discipline. AWS says siloed stacks must not allow one-off variation; each runs the same configuration and software version, and each release is deployed to the pool and to every silo. https://docs.aws.amazon.com/whitepapers/latest/saas-architecture-fundamentals/full-stack-silo-and-pool.html (historical-reference banner)

1.6 Pool isolation guarantees and costs. In a pool, "typical networking and IAM constructs cannot be relied upon" to separate tenants; isolation becomes an application and data-layer responsibility, and the shared model "increases the chance for cross-tenant access." Pros: agility, cost efficiency, one management view, faster innovation. Cons: noisy neighbor, harder cost attribution, increased scope of impact (one outage hits all tenants), and compliance pushback. https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/pool-isolation.html

1.7 Isolation is required regardless of model; a cross-tenant breach is described as "potentially unrecoverable" for a SaaS business. https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/tenant-isolation.html

1.8 Failure modes by model `[INFERRED]` from 1.4 to 1.6:
   - Silo: drift between customer stacks (a migration applied to some projects and not others); a release that succeeds in one project and fails in another; per-tenant misconfiguration of IAM or org policy.
   - Pool: a missing tenant predicate in one query path; a role that bypasses the policy (3.1 to 3.4); tenant context leaking across pooled connections (3.6); one tenant's load degrading all.
   - Bridge: both sets, plus the boundary itself (which data crosses from the pooled tier to the siloed tier, and under whose identity).

1.9 Operational cost shape `[INFERRED]`:
   - Per-tenant floor: silo carries a fixed set of resources per customer (project, Cloud SQL instance, KMS key ring, service accounts, Identity Platform configuration, monitoring and logging wiring); pool carries only rows and configuration.
   - Migrations: silo runs every schema migration N times, once per customer database; pool runs it once.
   - Pentest scope: silo can test one template instance and argue the others are identical (which holds only if drift is controlled, 1.5); pool must test cross-tenant paths in the shared stack on every release that touches data access.

## 2. GCP-native silo: project per customer

2.1 Google's Cloud Run page for multi-tenant platforms recommends "one Google Cloud project per tenant" as a strict resource boundary. Benefits it lists: tenant data deletion by deleting the project, project-level quotas to cap usage, folder-level organization policies (for example allowed regions), and pre-creating a pool of projects to avoid provisioning latency. Hosting multiple tenants per project is described as adding complexity and weakening the boundary. The page's scope is platforms running tenant-supplied code, which is stricter than PermitPath's case. https://docs.cloud.google.com/run/docs/securing/multi-tenant

2.2 Limits from the same page: a non-adjustable limit of 1,000 Cloud Run services per region per project; a soft limit of 100,000 projects per billing account. Same page.

2.3 Resource hierarchy. Folders group projects and can act as "sub organizations" with their own admins; IAM allow policies and organization policies set on a folder flow down to every project beneath it. https://docs.cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy Google's landing-zone guidance discusses folders by environment, region, or product and mentions client UAT projects, but does not discuss per-customer SaaS projects. https://docs.cloud.google.com/architecture/landing-zones/decide-resource-hierarchy

2.4 Organization policies. Constraints are set at organization, folder, or project and inherited by descendants unless overridden; managed constraints are not merged, the child either inherits or overrides. Policies are generally not retroactive (existing violations are flagged, not removed). Relevant constraints: resource locations, domain-restricted sharing, service-account creation restrictions; dry-run mode is available. https://docs.cloud.google.com/resource-manager/docs/organization-policy/overview

2.5 Central logging. Aggregated sinks are created on a folder or organization; with include-children set they route logs from all descendant projects to one destination (project, log bucket, BigQuery dataset, Cloud Storage, Pub/Sub). Intercepting sinks also stop matching logs from reaching child sinks (except `_Required`); in the console an intercepting sink offers only a project destination. Up to 200 sinks per folder or organization; the sink's writer identity needs a role on the destination. https://docs.cloud.google.com/logging/docs/export/aggregated_sinks The Terraform folder-sink resource exposes include_children, intercept_children, filters, and exclusions. https://github.com/hashicorp/terraform-provider-google/blob/main/website/docs/r/logging_folder_sink.html.markdown

2.6 Central monitoring. A scoping project's metrics scope can include other projects; Monitoring Viewer on the scoping project shows data for all monitored projects. Google recommends a resource-free project as the scoping project. https://docs.cloud.google.com/monitoring/settings Limit: 3,500 projects per metrics scope, performant for 375. https://docs.cloud.google.com/monitoring/quotas Terraform resource: a monitored-project resource linking a project to a metrics scope. https://github.com/hashicorp/terraform-provider-google/blob/main/website/docs/r/monitoring_monitored_project.html.markdown

2.7 Per-customer instantiation. The Google-maintained project-factory module creates a project, attaches billing, enables APIs, deletes the default network, replaces the default compute service account, optionally attaches to a Shared VPC, and grants a controlling group a role; budget inputs exist. https://github.com/terraform-google-modules/terraform-google-project-factory A per-customer module (project factory plus Cloud Run, Cloud SQL, KMS, Identity Platform, sink and monitoring wiring) instantiated once per customer is the pattern this implies; "no application code change, one infrastructure run" fits it. `[INFERRED]`

2.8 Identity Platform: per project versus multi-tenancy.
   - Multi-tenancy: a tenant is a silo of users and configuration inside one Identity Platform project, with its own ID, users, providers and sign-in methods, auditing and IAM configuration, quota allocation, and usage breakdown; Google calls it a data isolation boundary. Tenants cannot disable account linking and cannot have a tenant-specific blocking function. https://docs.cloud.google.com/identity-platform/docs/multi-tenancy
   - Limit: 2 tenants per project without billing, unlimited with billing. https://docs.cloud.google.com/identity-platform/quotas
   - Client side: the app sets the tenant ID on the auth instance before sign-in; it is not persisted across page reloads; the signed-in user carries the tenant ID. A top-level tenant claim is documented for Admin SDK custom tokens. Whether the standard ID token carries a tenant claim that a backend can verify is `[UNVERIFIED]` here. https://docs.cloud.google.com/identity-platform/docs/multi-tenancy-authentication
   - Terraform: the tenant resource requires multi-tenancy to be enabled in the Cloud Console first (a one-time manual step per Identity Platform project); the config resource has a multi-tenant block with allow-tenants and a default parent for tenant projects. https://github.com/hashicorp/terraform-provider-google/blob/main/website/docs/r/identity_platform_tenant.html.markdown and https://github.com/hashicorp/terraform-provider-google/blob/main/website/docs/r/identity_platform_config.html.markdown
   - Per-project Identity Platform (silo) puts users in the customer's project and IAM boundary; multi-tenancy (pool or bridge) keeps one project and one place for providers, with tenant-level separation. `[INFERRED]`

2.9 KMS key per project. CMEK gives customer-owned keys and a cryptographic boundary; default Google encryption may share key-encryption keys across customers. Key rings can sit in the resource project or a separate key project (separation of duties). Autokey can create keys at resource creation, with one key project per folder or same-project storage. Disabling or destroying a key makes protected data inaccessible; destroying enables crypto-shredding at offboarding. https://docs.cloud.google.com/kms/docs/cmek
   - Cloud SQL for PostgreSQL CMEK must be chosen at instance creation and cannot be changed later; the key must be in the same region (multi-region or global keys do not work); an inaccessible key suspends the instance; destroying the key version that created the instance destroys its backups. https://docs.cloud.google.com/sql/docs/postgres/cmek

2.10 One front door over N projects. The global external Application Load Balancer supports cross-project service referencing: frontend and URL map in one project, backend services in another, with the Compute Load Balancer Services User role granted by the backend project; the worked example uses instance groups and buckets and no Shared VPC. https://docs.cloud.google.com/load-balancing/docs/https/setup-cross-project-backend-service-backend-bucket For serverless NEGs (Cloud Run) the NEG, backend service, and Cloud Run service must be in the same project, and cross-project referencing is stated as supported "in a Shared VPC deployment"; Cloud Armor protection is available with serverless NEGs. https://docs.cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts Whether a serverless-NEG backend can be referenced cross-project without Shared VPC is `[UNVERIFIED]`. Host rules route by hostname (exact or wildcard), one host rule per hostname; the Host header is not validated and should not be used for access control. https://docs.cloud.google.com/load-balancing/docs/url-map-concepts

## 3. GCP-native pool: Cloud SQL row-level security and BigQuery policies

3.1 PostgreSQL row-level security. Once enabled on a table with no policy, a default-deny applies. Superusers and roles with BYPASSRLS always bypass. The table owner is normally exempt unless the table is set to FORCE ROW LEVEL SECURITY. Unique, primary-key, and foreign-key checks always bypass policies, which can create covert channels. Setting row_security off does not bypass policies; it raises an error if a policy would filter rows (intended for backups). Policy subqueries use the query snapshot, which can leak under READ COMMITTED during concurrent updates. https://www.postgresql.org/docs/current/ddl-rowsecurity.html

3.2 CREATE POLICY semantics. The USING expression filters existing rows silently (no error for invisible rows); the WITH CHECK expression validates new or updated rows and raises an error when false or null; for ALL and UPDATE policies, an omitted WITH CHECK reuses USING. Permissive policies combine with OR, restrictive with AND, and with only restrictive policies nothing is accessible. Policies run with the invoker's rights. Functions marked LEAKPROOF may run before policy expressions. Views use the view owner's policies unless created as security-invoker. Only the table owner can create policies. https://www.postgresql.org/docs/current/sql-createpolicy.html

3.3 BYPASSRLS. A role attribute (default NOBYPASSRLS) that skips every RLS policy; only superusers or roles that already have BYPASSRLS can grant it. The pg_dump note says superusers and the table owner always bypass RLS when dumping. https://www.postgresql.org/docs/current/sql-createrole.html

3.4 Cloud SQL specifics. Customers cannot create users with superuser privileges; `cloudsqlsuperuser` has "limited superuser privileges"; the default postgres user has CREATEROLE, CREATEDB, and LOGIN but not SUPERUSER or REPLICATION. The page does not mention BYPASSRLS. https://docs.cloud.google.com/sql/docs/postgres/users Whether a `cloudsqlsuperuser` member holds or can grant BYPASSRLS on Cloud SQL is `[UNVERIFIED]`; it is a direct question for a pool-model security review.

3.5 Session variables for tenant context. set_config with is_local true applies only for the current transaction; with false it lasts for the session. current_setting with missing_ok true returns NULL for an unknown setting instead of an error. https://www.postgresql.org/docs/current/functions-admin.html
   - `[INFERRED]` A policy comparing the tenant column to an unset variable read with missing_ok true matches no rows, so an unset context fails closed rather than open.
   - `[INFERRED]` With a connection pool (in the app or a pooler), session-scoped context can carry over to the next request on the same connection; transaction-scoped context does not.

3.6 Tenant-scoped data access layer `[INFERRED]`. The pattern is a single module through which every query runs: it takes the tenant from the verified identity (not the hostname, 2.10), opens a transaction, sets the tenant context transaction-locally, and executes. The application's database role is not the table owner and lacks BYPASSRLS; migrations run under a separate owner role. RLS is the backstop if the layer is bypassed; the layer is the primary control.

3.7 BigQuery row-level access policies. A policy has a grantee list and a filter expression; principals not granted see no rows; multiple policies can coexist with column-level security and IAM. A lookup-table subquery policy can replace many per-tenant policies. Policy filters do not participate in partition or cluster pruning. CREATE OR REPLACE TABLE, WRITE_TRUNCATE loads, and deletion remove policies; TRUNCATE does not. Side channels such as query duration can leak information. Policy creation and deletion are audit-logged, but the filter expression and grantee list are omitted from the logs. Google compares authorized views (most flexible), row-level policies (balance), and separate tables (strongest isolation). https://docs.cloud.google.com/bigquery/docs/row-level-security-intro

3.8 BigQuery policy administration. Creating a policy needs row-access-policy create and set-IAM permissions plus table data read; included in BigQuery Admin and Data Owner. Grantees can be users, groups, service accounts, domains, all authenticated users, or workforce identities. Google recommends a first full-access policy for administrators and service accounts, implying admins are not exempt by default. https://docs.cloud.google.com/bigquery/docs/managing-row-level-security

3.9 Authorized views and authorized datasets. A source dataset authorizes a view (or a whole dataset of views); users need access only to the view's dataset plus job-user on a project. Google recommends authorized datasets for multi-tenant designs because a dataset ACL is limited to 2,500 authorized resources. Source and view datasets must be in the same location. https://docs.cloud.google.com/bigquery/docs/authorized-views

3.10 Small-cell suppression. The aggregation threshold analysis rule on a view sets a minimum number of distinct privacy units per output row and omits rows below it; differential privacy is the alternative rule type. Rules cannot be added to materialized views, and time travel is disabled on views with an aggregation threshold. https://docs.cloud.google.com/bigquery/docs/analysis-rules

3.11 Tests that prove tenant A cannot read tenant B `[INFERRED]` (no primary source prescribes these):
   - As tenant A's context, select a known tenant B row by primary key: expect zero rows.
   - As tenant A, insert or update a row carrying tenant B's ID: expect a WITH CHECK error.
   - With no tenant context set: expect zero rows on every tenant-bearing table.
   - Catalog assertion in CI: every table with a tenant column has RLS enabled and forced, and has at least one policy.
   - Role assertion in CI: the application role owns no tenant tables and lacks BYPASSRLS and superuser.
   - Pooling test: run request A then request B on the same connection; B must not see A's context.
   - Uniqueness side channel: confirm keys with external meaning are not unique across tenants (3.1, 3.2).
   - BigQuery: query as tenant A's principal and compare to an admin full-access count filtered to A; query for B's rows as A and expect zero; confirm the aggregation threshold suppresses a known small group.
   - Silo equivalent: tenant A's service account is denied on tenant B's project, Cloud SQL instance, and KMS key (an IAM test, not a data test).

## 4. Shipping the centrally maintained rules table to N instances

4.1 Constraint from the brief: one rules table, maintained by Raken, consumed by every customer at the same version; City rule changes live within five business days. In pool there is one copy and one release; options below matter for silo and bridge. `[INFERRED]`

4.2 Versioned artifact in Artifact Registry. Generic repositories store any file type under a package name and version and are described as "versioned, immutable artifacts"; uploads and downloads use gcloud or the API; Reader, Writer, and Repository Administrator roles separate download, upload, and delete. How immutability is enforced is not explained on the page `[UNVERIFIED]`. https://docs.cloud.google.com/artifact-registry/docs/generic

4.3 Cloud Storage with a read-only Cloud Run volume mount. Cloud Run can mount a bucket read-only through Cloud Storage FUSE; metadata is cached (stat cache default TTL 60 seconds); the mount happens before the container starts, and if it does not succeed within 30 seconds the service fails to start. https://docs.cloud.google.com/run/docs/configuring/services/cloud-storage-volume-mounts `[INFERRED]` A change to an object may be seen up to the cache TTL later, and each silo's start depends on the central bucket being reachable.

4.4 Option trade-offs `[INFERRED]`:
   - Pull on deploy (rules version pinned in the deploy, artifact fetched at build or start). Every customer is at a known version and the deploy record is the evidence. A rules release is N deploys (or one pipeline fanning out to N projects); a failed deploy in one project leaves that customer behind. Fits a five-business-day window if the fan-out is automated; each project's service account needs read on the central artifact.
   - Pull on schedule (each instance polls for a newer version and loads it into its database). No deploy per release; convergence within one polling interval. Version skew between customers exists during the interval and on any poll failure, so the instance must report its loaded version to central monitoring for the "same version" claim to be provable.
   - Central read-only API (Raken-hosted rules service queried at evaluation time). One copy, so version skew is impossible by construction. Every customer instance depends on the central service at request time (shared failure mode across silos), and the customer's data flow now crosses a Raken-run boundary, which a silo-model security review will ask about. Responses could be cached per instance with a version check.
   - Push (central pipeline writes the rules version into each customer database). One action from Raken's side with N writes; needs central write access into every customer project, which narrows the silo boundary.

4.5 Version proof across customers `[INFERRED]`: whichever option, a "same version everywhere" claim needs each instance to emit its loaded rules version as a metric or log, which the folder-level sink or metrics scope (2.5, 2.6) can aggregate into one view.

## 5. Cross-customer vendor reporting without breaking isolation

5.1 Central aggregation from per-project datasets. Aggregated sinks can route logs from all customer projects to a central BigQuery dataset (2.5). For application metrics, authorized views or authorized datasets in each customer project can expose only aggregate columns to a central reporting identity; source and view must share a location (3.9). https://docs.cloud.google.com/bigquery/docs/authorized-views `[INFERRED]` for the per-customer authorized-view pattern.

5.2 Suppression at the view. An aggregation-threshold analysis rule on the shared view enforces a minimum count of distinct privacy units per row; queries must use the aggregation-threshold clause. https://docs.cloud.google.com/bigquery/docs/analysis-rules

5.3 BigQuery sharing (formerly Analytics Hub). Exchanges hold listings; subscribing creates a read-only linked dataset in the subscriber project with no data copy; publishers and subscribers can be in different organizations; egress controls can block copy, export, and writing query results to tables; usage metrics break down by subscriber project and organization; up to 1,000 linked datasets per shared dataset. https://docs.cloud.google.com/bigquery/docs/analytics-hub-introduction

5.4 Data clean rooms. Built on BigQuery sharing; roles are owner, contributor, and subscriber; subscribers cannot see view definitions or query INFORMATION_SCHEMA on linked datasets; analysis rules apply only to views, and tables shared without rules expose raw data; egress controls prevent copying raw data; query templates restrict subscribers to approved queries. Google cautions that analysis rules may not stop every sophisticated extraction query and recommends query templates where execution must be limited. https://docs.cloud.google.com/bigquery/docs/data-clean-rooms `[PARTIAL: read to 100,000 of 105,962 characters]`

5.5 Direction of flow `[INFERRED]`: for Raken ROI reporting, each customer project is a contributor of aggregated, rule-protected views and Raken's central project is the subscriber; customers do not see each other's data because each listing is separate. In pool, the same suppression is applied to a single dataset with a tenant column, and cross-tenant reporting is a query rather than a sharing arrangement.

## 6. Security-review language and evidence

6.1 Silo claims and evidence:
   - "Your data is in a dedicated Google Cloud project with its own IAM policy." Evidence: the project's IAM allow policy and inherited folder policies. https://docs.cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy
   - "Who changed what in your environment is logged and cannot be disabled." Admin Activity and System Event audit logs are always written and cannot be excluded or disabled; Data Access logs are off by default (except BigQuery) and must be enabled; logs are tied to the project that owns the resource. https://docs.cloud.google.com/logging/docs/audit
   - "Your data is encrypted with a key unique to you, and offboarding can destroy it." CMEK per customer and crypto-shredding (2.9). https://docs.cloud.google.com/kms/docs/cmek
   - "Google staff access to your data is logged." Access Transparency records Google personnel actions on customer data with reason and accessor details; it is on by default for every organization; Access Approval can require approval first. https://docs.cloud.google.com/assured-workloads/access-transparency/docs/overview and https://docs.cloud.google.com/assured-workloads/access-transparency/docs/enable
   - "We pentest one template; every customer runs the identical template." Supported only to the degree drift is controlled (1.5). `[INFERRED]`
   - "Region restricted by policy." Resource-location organization policy on the folder (2.4).

6.2 Pool claims and evidence `[INFERRED]` except where cited:
   - "Isolation is enforced in the database, not only in code." Evidence: RLS enabled and forced on every tenant table, policy definitions, and the application role's attributes (3.1 to 3.4). https://www.postgresql.org/docs/current/ddl-rowsecurity.html
   - "Cross-tenant tests run on every release." Evidence: the test suite in 3.11 and its CI history.
   - Audit logs, Access Transparency, and CMEK still apply, but at the shared project and shared key, so they show "Raken's environment," not "your environment." A per-tenant key in a pooled database is not provided by Cloud SQL CMEK, which is per instance (2.9). `[INFERRED]` from https://docs.cloud.google.com/sql/docs/postgres/cmek
   - Pool reviews commonly ask about noisy neighbor, blast radius, and compliance concerns, which AWS lists as pool cons. https://docs.aws.amazon.com/wellarchitected/latest/saas-lens/pool-isolation.html

6.3 Bridge claims `[INFERRED]`: customer data (uploads, host records, verdicts, metrics) in a siloed project with the silo evidence in 6.1; shared assets (rules table, identity front door, reporting) pooled, with the reviewer told explicitly which shared components exist and what crosses the boundary (rules in, suppressed aggregates out).

6.4 What the hostname does and does not prove. The load balancer does not validate Host, so "a customer reaches only their tenant because of the hostname" is not a valid claim; the valid claim is that the authenticated identity's tenant is checked against the requested tenant. https://docs.cloud.google.com/load-balancing/docs/url-map-concepts

## 7. Scorecard: steps, not dollars `[INFERRED]`

All of section 7 is synthesis from sections 1 to 6. Steps are counted at the level of a runbook line. Common to all three models and not counted: Cloud Run service, Cloud Armor policy, Secret Manager, separate staging, CI pipeline, and the rules-table schema.

7.1 Definitions used below:
   - Pool: one project, one Cloud SQL instance with RLS, one Identity Platform project with one tenant per customer, one BigQuery dataset with row policies.
   - Silo: one project per customer from a Terraform module (project, Cloud SQL, KMS, Identity Platform, Cloud Run, LB backend), plus a central Raken project for front door, logs, monitoring, rules artifact, and reporting.
   - Bridge: customer data stores (Cloud SQL, BigQuery dataset, KMS key) per customer project; shared front door, Identity Platform multi-tenancy, rules distribution, and reporting in the central project.

7.2 Five-week MVP build with one customer (build steps beyond the common set):

| Step | Pool | Bridge | Silo |
|---|---|---|---|
| Folder and org policies | 0 | 1 | 1 |
| Central project (logs, monitoring, rules artifact) | 0 | 1 | 1 |
| Terraform per-customer module | 0 | 1 (data stores only) | 1 (full stack) |
| Cross-project LB wiring (2.10) | 0 | 1 | 1 |
| Aggregated sink and metrics scope | 0 | 1 | 1 |
| CMEK key per customer | 0 (one shared key) | 1 | 1 |
| Identity Platform setup | 1 (multi-tenancy) | 1 (multi-tenancy) | 1 per project |
| RLS policies and FORCE on every tenant table | 1 | 0 or 1 (optional backstop) | 0 |
| Tenant-scoped data access layer | 1 | 1 (routes to the tenant's database) | 0 (one tenant per instance) |
| Cross-tenant test suite (3.11) | 1 (data tests) | 1 (IAM and routing tests) | 1 (IAM tests) |
| Rules distribution to N instances (4.4) | 0 (one copy) | 1 | 1 |
| Reporting with suppression (5.1 to 5.4) | 1 (one dataset) | 1 (per-project views) | 1 (per-project views) |
| Rules-version reporting (4.5) | 0 | 1 | 1 |
| Approximate build steps | 5 | 12 to 13 | 11 |

7.3 Per additional customer, provisioning:

| Step | Pool | Bridge | Silo |
|---|---|---|---|
| Configure Identity Platform tenant and providers | 1 | 1 | 1 (per-project Identity Platform in the new project) |
| Add hostname host rule and certificate | 1 | 1 | 1 |
| Insert tenant row and config | 1 | 1 | 1 |
| Terraform run of per-customer module | 0 | 1 | 1 |
| Run schema migrations on new database | 0 | 1 | 1 |
| Load current rules version | 0 | 1 | 1 |
| Grant central reporting identity on new views | 0 | 1 | 1 |
| Verify sink and metrics scope picked up the project | 0 | 1 | 1 |
| Run cross-tenant test suite against new tenant | 1 | 1 | 1 |
| Approximate steps | 4 | 9 | 9 |

7.4 Per rules release (one City rule change):

| Step | Pool | Bridge | Silo |
|---|---|---|---|
| Author, review, and merge rules change | 1 | 1 | 1 |
| Publish versioned artifact | 0 or 1 | 1 | 1 |
| Apply to instances | 1 | N (or 1 automated fan-out) | N (or 1 automated fan-out) |
| Verify loaded version everywhere | 1 | 1 (central view, 4.5) | 1 (central view, 4.5) |
| Remediate any lagging instance | 0 | 0 to N | 0 to N |
| Approximate steps | 3 to 4 | 3 + N (plus up to N remediations), or 4 with fan-out | 3 + N (plus up to N remediations), or 4 with fan-out |

7.5 Per pentest or customer security review:

| Step | Pool | Bridge | Silo |
|---|---|---|---|
| Scope document | 1 (shared stack, every tenant in scope) | 1 (shared tier plus one customer template) | 1 (one template) |
| Cross-tenant data tests in scope | 1 (central to the test) | 1 (shared tier only) | 0 (IAM tests instead) |
| Show drift evidence between customer stacks | 0 | 1 | 1 |
| Evidence pack: IAM, audit logs, Access Transparency, CMEK (6.1) | 1 (shared) | 1 (per customer) | 1 (per customer) |
| Answer the BYPASSRLS / owner-bypass question (3.4) | 1 | 0 or 1 | 0 |
| Answer the shared-component question (rules, identity, reporting) | 1 | 1 | 1 |
| Approximate steps | 5 | 5 to 6 | 4 |

7.6 Reading the scorecard, from the totals in 7.2 to 7.5: pool has the fewest steps to build (5), to provision a customer (4), and to release rules (3 to 4 regardless of N). Silo has the fewest steps per review (4) and needs 11 to build and 9 per customer. Bridge has the most steps to build (12 to 13), the same as silo to provision (9) and to release rules, and the most per review (5 to 6, against pool's 5), because it carries a shared tier and per-customer templates and must evidence both. What bridge keeps shared is identity, rules distribution, and reporting. This restates the AWS pros and cons in 1.4 and 1.6 in step counts and is not a recommendation.

## Open items

1. Whether `cloudsqlsuperuser` members hold or can grant BYPASSRLS on Cloud SQL for PostgreSQL (3.4).
2. Whether the Identity Platform ID token carries a verifiable tenant claim usable by the backend (2.8).
3. Whether serverless-NEG (Cloud Run) backends can be referenced cross-project from one global external Application Load Balancer without Shared VPC, and where the Cloud Armor policy attaches in that setup (2.10).
4. How Artifact Registry generic-artifact immutability is enforced (4.2).
5. The remaining 5,962 characters of the data clean rooms page (5.4).
