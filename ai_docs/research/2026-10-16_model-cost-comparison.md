# Model cost comparison: document checks and assistant conversations, six months

Fetched 2026-10-16. All prices USD per 1M tokens, global endpoints, from the providers' own pages. Not committed. No client pricing or commercial terms here.

## Sources (all fetched 2026-10-16)

- S1 Google Cloud Agent Platform (Vertex) pricing: https://cloud.google.com/vertex-ai/generative-ai/pricing (Claude and Gemini tables)
- S2 Anthropic pricing: https://platform.claude.com/docs/en/about-claude/pricing
- S3 Claude on Vertex: https://platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai
- S4 Claude PDF support: https://platform.claude.com/docs/en/build-with-claude/pdf-support
- S5 OpenAI pricing: https://developers.openai.com/api/docs/pricing (openai.com/api/pricing returned 403)

## Workloads and assumptions

- Document checks: 7,200 x (3 pages). Image mode 3 x 2,500 = 7,500 input tokens; text mode 3 x 1,000 = 3,000. Output 500 tokens. These token counts are the request's assumptions, not provider figures.
- Conversations: 12,000 x (6,000 input, 1,500 output).
- Cached scenario (my assumption, not a provider figure): 80% of input (4,800) is a cache read, 20% (1,200) is a cache write. Gemini cache-write is billed at base input (S1 lists no write fee; [UNVERIFIED] for implicit vs explicit caching storage fees).
- Batch scenario: non-cached, batch rates, only valid if asynchronous latency is acceptable. Conversations are interactive, so the batch column for them is a ceiling on savings, not a realistic option.
- Thinking/reasoning tokens are excluded; Gemini and GPT-6 bill them as output, so real output may be higher. [UNVERIFIED] volume.

## Prices (S1, S2, S5)

| Model | Input | Output | Cache read | Cache write | Batch in/out | Notes |
|---|---|---|---|---|---|---|
| Claude Sonnet 5.5 | 2.00 | 10.00 | 0.10 | 2.50 (5m), 4.00 (1h) | 1.00 / 5.00 | S1, S2. Vertex global price equals Anthropic direct. |
| Claude Haiku 5.5 | 0.10 | 0.50 | 0.01 | 0.125 (5m), 0.20 (1h) | 0.05 / 0.25 | S1, S2. Prompts over 100K tokens: 0.50 / 2.50. |
| Gemini 3.8 Flash | 0.75 promo / 1.50 std | 3.75 / 7.50 | 0.075 / 0.15 | none listed | 0.375 in (S1); output 1.875 [UNVERIFIED, half of standard assumed] | Promo through 2026-12-31, standard from 2027-01-01 (S1). |
| Gemini 3.1 Pro Preview (<=200K) | 2.00 | 12.00 | 0.20 | none listed | 1.00 / 6.00 | S1. Over 200K input: 4.00 / 18.00. Preview model. |
| OpenAI gpt-6.1-sol (mid-tier, short ctx) | 2.00 | 10.00 | 0.10 | 2.50 | 1.00 / 5.00 | S5. Also listed: gpt-6-astra (top, 10/50) and gpt-6-luna (0.10/0.50). "Mid-tier" is my reading of the lineup. |

Other things on S1 worth knowing: Gemini 4 Argon is listed (standard 2/10 promo to 2026-11-30, then 4/20; cache 0.1/0.2; batch half). I could not tell from the page whether it is the "Pro" or a new tier, so it is not in the totals. Gemini 3.5 Flash is 1.50/9.00; Flash-Lite variants are cheaper. Non-global Gemini endpoints cost 10% more; Claude regional/multi-region endpoints cost 10% more (S3). Claude Message Batches API is not supported on Vertex (S3), though S1 lists Claude batch prices; confirm how Vertex batch is invoked [UNVERIFIED].

## PDF and image handling

- Claude (S4): each PDF page is processed as text plus an image; guidance is 1,500-3,000 text tokens per page, plus image tokens per the vision page. No extra PDF fee. Max 600 pages (100 when context under 1M), 32 MB (30 MB payload cap on Vertex, S3). The 2,500/1,000 per-page assumptions sit inside these ranges. Sonnet 5.5 and Haiku 5.5 use the newer tokenizer (about 30% more tokens for the same text, S2); the assumed counts do not model that.
- Gemini (S1): "PDFs are billed as image input, with one PDF page equivalent to one image," at the model's image input rate (same as text rate for the Flash and Pro rows above). The per-image token count for Gemini 3.x text-generation models is [UNVERIFIED]; S1 states 258 tokens per image only for the Live API. If Gemini really tokenizes a page at far fewer than 2,500 tokens, Gemini document costs fall sharply. Test with a token-count call before deciding.
- OpenAI (S5): PDF/image token rules are on a separate vision page I did not fetch. [UNVERIFIED]

## Six-month totals (arithmetic: tokens x price / 1M, plus output)

Example, Sonnet 5.5, document images, standard: 7,200 x 7,500 = 54.0M in x $2 = $108; 7,200 x 500 = 3.6M out x $10 = $36; total $144. Conversations: 12,000 x 6,000 = 72M x $2 = $144; 12,000 x 1,500 = 18M x $10 = $180; total $324. Cached: 12,000 x (4,800 x $0.10 + 1,200 x $2.50) / 1M = $41.76 + $180 = $222.

| Model | Doc images std | Doc text std | Doc images batch | Doc text batch | Conv. no cache | Conv. cached (80% reads) | Conv. batch no cache |
|---|---|---|---|---|---|---|---|
| Claude Sonnet 5.5 (Vertex global = Anthropic direct) | $144 | $79 | $72 | $40 | $324 | $222 | $162 |
| Claude Haiku 5.5 (Vertex global = Anthropic direct) | $7 | $4 | $4 | $2 | $16 | $11 | $8 |
| Gemini 3.8 Flash (promo thru 2026-12-31) | $54 | $30 | $27 | $15 | $122 | $83 | $61 |
| Gemini 3.8 Flash (std from 2027-01-01) | $108 | $59 | $54 | $30 | $243 | $165 | $122 |
| Gemini 3.1 Pro Preview (<=200K) | $151 | $86 | $76 | $43 | $360 | $256 | $180 |
| OpenAI gpt-6.1-sol (short ctx) | $144 | $79 | $72 | $40 | $324 | $222 | $162 |

Totals are for the whole six months, USD, rounded. Doc columns are the 7,200 checks; conversation columns are the 12,000 conversations. Anthropic direct and Claude on Vertex (global) are identical, so one row covers both.

## Reading the numbers

- At this volume everything is small: the whole range is roughly $10 to $510 for both workloads over six months. Model quality and verdict reliability matter far more than price. Haiku 5.5 and Gemini Flash are cheap enough that cost is not a constraint; Sonnet 5.5 and Pro cost a few hundred dollars.
- Gemini 3.8 Flash promo pricing halves in 2027. Haiku 5.5 is the cheapest row here, but whether it is accurate enough for permit documents is untested.
- Provider-neutral note: verdicts come from deterministic code, so the model is only extracting fields and answering questions; a cheap tier may suffice.

## Data retention and no-training (one line each; separate note covers depth)

- Claude on Vertex: governed by Google Cloud, not Anthropic (S3 "Data retention"): https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance. That page says Google will not train on customer data without permission, in-memory cache up to 24h, abuse-monitoring prompt logging possible; it does not mention Claude/partner models, so partner-model terms are [UNVERIFIED].
- Gemini on Vertex: same page, https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance : no training without prior permission; implicit cache up to 24h; abuse-monitoring logging possible unless an exception is granted.
- Anthropic API direct: deleted within 30 days by default (longer for policy violations, ZDR by agreement) https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data ; no training on commercial API data by default https://privacy.claude.com/en/articles/7996868-is-my-data-used-for-model-training
- OpenAI API: abuse-monitoring logs up to 30 days by default, no training by default, ZDR only for approved customers https://developers.openai.com/api/docs/guides/your-data
