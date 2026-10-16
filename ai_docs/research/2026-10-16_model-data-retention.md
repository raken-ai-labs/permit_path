# Model, hosting and logging data retention (security-review answers)

Fetched 2026-10-16 (all URLs below). Primary sources only. Google docs redirect from cloud.google.com to docs.cloud.google.com; the redirected URL is cited. Several Google pages were fetched through a summarizer and truncated at ~100K characters; those items are marked `[PARTIAL]`. `[UNVERIFIED]` = not confirmed from a primary source. This is not legal advice; confirm contract terms with Raken's Google account team.

## Bottom line for the "read in memory, discard, nothing stored" promise

1. The promise can be kept for our own stack (Cloud Run, Cloud Logging) by configuration. It cannot be stated unconditionally for the model hop without Google confirmation: Google's pages do not give a Claude-specific retention table (see 1 and 2).
2. Anthropic's ZDR arrangement does not apply to Claude on Vertex AI; Google is the data processor (1.4).
3. Request-response logging is off by default (3). Keep it off for any path that carries uploaded documents.

## 1. Claude on Vertex AI

1.1 Who governs data. Anthropic: "Data handling for this offering is governed by Google Cloud," pointing to Google's data governance page. https://platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai (section "Data retention").

1.2 Anthropic's own retention page says its ZDR and HIPAA arrangements cover the Claude API where Anthropic is processor; "On Amazon Bedrock and Google Cloud's Agent Platform, the cloud provider is the data processor." Retained data is "never used for model training without your express permission" (Anthropic's stated approach). https://platform.claude.com/docs/en/manage-claude/api-and-data-retention

1.3 Google's data governance page: "Google won't use your data to train or fine-tune any AI/ML models without your prior permission or instruction," for all managed models incl. GA and pre-GA. MaaS customer data "is retained ... for limited periods of time"; "To achieve zero data retention, customers must take specific actions within each of these areas." The page text we retrieved does not mention Claude or partner models by name and gives no separate partner-model ZDR steps. https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance `[PARTIAL: Claude-specific ZDR steps UNVERIFIED]`

1.4 Abuse monitoring (Google). For "Advanced AI models (including Claude)": "All prompts and responses will be logged and securely stored for up to 30 days," in the project's region or multi-region; not CMEK-encrypted. Scope for Claude is partial: Claude Mythos and Fable models fall under it; Claude Opus (4.7 or later) and Sonnet (5 or later) only when `advanced_ai_enabled` is true (Anthropic Cyber Verification Program); other Claude usage is outside that addendum. For Fable 5 and Mythos 5, prompts and responses are retained up to 30 days and sharing with Anthropic must be enabled. "It may not be possible to opt-out of prompt-response logging when using some Advanced AI features." Google Cloud Master Agreement customers are exempt from abuse-monitoring prompt logging by default. https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring
   - Implication: choose a Claude model outside the Advanced AI scope (for example Sonnet or Haiku tier without `advanced_ai_enabled`), confirm Raken is under the Cloud Master Agreement, and get written confirmation of the zero-retention status for the chosen model ID from the Google account team. `[UNVERIFIED for any specific model ID]`

1.5 Prompt caching for Claude on Vertex: a dedicated Google page exists (https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/prompt-caching) but its body was truncated in our fetch. Retention of cached Claude content `[UNVERIFIED]`. Mitigation: do not send `cache_control` for uploaded documents.

1.6 Data residency: global, multi-region (`us`, `eu`) and regional endpoints; regional or multi-region give geographic routing guarantees (global does not). Newer models are global or multi-region only. https://platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai (section "Global, multi-region, and regional endpoints").

1.7 Feature note: Files API and URL sources are not supported on Vertex, so documents travel inline in the request (30 MB payload cap). Same page, "Features not supported."

1.8 Anthropic recommends logging activity on at least a 30-day rolling basis for misuse investigation; turning on logging "does not give Google or Anthropic any access to your content." Same page, "Activity logging." This tension with "nothing stored" needs a decision (log metadata only).

## 2. Gemini on Vertex AI

Source: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance

- No training: same sentence as 1.3.
- Abuse monitoring: Google models "may log prompts for abuse detection under the Google Cloud Platform Terms of Service"; customers in scope can request an exception to get ZDR. Per the abuse-monitoring page: non-Frontier Google models log only when classifiers flag activity, up to 90 days; Frontier models up to 30 days, no charge. Cloud Master Agreement customers exempt by default. https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring
- Caching: implicit caching on by default. In-memory and durable cache data deleted "no later than 24 hours after it's written." Disable durable caching per project with `disableCache` in the cacheConfig API (in-memory caching remains) or disable caching entirely; org-wide disable requires the account team. CMEK not supported for durable caching.
- Other ZDR traps: Interactions API `store` defaults to `true` (set `false`); Grounding with Google Search keeps logs up to 3 days, cannot be disabled; Grounding with Google Maps stores 30 days, cannot be disabled; Gemini Live session resumption off by default, up to 24 hours if on; Deep Research agent 7 days.

## 3. Vertex AI request-response logging

- Default: off. "To achieve zero data retention, do not enable this feature." https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance
- Destination: a BigQuery table (default name `request_response_logging`); sampling rate 0 to 1. Supports Gemini (`generateContent`, `streamGenerateContent`) and Claude (`rawPredict`, `streamRawPredict`). For Anthropic models only REST configuration is supported (`setPublisherModelConfig`, `enabled` true or false). Changes take a few minutes. https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/capabilities/request-response-logging `[PARTIAL: read from offset 100000 only; the page's own statement of default state was not seen there, default taken from the data governance page]`
- Control: audit the project for any `setPublisherModelConfig` enablement and restrict who can set it.

## 4. Cloud Run

- Request logs are created automatically for services and contain standard LogEntry fields incl. `httpRequest`. https://docs.cloud.google.com/run/docs/logging The page does not say request bodies are or are not logged. `[UNVERIFIED]` that `httpRequest` has no body; the LogEntry reference page returned 404, so check https://cloud.google.com/logging/docs/reference/v2/rest/Shared.Types/LogEntry#HttpRequest. In practice, never put document content in URLs or headers.
- stdout/stderr are picked up automatically by Cloud Logging (text to `textPayload`, one-line JSON to `jsonPayload`). Anything the app prints goes to logs, so the app must not log document text or parsed fields. Same page.
- Cloud Run cannot turn off request logs directly; use Cloud Logging exclusions. Same page.
- Filesystem: each container's filesystem is writable and in-memory; writes use instance memory (no size limit, can OOM the instance); "Data written to the file system doesn't persist when the instance stops." https://docs.cloud.google.com/run/docs/container-contract (File system access). For a bounded in-memory scratch space use an in-memory volume: size-limited, counts toward container memory, deleted when the instance stops. https://docs.cloud.google.com/run/docs/configuring/in-memory-volumes
- Ephemeral Disk is a separate, opt-in volume (Preview; second generation only); data is deleted on instance shutdown, encrypted with instance-specific keys. Do not add one. https://docs.cloud.google.com/run/docs/configuring/services/ephemeral-disk
- Caveat: "in memory and discarded" holds for the instance, but one instance serves many requests in sequence or concurrently, and memory is not zeroed per request. Per-case isolation is an application property (no shared globals, concurrency 1 if required); the docs do not provide it. `[UNVERIFIED]` whether a concurrency-1 setting is documented as an isolation guarantee.

## 5. Cloud Logging

- Defaults: `_Required` 400 days (not configurable); `_Default` 30 days, configurable in a project from 1 to 3650 days; user-defined buckets 30 days, configurable 1 to 3650. https://docs.cloud.google.com/logging/quotas
- Shorten: set bucket retention (`gcloud logging buckets update`, per "Configure log buckets" https://docs.cloud.google.com/logging/docs/buckets `[not fetched; command syntax UNVERIFIED]`) or add exclusion filters on the `_Default` sink. https://docs.cloud.google.com/logging/docs/routing/overview
- `_Required` (admin activity, system event, access transparency audit logs) cannot be excluded or shortened, but those are metadata. Same routing page.
- Data Access audit logs: "disabled by default for all services but some BigQuery services." Types `ADMIN_READ`, `DATA_READ`, `DATA_WRITE`. https://docs.cloud.google.com/logging/docs/audit/configure-data-access Whether Vertex AI Data Access logs include prompt content `[UNVERIFIED]`; assume metadata only, confirm before enabling.

## 6. Comparison

- Anthropic API direct (commercial): inputs and outputs deleted within 30 days by default; up to 2 years if flagged for policy violation, classifier scores up to 7 years. https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data
- Anthropic ZDR: by agreement, per organization, approval required; covers eligible APIs; still keeps safety classifier results. PDF support is ZDR-eligible; Files API, code execution and some tools are not. https://privacy.claude.com/en/articles/8956058-i-have-a-zero-data-retention-agreement-with-anthropic-what-products-does-it-apply-to and https://platform.claude.com/docs/en/manage-claude/api-and-data-retention
- OpenAI API: not used for training unless opted in; abuse-monitoring logs of prompts and responses up to 30 days by default; Modified Abuse Monitoring or Zero Data Retention by prior approval, set per org or project; `/v1/files`, `/v1/batches`, assistants and threads not ZDR eligible. https://developers.openai.com/api/docs/guides/your-data

## Open items for the security review

1. Written Google confirmation that the chosen Claude model ID on Vertex has no prompt or response retention (or states the retention), under Raken's agreement.
2. Claude prompt caching retention on Vertex (1.5).
3. LogEntry `httpRequest` contents and a log-redaction test on staging.
4. Wording: if abuse monitoring or caching applies, the host-facing claim must say "not stored by PermitPath" rather than "stored nowhere."
